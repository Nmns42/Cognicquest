import 'dart:math' as math;

import 'package:cognicquest/features/graph/domain/graph_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_layout_reference.dart';

/// Chantier 12 (A) : sortir la disposition du thread UI ne doit pas changer
/// la carte. Chaque variante est comparée, au bit près, à l'algorithme
/// d'origine.
void main() {
  (List<String>, List<(String, String)>) graph(int n, int m, {int seed = 7}) {
    final random = math.Random(seed);
    final ids = [for (var i = 0; i < n; i++) 'n${i.toString().padLeft(4, '0')}'];
    final edges = [
      for (var i = 0; i < m; i++)
        (ids[random.nextInt(n)], ids[random.nextInt(n)]),
    ];
    return (ids, edges);
  }

  void expectSameAsReference(
    GraphLayout layout,
    List<String> ids,
    List<(String, String)> edges,
  ) {
    final reference = ReferenceGraphLayout.layout(ids, edges);
    expect(layout.positions.keys.toSet(), reference.keys.toSet());
    for (final MapEntry(:key, :value) in reference.entries) {
      // Égalité stricte des doubles : même arithmétique, même ordre.
      expect(layout.positions[key], value, reason: key);
    }
  }

  final cases = {
    'graphe vide': graph(0, 0),
    'deux fiches': graph(2, 1),
    'au seuil': graph(GraphLayout.asyncThreshold, 40),
    '120 fiches': graph(120, 300, seed: 3),
  };

  group('GraphLayout.compute', () {
    for (final MapEntry(key: name, value: (ids, edges)) in cases.entries) {
      test('identique à l\'algorithme d\'origine — $name', () {
        expectSameAsReference(GraphLayout.compute(ids, edges), ids, edges);
      });
    }
  });

  group('GraphLayout.computeAsync découpé (chemin web)', () {
    for (final MapEntry(key: name, value: (ids, edges)) in cases.entries) {
      test('identique à l\'algorithme d\'origine — $name', () async {
        final layout = await GraphLayout.computeAsync(
          ids,
          edges,
          useIsolate: false,
          // Tranches minuscules : force un découpage en très nombreuses
          // étapes, le cas le plus exposé à une divergence.
          sliceBudget: Duration.zero,
        );
        expectSameAsReference(layout, ids, edges);
      });
    }

    test('rend la main à la boucle d\'évènements entre deux tranches',
        () async {
      final (ids, edges) = graph(120, 300);
      var ticks = 0;
      var done = false;
      final future = GraphLayout.computeAsync(
        ids,
        edges,
        useIsolate: false,
        sliceBudget: const Duration(milliseconds: 2),
      ).whenComplete(() => done = true);
      while (!done) {
        await Future<void>.delayed(Duration.zero);
        ticks++;
      }
      await future;
      // Un calcul bloquant n'aurait laissé passer aucun autre évènement.
      expect(ticks, greaterThan(10));
    });
  });

  group('GraphLayout.computeAsync en isolate (mobile, desktop)', () {
    test('identique à l\'algorithme d\'origine', () async {
      final (ids, edges) = cases['120 fiches']!;
      final layout =
          await GraphLayout.computeAsync(ids, edges, useIsolate: true);
      expectSameAsReference(layout, ids, edges);
    });
  });
}
