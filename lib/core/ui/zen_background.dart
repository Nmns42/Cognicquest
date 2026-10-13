import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fond de l'application : le beige du thème et, dans les angles, quelques
/// feuilles dessinées au trait, à peine visibles.
///
/// Un rappel du végétal pour apaiser l'œil, jamais un motif qui attire le
/// regard : traits fins, opacité très basse, aucun mouvement. Peint une seule
/// fois sous toutes les pages (les `Scaffold` sont transparents), et isolé
/// dans sa propre couche de rendu pour ne pas être redessiné à chaque image.
class ZenBackground extends StatelessWidget {
  const ZenBackground({super.key, required this.child});

  final Widget child;

  /// Opacité du trait : sous le seuil où il ferait concurrence au texte.
  static const double inkOpacity = 0.07;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return ColoredBox(
      color: cq.beige,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: LeafPainter(
                    color: cq.vertDark.withValues(alpha: inkOpacity),
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Feuilles d'eucalyptus et de sauge au trait, en haut à droite et en bas à
/// gauche. Tailles relatives au plus petit côté de l'écran : le motif garde
/// ses proportions du téléphone au grand écran.
class LeafPainter extends CustomPainter {
  const LeafPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, unit / 400)
      ..strokeCap = StrokeCap.round;

    // Rameau en haut à droite, qui retombe vers l'intérieur.
    _branch(
      canvas,
      stroke,
      origin: Offset(size.width + unit * 0.04, -unit * 0.02),
      angle: math.pi * 0.72,
      length: unit * 0.55,
      leafSize: unit * 0.09,
    );
    // Rameau en bas à gauche, qui monte.
    _branch(
      canvas,
      stroke,
      origin: Offset(-unit * 0.04, size.height + unit * 0.02),
      angle: -math.pi * 0.28,
      length: unit * 0.45,
      leafSize: unit * 0.075,
    );
  }

  /// Une tige légèrement courbe et des paires de feuilles alternées.
  void _branch(
    Canvas canvas,
    Paint paint, {
    required Offset origin,
    required double angle,
    required double length,
    required double leafSize,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final stem = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, length * 0.06, length, 0);
    canvas.drawPath(stem, paint);

    const pairs = 6;
    for (var i = 1; i <= pairs; i++) {
      final t = i / (pairs + 1);
      final x = length * t;
      final y = length * 0.06 * 4 * t * (1 - t) * 0.5;
      // Les feuilles rapetissent vers la pointe du rameau.
      final scale = 1 - t * 0.45;
      for (final side in const [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(side * math.pi * 0.28);
        _leaf(canvas, paint, leafSize * scale, side);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  /// Feuille en amande avec sa nervure centrale.
  void _leaf(Canvas canvas, Paint paint, double size, double side) {
    final w = size * 0.42 * side;
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size * 0.5, -w, size, 0)
      ..quadraticBezierTo(size * 0.5, w * 0.35, 0, 0);
    canvas.drawPath(leaf, paint);
    canvas.drawLine(Offset.zero, Offset(size * 0.8, -w * 0.08), paint);
  }

  @override
  bool shouldRepaint(LeafPainter oldDelegate) => oldDelegate.color != color;
}
