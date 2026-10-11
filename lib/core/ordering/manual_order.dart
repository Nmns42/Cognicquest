import 'fractional_key.dart';

/// Élément d'une liste à ordre manuel : identifiant et clé (`null` tant que
/// l'élément n'a jamais été placé à la main).
class OrderedItem {
  const OrderedItem(this.id, this.key);

  final String id;
  final String? key;
}

/// Écriture de clé à effectuer.
class KeyUpdate {
  const KeyUpdate(this.id, this.key);

  final String id;
  final String key;

  @override
  bool operator ==(Object other) =>
      other is KeyUpdate && other.id == id && other.key == key;

  @override
  int get hashCode => Object.hash(id, key);

  @override
  String toString() => 'KeyUpdate($id → $key)';
}

/// Ordre manuel commun aux fiches et aux habitudes.
abstract final class ManualOrder {
  /// Compare deux éléments clés : clé, puis identifiant pour départager deux
  /// clés identiques (conflit hors ligne) — même résultat sur tous les
  /// appareils. Comparaison octet par octet, comme SQLite (`BINARY`) et
  /// Postgres (`collate "C"`).
  static int compareKeyed(OrderedItem a, OrderedItem b) {
    final byKey = a.key!.compareTo(b.key!);
    return byKey != 0 ? byKey : a.id.compareTo(b.id);
  }

  /// Écritures nécessaires pour placer [movedId] à l'index [newIndex] de
  /// [items] (ordre affiché, élément déplacé compris ; [newIndex] compté
  /// dans la liste *sans* l'élément déplacé).
  ///
  /// - Cas courant : une seule écriture, la clé de l'élément déplacé.
  /// - Éléments sans clé (jamais placés à la main) : ils reçoivent, une seule
  ///   fois, des clés réparties dans leur ordre affiché actuel, qui repose sur
  ///   des champs synchronisés — deux appareils calculent les mêmes clés.
  /// - Voisins à clé identique (conflit hors ligne) : le voisin suivant est
  ///   réparé, une ligne de plus au maximum.
  static List<KeyUpdate> planMove(
    List<OrderedItem> items,
    String movedId,
    int newIndex,
  ) {
    final updates = <String, String>{};
    final keys = [for (final item in items) item.key];

    // 1. Clés initiales pour les éléments qui n'en ont pas, par plages
    //    contiguës, entre les clés qui les encadrent.
    var i = 0;
    while (i < keys.length) {
      if (keys[i] != null) {
        i++;
        continue;
      }
      var j = i;
      while (j < keys.length && keys[j] == null) {
        j++;
      }
      final low = i > 0 ? keys[i - 1] : null;
      final high = j < keys.length ? keys[j] : null;
      final spread = FractionalKey.spreadBetween(low, high, j - i);
      for (var k = i; k < j; k++) {
        keys[k] = spread[k - i];
        updates[items[k].id] = spread[k - i];
      }
      i = j;
    }

    // 2. Retrait de l'élément déplacé, puis ses nouveaux voisins.
    final from = items.indexWhere((item) => item.id == movedId);
    if (from < 0) throw ArgumentError.value(movedId, 'movedId', 'absent');
    final ids = [for (final item in items) item.id]..removeAt(from);
    keys.removeAt(from);
    final at = newIndex.clamp(0, ids.length);

    final left = at > 0 ? keys[at - 1] : null;
    var right = at < keys.length ? keys[at] : null;

    // 3. Conflit : voisins à clé identique. Le voisin de droite reçoit une
    //    clé entre la clé commune et la suivante strictement plus grande.
    if (left != null && right != null && left.compareTo(right) >= 0) {
      String? next;
      for (var k = at + 1; k < keys.length; k++) {
        if (keys[k]!.compareTo(right) > 0) {
          next = keys[k];
          break;
        }
      }
      right = FractionalKey.repairDuplicate(left, next);
      keys[at] = right;
      updates[ids[at]] = right;
    }

    updates[movedId] = FractionalKey.between(left, right);
    return [
      for (final MapEntry(key: id, value: key) in updates.entries)
        KeyUpdate(id, key),
    ];
  }
}
