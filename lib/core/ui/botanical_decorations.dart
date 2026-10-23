import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/botanical_palette.dart';

/// Motifs végétaux de la direction « Botanique sophistiqué & pleine
/// conscience » : filigranes du fond, feuillage des bannières, couronne de
/// laurier et arbre compagnon.
///
/// Tout est peint au vecteur (aucune image, aucune dépendance), aux teintes
/// du thème ([BotanicalPalette], [CognicColors]) : le motif suit le thème
/// clair ou sombre. Les décors sont exclus de l'accessibilité et ne captent
/// aucun geste.

// ─── Formes de base ─────────────────────────────────────────────────────────

/// Feuille lancéolée couchée sur l'axe x, de la base (0, 0) à la pointe
/// (`length`, 0).
Path _leafPath(double length, double width) => Path()
  ..moveTo(0, 0)
  ..cubicTo(length * 0.25, -width, length * 0.7, -width * 0.85, length, 0)
  ..cubicTo(length * 0.7, width * 0.85, length * 0.25, width, 0, 0)
  ..close();

/// Feuille de lierre à trois lobes, pointe vers -y, base en (0, 0).
Path _ivyPath(double size) {
  final s = size;
  return Path()
    ..moveTo(0, 0)
    ..cubicTo(-s * 0.55, s * 0.05, -s * 0.75, -s * 0.35, -s * 0.45, -s * 0.45)
    ..cubicTo(-s * 0.55, -s * 0.75, -s * 0.2, -s * 0.85, 0, -s)
    ..cubicTo(s * 0.2, -s * 0.85, s * 0.55, -s * 0.75, s * 0.45, -s * 0.45)
    ..cubicTo(s * 0.75, -s * 0.35, s * 0.55, s * 0.05, 0, 0)
    ..close();
}

/// Dessine une feuille pleine (et sa nervure) en [at], orientée selon
/// [angle] (radians, 0 = vers la droite).
void _drawLeaf(
  Canvas canvas,
  Offset at,
  double angle,
  double length,
  double width,
  Color fill, {
  Color? vein,
}) {
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(angle);
  canvas.drawPath(_leafPath(length, width), Paint()..color = fill);
  if (vein != null) {
    canvas.drawLine(
      Offset(length * 0.06, 0),
      Offset(length * 0.82, 0),
      Paint()
        ..color = vein
        ..strokeWidth = math.max(0.8, width * 0.08)
        ..strokeCap = StrokeCap.round,
    );
  }
  canvas.restore();
}

/// Point d'une courbe de Bézier quadratique, et sa tangente (en radians).
(Offset, double) _onQuad(Offset a, Offset c, Offset b, double t) {
  final u = 1 - t;
  final p = a * (u * u) + c * (2 * u * t) + b * (t * t);
  final d = (c - a) * (2 * u) + (b - c) * (2 * t);
  return (p, math.atan2(d.dy, d.dx));
}

Widget _decor(CustomPainter painter, {Widget? child}) => IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(painter: painter, child: child),
        ),
      ),
    );

// ─── Filigranes du fond ─────────────────────────────────────────────────────

/// Fond de l'application : parchemin du thème et, dans les coins, des
/// rameaux et des feuilles en filigrane doré, à faible opacité.
///
/// Peint une seule fois sous toutes les pages (les `Scaffold` sont
/// transparents), dans sa propre couche de rendu.
class BotanicalWatermarkBackground extends StatelessWidget {
  const BotanicalWatermarkBackground({super.key, required this.child});

  final Widget child;

  /// Opacité des filigranes : présents, jamais en concurrence avec le texte.
  static const double opacity = 0.55;

