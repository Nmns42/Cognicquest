import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart' as foundation show compute;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Disposition du graphe de connaissances (algorithme de Fruchterman-Reingold
/// avec gravité).
///
/// Écrite à la main plutôt que déléguée à `graphview`, qui :
/// - n'affichait que les fiches reliées par au moins un lien (les fiches
///   isolées, celles que le CdC veut justement montrer, disparaissaient) ;
/// - tirait des positions au hasard à chaque reconstruction, si bien que le
///   graphe se réorganisait dès qu'on touchait un nœud.
///
/// Ici la disposition est déterministe : mêmes fiches, mêmes liens, même carte.
class GraphLayout {
  const GraphLayout._(this.positions, this.size);

  static const GraphLayout empty = GraphLayout._({}, Size.zero);

  /// Centre de chaque nœud, dans le repère de la toile ([size]).
  final Map<String, Offset> positions;

  /// Taille de la toile, marges comprises.
  final Size size;

  bool get isEmpty => positions.isEmpty;

  /// Nombre de fiches au-delà duquel le calcul dépasse une frame (≈ 13 ms
  /// mesurées pour 24 fiches) : l'écran passe alors par [computeAsync]. En
  /// dessous, il reste synchrone, sans écran d'attente.
  static const int asyncThreshold = 24;

  /// Calcule la disposition de [ids] reliés par [edges].
  ///
  /// [spacing] est la distance idéale entre deux fiches voisines ; aucune paire
  /// de nœuds ne finit plus proche que `spacing * 0.75`. Les arêtes dont une
  /// extrémité est inconnue, les boucles et les doublons sont ignorés.
  static GraphLayout compute(
    Iterable<String> ids,
    Iterable<(String, String)> edges, {
    double spacing = 170,
    double padding = 120,
    int iterations = 300,
  }) {
    final job = GraphLayoutJob(
      ids,
      edges,
      spacing: spacing,
      padding: padding,
      iterations: iterations,
    );
    while (!job.isDone) {
      job.step();
    }
    return job.result;
  }

  /// Même résultat que [compute], sans bloquer l'interface.
  ///
  /// - Mobile et desktop : calcul dans un isolate (`compute` de Flutter).
  /// - Web : Flutter web n'a pas d'isolates (`compute` y exécute la fonction
  ///   sur le thread principal). Le calcul est découpé en tranches de
  ///   [sliceBudget] ; entre deux tranches, la main revient à la boucle
  ///   d'évènements et le navigateur peut afficher une frame.
  ///
  /// [useIsolate] n'est fourni que par les tests, pour exercer le découpage
  /// sur la VM.
  static Future<GraphLayout> computeAsync(
    List<String> ids,
    List<(String, String)> edges, {
    bool? useIsolate,
    Duration sliceBudget = const Duration(milliseconds: 8),
  }) async {
    if (useIsolate ?? !kIsWeb) {
      return foundation.compute(_computeInIsolate, (ids, edges));
    }

    final job = GraphLayoutJob(ids, edges);
    final clock = Stopwatch();
    while (!job.isDone) {
      clock
        ..reset()
        ..start();
      // Au moins une étape par tranche : le calcul avance même si une seule
      // étape dépasse le budget.
      do {
        job.step();
      } while (!job.isDone && clock.elapsed < sliceBudget);
      if (!job.isDone) await Future<void>.delayed(Duration.zero);
    }
    return job.result;
  }
}

GraphLayout _computeInIsolate((List<String>, List<(String, String)>) input) =>
    GraphLayout.compute(input.$1, input.$2);

