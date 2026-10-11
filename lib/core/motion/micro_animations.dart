import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'reduce_motion.dart';

/// Micro-animations de l'app (chantier 12, R4).
///
/// Toutes sont implicites (`TweenAnimationBuilder`) et passent par
/// [Motion.duration] : en mode « Animations réduites », la durée tombe à zéro
/// et l'état final s'affiche dès la première frame.

/// Retourne une carte : [front] tant que [revealed] est faux, puis [back],
/// avec une rotation autour de l'axe vertical.
///
/// Le premier affichage n'est jamais animé. Pour passer à une autre carte
/// sans la voir se retourner à l'envers, donner une clé différente par carte.
class FlipReveal extends StatelessWidget {
  const FlipReveal({
    super.key,
    required this.revealed,
    required this.front,
    required this.back,
  });

  final bool revealed;
  final Widget front;
  final Widget back;

  static const Duration duration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: revealed ? 1.0 : 0.0),
      duration: Motion.duration(context, duration),
      curve: Curves.easeInOut,
      builder: (context, turn, _) {
        final showsBack = turn >= 0.5;
        // Le verso tourne de -90° à 0° : il n'apparaît jamais en miroir.
        final angle = showsBack ? (turn - 1) * math.pi : turn * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012) // perspective légère
            ..rotateY(angle),
          child: showsBack ? back : front,
        );
      },
    );
  }
}
