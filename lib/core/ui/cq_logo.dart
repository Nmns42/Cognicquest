import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/logo_palette.dart';

/// Logo CognicQuest « Arbre-Neurone » : racines et tronc d'écorce, branches
/// qui se terminent en neurones, houppier organique (feuillage à lobes) qui
/// enveloppe le réseau.
///
/// Couleurs du thème par défaut ([LogoPalette.of]) : lisible en clair comme
/// en sombre. Source unique du dessin : `assets/logo/cognicquest-logo.svg`
/// et toutes les icônes (`tool/generate_icons_test.dart`) en dérivent.
class CqLogo extends StatelessWidget {
  const CqLogo({super.key, this.size = 24, this.palette});

  final double size;

  /// Couleurs imposées (icônes générées) ; sinon celles du thème.
  final LogoPalette? palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'CognicQuest',
      child: CustomPaint(
        size: Size.square(size),
        painter: CqLogoPainter(palette ?? LogoPalette.of(context.cq)),
      ),
    );
  }
}

/// Dessin du logo dans un carré, sur une grille de 512 unités.
class CqLogoPainter extends CustomPainter {
  const CqLogoPainter(this.palette, {this.inset = 0});

  final LogoPalette palette;

  /// Marge relative (0 à 0,5) : 0,1 pour la zone sûre des icônes maskables.
  final double inset;

  static const double grid = 512;

  /// Houppier : silhouette de feuillage à cinq lobes.
  static Path canopy() => Path()
    ..moveTo(150, 268)
    ..cubicTo(102, 262, 84, 206, 118, 172)
    ..cubicTo(108, 120, 160, 82, 208, 100)
    ..cubicTo(228, 62, 288, 58, 312, 96)
    ..cubicTo(362, 82, 410, 122, 396, 172)
    ..cubicTo(432, 204, 414, 262, 362, 268)
    ..cubicTo(330, 286, 290, 280, 274, 268)
    ..lineTo(238, 268)
    ..cubicTo(222, 280, 182, 286, 150, 268)
    ..close();

  /// Synapses : courbes entre les terminaisons.
  static Path synapses() => Path()
    ..moveTo(196, 206)
    ..quadraticBezierTo(214, 158, 256, 150)
    ..moveTo(316, 206)
    ..quadraticBezierTo(298, 158, 256, 150);

  /// Tronc et branches.
  static Path branches() => Path()
    ..moveTo(256, 330)
    ..lineTo(256, 150)
    ..moveTo(256, 288)
    ..cubicTo(244, 252, 214, 236, 196, 206)
    ..moveTo(256, 288)
    ..cubicTo(268, 252, 298, 236, 316, 206);

  /// Bas du tronc et racines.
  static Path roots() => Path()
    ..moveTo(256, 326)
    ..lineTo(256, 384)
    ..moveTo(256, 380)
    ..cubicTo(254, 408, 226, 420, 196, 432)
    ..moveTo(256, 380)
    ..cubicTo(258, 408, 286, 420, 316, 432)
    ..moveTo(256, 384)
    ..lineTo(256, 444);

  static const List<(Offset, double)> neurons = [
    (Offset(256, 150), 22),
    (Offset(196, 206), 19),
    (Offset(316, 206), 19),
  ];

  static const List<Offset> rootTips = [
    Offset(196, 432),
    Offset(316, 432),
    Offset(256, 444),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final drawn = side * (1 - 2 * inset);
    canvas.save();
    canvas.translate(
      (size.width - drawn) / 2,
      (size.height - drawn) / 2,
    );
    canvas.scale(drawn / grid);

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(canopy(), stroke(palette.canopy, 18));
    canvas.drawPath(synapses(), stroke(palette.canopy, 12));
    canvas.drawPath(branches(), stroke(palette.branches, 24));
    canvas.drawPath(roots(), stroke(palette.roots, 24));

    final branchFill = Paint()..color = palette.branches;
    for (final (center, radius) in neurons) {
      canvas.drawCircle(center, radius, branchFill);
    }
    final rootFill = Paint()..color = palette.roots;
    for (final tip in rootTips) {
      canvas.drawCircle(tip, 14, rootFill);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CqLogoPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.inset != inset;
}
