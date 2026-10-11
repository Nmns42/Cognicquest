import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

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
    // Tri : la carte ne dépend pas de l'ordre dans lequel la base renvoie les
    // fiches.
    final nodes = ids.toSet().toList()..sort();
    final n = nodes.length;
    if (n == 0) return empty;

    final index = {for (var i = 0; i < n; i++) nodes[i]: i};
    final links = <(int, int)>{};
    for (final (a, b) in edges) {
      final i = index[a];
      final j = index[b];
      if (i == null || j == null || i == j) continue;
      links.add(i < j ? (i, j) : (j, i));
    }

    // Départ en tournesol (angle d'or) : bien réparti et reproductible.
    const goldenAngle = 2.399963229728653;
    final xs = List<double>.filled(n, 0);
    final ys = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final r = spacing * 0.6 * math.sqrt(i + 0.5);
      xs[i] = r * math.cos(i * goldenAngle);
      ys[i] = r * math.sin(i * goldenAngle);
    }

    final k = spacing;
    final initialTemperature = spacing * math.max(1, math.sqrt(n));
    final dx = List<double>.filled(n, 0);
    final dy = List<double>.filled(n, 0);

    for (var step = 0; step < iterations; step++) {
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
      for (final (i, j) in links) {
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
          initialTemperature * (1 - step / iterations) + spacing * 0.01;
      for (var i = 0; i < n; i++) {
        final length = math.sqrt(dx[i] * dx[i] + dy[i] * dy[i]);
        if (length < 1e-9) continue;
        final move = math.min(length, temperature);
        xs[i] += dx[i] / length * move;
        ys[i] += dy[i] / length * move;
      }
    }

    _removeOverlaps(xs, ys, spacing * 0.75);

    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (var i = 0; i < n; i++) {
      minX = math.min(minX, xs[i]);
      minY = math.min(minY, ys[i]);
      maxX = math.max(maxX, xs[i]);
      maxY = math.max(maxY, ys[i]);
    }

    return GraphLayout._(
      {
        for (var i = 0; i < n; i++)
          nodes[i]: Offset(xs[i] - minX + padding, ys[i] - minY + padding),
      },
      Size(maxX - minX + 2 * padding, maxY - minY + 2 * padding),
    );
  }

  /// Écarte les nœuds trop proches : les étiquettes ne doivent jamais se
  /// recouvrir, même quand la simulation n'a pas tout à fait convergé.
  static void _removeOverlaps(
    List<double> xs,
    List<double> ys,
    double minDistance,
  ) {
    final n = xs.length;
    for (var pass = 0; pass < 100; pass++) {
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
      if (!moved) return;
    }
  }
}