  @override
  Widget build(BuildContext context) {
    final palette = BotanicalPalette.of(context);
    return ColoredBox(
      color: context.cq.beige,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _decor(_WatermarkPainter(
              palette.watermark.withValues(alpha: opacity))),
          child,
        ],
      ),
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  const _WatermarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height);
    // Grand rameau en haut à droite, qui retombe vers l'intérieur.
    _spray(canvas, Offset(size.width + unit * 0.02, -unit * 0.04),
        math.pi * 0.7, unit * 0.62, unit * 0.11);
    // Rameau en bas à gauche, qui monte.
    _spray(canvas, Offset(-unit * 0.03, size.height + unit * 0.03),
        -math.pi * 0.3, unit * 0.5, unit * 0.095);
    // Brins plus discrets dans les deux autres coins.
    _spray(canvas, Offset(-unit * 0.02, unit * 0.22), -math.pi * 0.08,
        unit * 0.3, unit * 0.06);
    _spray(canvas, Offset(size.width + unit * 0.02, size.height - unit * 0.1),
        math.pi * 1.12, unit * 0.36, unit * 0.07);
  }

  /// Tige courbe et feuilles alternées qui rapetissent vers la pointe.
  void _spray(Canvas canvas, Offset origin, double angle, double length,
      double leaf) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    final a = Offset.zero;
    final c = Offset(length * 0.5, length * 0.08);
    final b = Offset(length, 0);
    canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, leaf * 0.06)
        ..strokeCap = StrokeCap.round,
    );
    const leaves = 9;
    for (var i = 1; i <= leaves; i++) {
      final t = i / (leaves + 1);
      final (p, tangent) = _onQuad(a, c, b, t);
      final side = i.isEven ? 1.0 : -1.0;
      final scale = 1 - t * 0.5;
      _drawLeaf(canvas, p, tangent + side * math.pi * 0.3, leaf * scale,
          leaf * scale * 0.34, color);
    }
    _drawLeaf(canvas, b, 0, leaf * 0.5, leaf * 0.17, color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WatermarkPainter old) => old.color != color;
}

// ─── Feuillage de la bannière ───────────────────────────────────────────────

/// Bouquet de tiges, lierre grimpant, feuilles de sauge et jeunes pousses,
/// qui s'épanouit dans la boîte qu'on lui donne (à droite d'une bannière).
class HeroFoliageOverlay extends StatelessWidget {
  const HeroFoliageOverlay({super.key});

  @override
  Widget build(BuildContext context) =>
      _decor(_FoliagePainter(BotanicalPalette.of(context)));
}

class _FoliagePainter extends CustomPainter {
  const _FoliagePainter(this.p);

  final BotanicalPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = math.min(w, h * 1.2);

    // Mottes de terre au pied du bouquet.
    final soil = Paint()..color = p.bark.withValues(alpha: 0.55);
    for (final (x, r) in const [(0.22, 0.07), (0.5, 0.09), (0.84, 0.08)]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(w * x, h + unit * r * 0.15),
              width: unit * r * 2.4,
              height: unit * r * 1.1),
          soil);
    }

    // Tiges brunes à graines, à gauche.
    final stalk = Paint()
      ..color = p.bark
      ..strokeWidth = math.max(1.2, unit * 0.008)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (x, top, lean) in const [(0.12, 0.42, -0.04), (0.2, 0.3, 0.03)]) {
      final base = Offset(w * x, h);
      final tip = Offset(w * (x + lean), h * top);
      canvas.drawLine(base, tip, stalk);
      for (var i = 0; i < 7; i++) {
        final t = 0.15 + i * 0.12;
        final at = Offset.lerp(tip, base, t * 0.7)!;
        for (final side in const [-1.0, 1.0]) {
          _drawLeaf(canvas, at, -math.pi / 2 + side * 0.9, unit * 0.04,
              unit * 0.016, p.bark);
        }
      }
    }

    // Lierre grimpant, au centre : tige sinueuse et feuilles à trois lobes.
    final vine = Path()..moveTo(w * 0.42, h);
    vine.cubicTo(w * 0.3, h * 0.7, w * 0.6, h * 0.5, w * 0.44, h * 0.3);
    vine.cubicTo(w * 0.36, h * 0.18, w * 0.5, h * 0.06, w * 0.56, h * 0.02);
    canvas.drawPath(
        vine,
        Paint()
          ..color = p.leafDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.4, unit * 0.01)
          ..strokeCap = StrokeCap.round);
    final metrics = vine.computeMetrics().first;
    for (var i = 1; i <= 7; i++) {
      final tangent =
          metrics.getTangentForOffset(metrics.length * i / 8.2)!;
      final side = i.isEven ? 1.0 : -1.0;
      final size = unit * (0.12 - i * 0.007);
      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(-tangent.angle + side * 1.1);
      canvas.drawPath(
          _ivyPath(size), Paint()..color = i.isEven ? p.leafLight : p.leafMid);
      canvas.restore();
    }
    // Vrille au sommet.
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.56, h * 0.02)
          ..quadraticBezierTo(w * 0.62, h * 0.0, w * 0.6, h * 0.08),
        Paint()
          ..color = p.leafLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, unit * 0.006));

    // Grandes feuilles de sauge en éventail, à droite.
    final base = Offset(w * 0.82, h);
    for (final (angle, length, light) in const [
      (-2.0, 0.55, false),
      (-1.75, 0.78, true),
      (-1.5, 0.92, false),
      (-1.28, 0.7, true),
      (-1.05, 0.5, false),
    ]) {
      _drawLeaf(canvas, base, angle, unit * length, unit * length * 0.16,
          light ? p.leafLight : p.leafMid,
          vein: p.leafDark);
    }

    // Jeunes pousses à deux feuilles.
    for (final x in const [0.3, 0.64]) {
      final foot = Offset(w * x, h);
      final top = Offset(w * x, h - unit * 0.1);
      canvas.drawLine(foot, top, Paint()
        ..color = p.leafLight
        ..strokeWidth = math.max(1.2, unit * 0.008));
      _drawLeaf(canvas, top, -math.pi * 0.85, unit * 0.07, unit * 0.03,
          p.leafLight);
      _drawLeaf(canvas, top, -math.pi * 0.15, unit * 0.07, unit * 0.03,
          p.leafLight);
    }
  }

  @override
  bool shouldRepaint(_FoliagePainter old) => old.p != p;
}

