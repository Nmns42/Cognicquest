import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'botanical_decorations.dart';

/// Fond de l'application : délègue aux filigranes botaniques
/// ([BotanicalWatermarkBackground]). Gardé sous ce nom pour le Shell.
class ZenBackground extends StatelessWidget {
  const ZenBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BotanicalWatermarkBackground(child: child);
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

    // Eucalyptus à feuilles rondes, en haut à gauche et en bas à droite :
    // une autre silhouette, pour que le motif ne paraisse pas répété.
    _roundSprig(
      canvas,
      stroke,
      origin: Offset(-unit * 0.02, unit * 0.18),
      angle: -math.pi * 0.06,
      length: unit * 0.32,
      leafRadius: unit * 0.032,
    );
    _roundSprig(
      canvas,
      stroke,
      origin: Offset(size.width + unit * 0.02, size.height - unit * 0.12),
      angle: math.pi * 1.1,
      length: unit * 0.38,
      leafRadius: unit * 0.038,
    );

    // Quelques feuilles tombées, isolées, vers le centre des marges.
    for (final (dx, dy, turn, scale) in const [
      (0.12, 0.55, 0.15, 0.9),
      (0.88, 0.38, -0.35, 0.7),
      (0.64, 0.92, 0.6, 0.8),
    ]) {
      canvas.save();
      canvas.translate(size.width * dx, size.height * dy);
      canvas.rotate(math.pi * turn);
      _leaf(canvas, stroke, unit * 0.06 * scale, 1);
      canvas.restore();
    }
  }

  /// Tige d'eucalyptus : feuilles rondes alternées, de plus en plus petites.
  void _roundSprig(
    Canvas canvas,
    Paint paint, {
    required Offset origin,
    required double angle,
    required double length,
    required double leafRadius,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    final stem = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -length * 0.08, length, 0);
    canvas.drawPath(stem, paint);

    const leaves = 7;
    for (var i = 1; i <= leaves; i++) {
      final t = i / (leaves + 1);
      final side = i.isEven ? 1.0 : -1.0;
      final r = leafRadius * (1 - t * 0.5);
      final center = Offset(length * t, -length * 0.08 * 4 * t * (1 - t) * 0.5)
          .translate(0, side * r * 1.15);
      canvas.drawOval(
          Rect.fromCenter(center: center, width: r * 2, height: r * 1.7),
          paint);
    }
    canvas.restore();
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
