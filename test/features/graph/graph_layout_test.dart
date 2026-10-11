import 'dart:ui' show Size;

import 'package:cognicquest/features/graph/domain/graph_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GraphLayout.compute', () {
    test('place chaque fiche, y compris les isolées', () {
      // Régression : graphview n'affichait que les fiches reliées.
      final layout = GraphLayout.compute(
        ['a', 'b', 'seule', 'autre-seule'],
        [('a', 'b')],
      );

      expect(layout.positions.keys,
          unorderedEquals(['a', 'b', 'seule', 'autre-seule']));
    });

    test('est déterministe et indépendant de l\'ordre des entrées', () {
      // Régression : la carte se réorganisait à chaque reconstruction.
      final first = GraphLayout.compute(['a', 'b', 'c'], [('a', 'b')]);
      final second = GraphLayout.compute(['c', 'b', 'a'], [('a', 'b')]);

      expect(second.positions, first.positions);
      expect(second.size, first.size);
    });

    test('garde tous les nœuds dans la toile, marges comprises', () {
      final layout = GraphLayout.compute(
        [for (var i = 0; i < 30; i++) 'n$i'],
        [for (var i = 0; i < 29; i++) ('n$i', 'n${i + 1}')],
        padding: 100,
      );

      for (final p in layout.positions.values) {
        expect(p.dx, inInclusiveRange(100, layout.size.width - 100));
        expect(p.dy, inInclusiveRange(100, layout.size.height - 100));
      }
    });

    test('ignore les liens fantômes, les boucles et les doublons', () {
      final clean = GraphLayout.compute(['a', 'b'], [('a', 'b')]);
      final noisy = GraphLayout.compute(
        ['a', 'b'],
        [('a', 'b'), ('b', 'a'), ('a', 'a'), ('a', 'fantome')],
      );

      expect(noisy.positions, clean.positions);
    });

    test('rapproche les fiches reliées plus que les autres', () {
      final layout = GraphLayout.compute(
        ['a', 'b', 'c', 'd'],
        [('a', 'b'), ('c', 'd')],
      );
      final p = layout.positions;

      expect((p['a']! - p['b']!).distance,
          lessThan((p['a']! - p['c']!).distance));
      expect((p['c']! - p['d']!).distance,
          lessThan((p['b']! - p['d']!).distance));
    });

    test('un graphe vide donne une toile vide', () {
      final layout = GraphLayout.compute(const [], const []);
      expect(layout.isEmpty, isTrue);
      expect(layout.size, Size.zero);
    });
  });
}
