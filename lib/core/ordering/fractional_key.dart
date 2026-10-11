/// Clés d'ordre fractionnaires (« fractional indexing », principe LexoRank).
///
/// Une clé est la partie décimale d'un nombre de [0, 1[ écrite en base 62 :
/// `'V'` vaut 31/62, `'0V'` vaut 31/62². Deux règles en font un ordre total
/// et stable :
/// - alphabet ASCII trié (`0-9`, `A-Z`, `a-z`) : comparer deux clés octet par
///   octet (`String.compareTo` en Dart, collation `BINARY` dans SQLite,
///   `collate "C"` dans Postgres) revient à comparer leurs valeurs ;
/// - jamais de `0` final : deux clés de même valeur sont donc identiques.
///
/// Déplacer un élément ne réécrit que sa propre clé, prise entre celles de
/// ses voisins : aucune renumérotation, donc pas d'écrasement entre deux
/// appareils qui déplacent des éléments différents. Insérer toujours au même
/// endroit allonge la clé d'environ un caractère toutes les six insertions
/// (log₂ 62 ≈ 5,95, voir [_midpoint]).
abstract final class FractionalKey {
  static const String alphabet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  static const int _base = 62;

  static final RegExp _valid = RegExp(r'^[0-9A-Za-z]*[1-9A-Za-z]$');

  /// `true` si [key] est une clé bien formée.
  static bool isValid(String key) => _valid.hasMatch(key);

  /// Clé strictement comprise entre [before] et [after] (`null` = sans borne).
  ///
  /// Exige `before < after` : pour deux voisins à clé identique (conflit hors
  /// ligne), voir [repairDuplicate].
  static String between(String? before, String? after) {
    if (before != null && !isValid(before)) {
      throw ArgumentError.value(before, 'before', 'clé invalide');
    }
    if (after != null && !isValid(after)) {
      throw ArgumentError.value(after, 'after', 'clé invalide');
    }
    if (before != null && after != null && before.compareTo(after) >= 0) {
      throw ArgumentError('$before doit précéder $after');
    }
    return _midpoint(before ?? '', after);
  }

  /// Milieu entre les fractions [a] (vide = 0) et [b] (`null` = 1), chiffre
  /// par chiffre (algorithme classique de fractional indexing).
  static String _midpoint(String a, String? b) {
    if (b != null) {
      // Préfixe commun (a complété par des 0) : il est conservé tel quel.
      var n = 0;
      while (n < b.length && (n < a.length ? a[n] : '0') == b[n]) {
        n++;
      }
      if (n > 0) {
        return b.substring(0, n) +
            _midpoint(a.length > n ? a.substring(n) : '', b.substring(n));
      }
    }

    final digitA = a.isEmpty ? 0 : alphabet.indexOf(a[0]);
    final digitB = b == null ? _base : alphabet.indexOf(b[0]);

    if (digitB - digitA > 1) {
      // Assez de place pour un chiffre intermédiaire.
      return alphabet[(digitA + digitB) ~/ 2];
    }
    // Chiffres consécutifs : si b a d'autres chiffres, son premier chiffre
    // seul est déjà strictement entre a et b.
    if (b != null && b.length > 1) return b[0];
    // Sinon on garde le chiffre de a et on cherche plus loin, au-dessus de
    // la suite de a.
    return alphabet[digitA] +
        _midpoint(a.length > 1 ? a.substring(1) : '', null);
  }

  /// [count] clés strictement croissantes, toutes comprises entre [before]
  /// et [after] (`null` = sans borne), réparties par bissection équilibrée.
  ///
  /// Déterministe : mêmes bornes et même nombre, mêmes clés, sur tous les
  /// appareils. La longueur reste de l'ordre de log₆₂(count) + 1 caractères.
  static List<String> spreadBetween(String? before, String? after, int count) {
    final keys = List<String>.filled(count, '');
    void fill(int from, int to, String? low, String? high) {
      if (from > to) return;
      final middle = (from + to) ~/ 2;
      final key = between(low, high);
      keys[middle] = key;
      fill(from, middle - 1, low, key);
      fill(middle + 1, to, key, high);
    }

    fill(0, count - 1, before, after);
    return keys;
  }

  /// Réparation d'un conflit : [left] et [right] sont voisins avec la même
  /// clé (deux appareils hors ligne ont choisi la même place). Renvoie la
  /// nouvelle clé de [right], prise entre la clé commune et [next] (clé du
  /// voisin suivant, `null` s'il n'y en a pas) : une seule ligne réparée.
  static String repairDuplicate(String sharedKey, String? next) {
    final after = (next != null && next.compareTo(sharedKey) > 0) ? next : null;
    return between(sharedKey, after);
  }
}
