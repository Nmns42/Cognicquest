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

  group('GraphSimulation', () {
    GraphSimulation simulate(List<String> ids, List<(String, String)> edges) {
      final sim = GraphSimulation()
        ..load(GraphLayout.compute(ids, edges), edges);
      sim.settle();
      return sim;
    }

    test('se pose d\'elle-même : l\'énergie retombe et la boucle s\'arrête',
        () {
      final sim = GraphSimulation()
        ..load(GraphLayout.compute(['a', 'b', 'c'], [('a', 'b')]), [('a', 'b')]);
      expect(sim.isActive, isTrue);
      var ticks = 0;
      while (sim.isActive && ticks < 1000) {
        sim.tick();
        ticks++;
      }
      expect(sim.isActive, isFalse);
      expect(ticks, lessThan(400));
    });

    test('deux fiches liées restent plus proches que deux fiches isolées', () {
      final sim = simulate(['a', 'b', 'c', 'd'], [('a', 'b')]);
      final p = sim.positions;
      final linked = (p['a']! - p['b']!).distance;
      final unlinked = (p['c']! - p['d']!).distance;
      expect(linked, lessThan(unlinked));
    });

    test('une fiche tenue suit le doigt et entraîne ses voisines', () {
      final sim = simulate(['a', 'b', 'c'], [('a', 'b')]);
      final b0 = sim.positions['b']!;
      final target = sim.positions['a']! + const Offset(600, 0);

      sim.pin('a', target);
      for (var i = 0; i < 120; i++) {
        sim.tick();
      }
      expect(sim.positions['a'], target, reason: 'la fiche tenue reste au doigt');
      expect(sim.positions['b']!.dx, greaterThan(b0.dx + 100),
          reason: 'la voisine suit le ressort');
      expect(sim.isActive, isTrue, reason: 'actif tant que la fiche est tenue');

      sim.release();
      sim.settle();
      expect(sim.isActive, isFalse);
    });

    test('ajouter une fiche ne rebat pas les autres', () {
      final edges = [('a', 'b')];
      final sim = simulate(['a', 'b'], edges);
      final before = Map.of(sim.positions);
      sim.load(GraphLayout.compute(['a', 'b', 'c'], edges), edges);
      expect(sim.positions['a'], before['a']);
      expect(sim.positions['b'], before['b']);
      expect(sim.positions, contains('c'));
    });

    test('touche une fiche dans son rayon, rien au-delà', () {
      final sim = simulate(['a'], const []);
      final a = sim.positions['a']!;
      expect(sim.hitTest(a + const Offset(5, 0), 10), 'a');
      expect(sim.hitTest(a + const Offset(50, 0), 10), isNull);
    });
  });
}