// ─── Couronne de laurier ────────────────────────────────────────────────────

/// Couronne de feuilles autour d'une flamme ambre : le compteur de série.
class LaurelStreakBadge extends StatelessWidget {
  const LaurelStreakBadge({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: _decor(
        _LaurelPainter(BotanicalPalette.of(context)),
        child: Center(
          child: Icon(Icons.local_fire_department,
              size: size * 0.5, color: context.cq.ambre),
        ),
      ),
    );
  }
}

class _LaurelPainter extends CustomPainter {
  const _LaurelPainter(this.p);

  final BotanicalPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.38;
    final leaf = size.shortestSide * 0.26;
    // Deux branches qui partent du bas et montent de chaque côté.
    for (final side in const [-1.0, 1.0]) {
      const count = 8;
      for (var i = 0; i < count; i++) {
        // De 105° (bas) à -50° (haut), en coordonnées écran.
        final deg = 105 - i * 22.0;
        final a = (side < 0 ? 180 - deg : deg) * math.pi / 180;
        final at = center + Offset(math.cos(a), math.sin(a)) * radius;
        // Feuille tangente à l'arc, pointe vers le haut de la couronne.
        final tangent = a + (side < 0 ? math.pi / 2 : -math.pi / 2);
        _drawLeaf(canvas, at, tangent - side * 0.5, leaf * (1 - i * 0.04),
            leaf * 0.34, i.isEven ? p.leafLight : p.leafMid,
            vein: p.leafDark);
      }
    }
  }

  @override
  bool shouldRepaint(_LaurelPainter old) => old.p != p;
}

// ─── Arbre compagnon ────────────────────────────────────────────────────────

/// Arbre stylisé qui grandit avec la régularité : [growth] de 0 (jeune
/// pousse) à 1 (arbre en fleurs). Tronc d'écorce, feuillage sauge et forêt,
/// petites fleurs crème.
class MindfulTreeIllustration extends StatelessWidget {
  const MindfulTreeIllustration({super.key, required this.growth});

  final double growth;

  @override
  Widget build(BuildContext context) {
    final g = growth.clamp(0.0, 1.0);
    return Semantics(
      image: true,
      label: 'Arbre de détente, croissance ${(g * 100).round()} %',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _TreePainter(
              palette: BotanicalPalette.of(context),
              forest: context.cq.vert,
              growth: g,
            ),
          ),
        ),
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  const _TreePainter({
    required this.palette,
    required this.forest,
    required this.growth,
  });

