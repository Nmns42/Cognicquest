import 'dart:math' as math;

import 'package:cognicquest/core/ordering/fractional_key.dart';
import 'package:cognicquest/core/ordering/manual_order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  void expectStrictlyIncreasing(List<String> keys) {
    for (var i = 1; i < keys.length; i++) {
      expect(keys[i - 1].compareTo(keys[i]), lessThan(0),
          reason: '${keys[i - 1]} !< ${keys[i]} (rang $i)');
    }
  }

  group('FractionalKey.between', () {
    test('rend une clé valide strictement entre ses bornes', () {
      for (final (a, b) in [
        (null, null),
        (null, 'V'),
        ('V', null),
        ('A', 'B'),
        ('A', 'A1'),
        ('A0V', 'A1'),
        ('z', null),
        ('zzzz', null),
        (null, '01'),
        (null, '0001'),
      ]) {
        final key = FractionalKey.between(a, b);
        expect(FractionalKey.isValid(key), isTrue, reason: key);
        if (a != null) expect(a.compareTo(key), lessThan(0), reason: '$a<$key');
        if (b != null) expect(key.compareTo(b), lessThan(0), reason: '$key<$b');
      }
    });

    test('refuse des bornes invalides ou dans le désordre', () {
      expect(() => FractionalKey.between('B', 'A'), throwsArgumentError);
      expect(() => FractionalKey.between('A', 'A'), throwsArgumentError);
      expect(() => FractionalKey.between('A0', null), throwsArgumentError);
      expect(() => FractionalKey.between('é', null), throwsArgumentError);
    });

    test('alphabet ASCII uniquement, dans l\'ordre des octets', () {
      final units = FractionalKey.alphabet.codeUnits;
      expect(units.every((u) => u < 128), isTrue);
      expect([...units]..sort(), units);
    });
  });

  test('10 000 insertions aléatoires : ordre strict, aucun doublon', () {
    final random = math.Random(42);
    final keys = <String>[];
    for (var n = 0; n < 10000; n++) {
      final at = random.nextInt(keys.length + 1);
      keys.insert(
        at,
        FractionalKey.between(
          at > 0 ? keys[at - 1] : null,
          at < keys.length ? keys[at] : null,
        ),
      );
    }
    expectStrictlyIncreasing(keys);
    expect(keys.toSet(), hasLength(keys.length));
    expect(keys.every(FractionalKey.isValid), isTrue);

    // Critère d'usage réaliste : des clés courtes (mesuré : max 6, moy. 3,3).
    final lengths = keys.map((k) => k.length);
    expect(lengths.reduce(math.max), lessThanOrEqualTo(8));
    expect(lengths.reduce((a, b) => a + b) / keys.length, lessThanOrEqualTo(4));
  });

  group('1 000 insertions au même endroit : ≈ 1 caractère / 5 insertions', () {
    // Garde-fou contre une régression : l'algorithme classique (milieu
    // chiffre par chiffre) mesure 201 caractères pour 1 000 insertions en
    // tête ou au même endroit, 167 en fin de liste. Borne ≈ 1/4,8 (≈ 4 % de
    // marge). L'idéal théorique de 1/5,95 n'est pas un besoin.
    int maxLength(int inserts) => (inserts / 4.8).ceil() + 2;

    test('toujours juste après le premier élément', () {
      final keys = [FractionalKey.between(null, null)];
      keys.add(FractionalKey.between(keys.first, null));
      for (var n = 0; n < 1000; n++) {
        keys.insert(1, FractionalKey.between(keys[0], keys[1]));
      }
      expectStrictlyIncreasing(keys);
      expect(keys.map((k) => k.length).reduce(math.max),
          lessThanOrEqualTo(maxLength(1000)));
    });

    test('toujours en tête', () {
      final keys = [FractionalKey.between(null, null)];
      for (var n = 0; n < 1000; n++) {
        keys.insert(0, FractionalKey.between(null, keys.first));
      }
      expectStrictlyIncreasing(keys);
      expect(keys.first.length, lessThanOrEqualTo(maxLength(1000)));
    });

    test('toujours en fin', () {
      final keys = [FractionalKey.between(null, null)];
      for (var n = 0; n < 1000; n++) {
        keys.add(FractionalKey.between(keys.last, null));
      }
      expectStrictlyIncreasing(keys);
      expect(keys.last.length, lessThanOrEqualTo(maxLength(1000)));
    });
  });

  group('FractionalKey.spreadBetween', () {
    test('clés courtes, croissantes et dans les bornes', () {
      final keys = FractionalKey.spreadBetween(null, null, 3000);
      expectStrictlyIncreasing(keys);
      expect(keys.map((k) => k.length).reduce(math.max), lessThanOrEqualTo(3));

      final bounded = FractionalKey.spreadBetween('A', 'B', 50);
      expectStrictlyIncreasing(['A', ...bounded, 'B']);
    });

    test('déterministe : même entrée, mêmes clés', () {
      expect(FractionalKey.spreadBetween(null, 'k', 137),
          FractionalKey.spreadBetween(null, 'k', 137));
    });
  });

  group('ManualOrder.planMove', () {
    List<String> applied(List<OrderedItem> items, List<KeyUpdate> updates) {
      final keys = {for (final i in items) i.id: i.key};
      for (final u in updates) {
        keys[u.id] = u.key;
      }
      final result = [
        for (final MapEntry(:key, :value) in keys.entries) OrderedItem(key, value),
      ]..sort(ManualOrder.compareKeyed);
      return [for (final i in result) i.id];
    }

    test('(a) un déplacement réécrit une seule ligne', () {
      final keys = FractionalKey.spreadBetween(null, null, 5);
      final items = [
        for (var i = 0; i < 5; i++) OrderedItem('n$i', keys[i]),
      ];
      final updates = ManualOrder.planMove(items, 'n4', 1);
      expect(updates, hasLength(1));
      expect(applied(items, updates), ['n0', 'n4', 'n1', 'n2', 'n3']);
    });

    test('même jeu de données sur deux appareils : mêmes clés initiales', () {
      List<OrderedItem> device() => [
            for (var i = 0; i < 40; i++) OrderedItem('id$i', null),
          ];
      final first = ManualOrder.planMove(device(), 'id7', 30);
      final second = ManualOrder.planMove(device(), 'id7', 30);
      expect(first, second);
      expect(first, hasLength(40), reason: 'initialisation unique');
    });

    test('(e) sans clé, l\'ordre affiché est conservé à l\'initialisation', () {
      final items = [
        for (var i = 0; i < 6; i++) OrderedItem('n$i', null),
      ];
      // On « déplace » n2 à sa propre place : seul l'ordre initial compte.
      final updates = ManualOrder.planMove(items, 'n2', 2);
      expect(applied(items, updates), ['n0', 'n1', 'n2', 'n3', 'n4', 'n5']);
    });

    test('éléments sans clé en tête, suivis d\'éléments clés', () {
      final keyed = FractionalKey.spreadBetween(null, null, 3);
      final items = [
        const OrderedItem('nouvelle', null),
        OrderedItem('a', keyed[0]),
        OrderedItem('b', keyed[1]),
        OrderedItem('c', keyed[2]),
      ];
      final updates = ManualOrder.planMove(items, 'c', 1);
      expect(applied(items, updates), ['nouvelle', 'c', 'a', 'b']);
      expect(updates, hasLength(2), reason: 'la nouvelle fiche + le déplacé');
    });

    test('voisins à clé identique : le déplacement fonctionne, une ligne '
        'réparée au plus', () {
      final items = [
        const OrderedItem('a', 'A'),
        const OrderedItem('b', 'M'), // b et c : même clé (conflit hors ligne)
        const OrderedItem('c', 'M'),
        const OrderedItem('d', 'Z'),
      ];
      final updates = ManualOrder.planMove(items, 'd', 2); // entre b et c
      expect(updates.length, lessThanOrEqualTo(2));
      expect(applied(items, updates), ['a', 'b', 'd', 'c']);
    });
  });

  test('l\'app (Dart) et SQLite rangent les clés dans le même ordre', () {
    final random = math.Random(7);
    final keys = <String>[];
    for (var n = 0; n < 2000; n++) {
      final at = random.nextInt(keys.length + 1);
      keys.insert(
          at,
          FractionalKey.between(
              at > 0 ? keys[at - 1] : null, at < keys.length ? keys[at] : null));
    }
    keys.shuffle(random);

    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    // Même déclaration que la colonne Drift (TEXT, collation par défaut).
    db.execute('CREATE TABLE t (position TEXT)');
    final insert = db.prepare('INSERT INTO t VALUES (?)');
    for (final key in keys) {
      insert.execute([key]);
    }
    insert.close();

    final fromSqlite = [
      for (final row in db.select('SELECT position FROM t ORDER BY position'))
        row['position'] as String,
    ];
    expect(fromSqlite, [...keys]..sort());
  });
}