/// Calcul de [GraphLayout] découpé en étapes, pour pouvoir l'interrompre
/// entre deux frames. Une étape = une itération de la simulation, puis un
/// passage d'écartement des nœuds trop proches, puis le cadrage final.
///
/// Les opérations et leur ordre sont exactement ceux du calcul d'origine :
/// découpé ou non, le résultat est identique au bit près.
class GraphLayoutJob {
  GraphLayoutJob(
    Iterable<String> ids,
    Iterable<(String, String)> edges, {
    this.spacing = 170,
    this.padding = 120,
    this.iterations = 300,
  }) : _nodes = ids.toSet().toList()..sort() {
    // Tri ci-dessus : la carte ne dépend pas de l'ordre dans lequel la base
    // renvoie les fiches.
    final n = _nodes.length;

    final index = {for (var i = 0; i < n; i++) _nodes[i]: i};
    for (final (a, b) in edges) {
      final i = index[a];
      final j = index[b];
      if (i == null || j == null || i == j) continue;
      _links.add(i < j ? (i, j) : (j, i));
    }

    // Départ en tournesol (angle d'or) : bien réparti et reproductible.
    const goldenAngle = 2.399963229728653;
    _xs = List<double>.filled(n, 0);
    _ys = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final r = spacing * 0.6 * math.sqrt(i + 0.5);
      _xs[i] = r * math.cos(i * goldenAngle);
      _ys[i] = r * math.sin(i * goldenAngle);
    }
    _dx = List<double>.filled(n, 0);
    _dy = List<double>.filled(n, 0);
    _initialTemperature = spacing * math.max(1, math.sqrt(n));
  }

  final double spacing;
  final double padding;
  final int iterations;

  static const int _maxOverlapPasses = 100;

  final List<String> _nodes;
  final Set<(int, int)> _links = {};
  late final List<double> _xs;
  late final List<double> _ys;
  late final List<double> _dx;
  late final List<double> _dy;
  late final double _initialTemperature;

  int _step = 0;
  int _overlapPass = 0;
  bool _overlapsSettled = false;
  GraphLayout? _result;

  bool get isDone => _nodes.isEmpty || _result != null;

  GraphLayout get result {
    if (_nodes.isEmpty) return GraphLayout.empty;
    return _result ?? (throw StateError('Calcul de disposition non terminé'));
  }

  /// Avance d'une étape. Sans effet une fois le calcul terminé.
  void step() {
    if (isDone) return;
    if (_step < iterations) {
      _simulate(_step++);
    } else if (!_overlapsSettled && _overlapPass < _maxOverlapPasses) {
      _overlapPass++;
      _overlapsSettled = !_removeOverlapsOnce(spacing * 0.75);
    } else {
      _result = _frame();
    }
  }

  void _simulate(int step) {
    final n = _nodes.length;
    final xs = _xs, ys = _ys, dx = _dx, dy = _dy;
    final k = spacing;

    dx.fillRange(0, n, 0);
    dy.fillRange(0, n, 0);

    // Répulsion entre toutes les paires.
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final ddx = xs[i] - xs[j];
        final ddy = ys[i] - ys[j];
        final d = math.max(math.sqrt(ddx * ddx + ddy * ddy), 0.01);
        final f = k * k / d;
        dx[i] += ddx / d * f;
        dy[i] += ddy / d * f;
        dx[j] -= ddx / d * f;
        dy[j] -= ddy / d * f;
      }
    }

    // Attraction le long des liens.
    for (final (i, j) in _links) {
      final ddx = xs[i] - xs[j];
      final ddy = ys[i] - ys[j];
      final d = math.max(math.sqrt(ddx * ddx + ddy * ddy), 0.01);
      final f = d * d / k;
      dx[i] -= ddx / d * f;
      dy[i] -= ddy / d * f;
      dx[j] += ddx / d * f;
      dy[j] += ddy / d * f;
    }

    // Gravité vers le centre : sans elle, les îlots et les fiches isolées
    // s'éloigneraient indéfiniment les uns des autres.
    for (var i = 0; i < n; i++) {
      dx[i] -= xs[i];
      dy[i] -= ys[i];
    }

    final temperature =
        _initialTemperature * (1 - step / iterations) + spacing * 0.01;
    for (var i = 0; i < n; i++) {
      final length = math.sqrt(dx[i] * dx[i] + dy[i] * dy[i]);
      if (length < 1e-9) continue;
      final move = math.min(length, temperature);
      xs[i] += dx[i] / length * move;
      ys[i] += dy[i] / length * move;
    }
  }

  /// Un passage d'écartement des nœuds trop proches : les étiquettes ne
  /// doivent jamais se recouvrir, même quand la simulation n'a pas tout à
  /// fait convergé. Renvoie `true` si un nœud a bougé.
  bool _removeOverlapsOnce(double minDistance) {
    final n = _nodes.length;
    final xs = _xs, ys = _ys;
    var moved = false;
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        var ddx = xs[j] - xs[i];
        var ddy = ys[j] - ys[i];
        var d = math.sqrt(ddx * ddx + ddy * ddy);
        if (d >= minDistance) continue;
        if (d < 1e-6) {
          // Superposition parfaite : direction arbitraire mais stable.
          ddx = math.cos(i + j.toDouble());
          ddy = math.sin(i + j.toDouble());
          d = 1;
        }
        final push = (minDistance - d) / 2 + 0.5;
        xs[i] -= ddx / d * push;
        ys[i] -= ddy / d * push;
        xs[j] += ddx / d * push;
        ys[j] += ddy / d * push;
        moved = true;
      }
    }
    return moved;
  }

  /// Ramène les positions dans une toile qui commence à (0, 0), marges
  /// comprises.
  GraphLayout _frame() {
    final n = _nodes.length;
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (var i = 0; i < n; i++) {
      minX = math.min(minX, _xs[i]);
      minY = math.min(minY, _ys[i]);
      maxX = math.max(maxX, _xs[i]);
      maxY = math.max(maxY, _ys[i]);
    }

    return GraphLayout._(
      {
        for (var i = 0; i < n; i++)
          _nodes[i]: Offset(_xs[i] - minX + padding, _ys[i] - minY + padding),
      },
      Size(maxX - minX + 2 * padding, maxY - minY + 2 * padding),
    );
  }
}