  final BotanicalPalette palette;
  final Color forest;
  final double growth;

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    final w = size.width;
    final h = size.height;
    final unit = math.min(w, h);
    // L'arbre occupe de 55 % (pousse) à 100 % de la hauteur disponible.
    final scale = 0.62 + 0.38 * growth;
    final ground = Offset(w / 2, h * 0.94);

    // Ombre au sol.
    canvas.drawOval(
        Rect.fromCenter(
            center: ground, width: unit * 0.62 * scale, height: unit * 0.06),
        Paint()..color = p.watermark.withValues(alpha: 0.8));

    // Tronc effilé et deux maîtresses branches.
    final trunkH = h * 0.36 * scale;
    final top = ground.translate(0, -trunkH);
    final base = unit * 0.05 * scale;
    final bark = Paint()..color = p.bark;
    canvas.drawPath(
        Path()
          ..moveTo(ground.dx - base, ground.dy)
          ..quadraticBezierTo(ground.dx - base * 0.3, ground.dy - trunkH * 0.5,
              top.dx - base * 0.35, top.dy)
          ..lineTo(top.dx + base * 0.35, top.dy)
          ..quadraticBezierTo(ground.dx + base * 0.3, ground.dy - trunkH * 0.5,
              ground.dx + base, ground.dy)
          ..close(),
        bark);
    final branch = Paint()
      ..color = p.bark
      ..style = PaintingStyle.stroke
      ..strokeWidth = base * 0.45
      ..strokeCap = StrokeCap.round;
    for (final side in const [-1.0, 1.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(top.dx, top.dy + trunkH * 0.25)
            ..quadraticBezierTo(top.dx + side * unit * 0.08 * scale, top.dy,
                top.dx + side * unit * 0.16 * scale, top.dy - trunkH * 0.18),
          branch);
    }

    // Houppier : grappes de disques, de l'ombre (forêt) à la lumière.
    final crown = top.translate(0, -h * 0.2 * scale);
    final r = unit * 0.17 * scale;
    final clusters = <(double, double, double)>[
      (-1.2, 0.3, 1.0), (1.2, 0.3, 1.0), (0, 0.45, 1.05),
      (-0.7, -0.5, 1.1), (0.7, -0.5, 1.1), (0, -0.9, 1.0),
      (-1.6, -0.3, 0.8), (1.6, -0.3, 0.8),
    ];
    // Moins de grappes pour une jeune pousse.
    final shown = 3 + (growth * (clusters.length - 3)).round();
    for (final (layer, color) in [
      (1.12, forest),
      (1.0, p.leafMid),
      (0.62, p.leafLight),
    ]) {
      final paint = Paint()..color = color;
      for (final (dx, dy, k) in clusters.take(shown)) {
        final c = crown + Offset(dx * r, dy * r);
        // La lumière vient d'en haut à gauche.
        final shift = layer < 1 ? Offset(-r * 0.22, -r * 0.25) : Offset.zero;
        canvas.drawCircle(c + shift, r * k * layer * 0.95, paint);
      }
    }

    // Petites fleurs crème au cœur jaune-brun, plus nombreuses avec la
    // régularité.
    final flowers = (growth * 6).round();
    const spots = [
      (-0.9, -0.2), (0.8, 0.1), (0.1, -1.0), (-0.3, 0.5), (1.3, -0.5),
      (-1.4, 0.2),
    ];
    for (final (dx, dy) in spots.take(flowers)) {
      final c = crown + Offset(dx * r, dy * r);
      final petal = r * 0.16;
      final paint = Paint()..color = p.bloom;
      for (var i = 0; i < 5; i++) {
        final a = i * 2 * math.pi / 5;
        canvas.drawCircle(
            c + Offset(math.cos(a), math.sin(a)) * petal, petal * 0.75, paint);
      }
      canvas.drawCircle(c, petal * 0.55, Paint()..color = p.bark);
    }
  }

  @override
  bool shouldRepaint(_TreePainter old) =>
      old.growth != growth || old.palette != palette || old.forest != forest;
}
