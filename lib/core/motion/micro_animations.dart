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

/// Fait « battre » [child] une fois (agrandissement puis retour) chaque fois
/// que [trigger] change alors que [enabled] est vrai.
///
/// Pas de clé changeante : l'état de [child] (ses propres animations) est
/// conservé.
class PulseOnChange extends StatefulWidget {
  const PulseOnChange({
    super.key,
    required this.trigger,
    this.enabled = true,
    this.scale = 1.08,
    this.duration = const Duration(milliseconds: 320),
    required this.child,
  });

  final Object? trigger;
  final bool enabled;
  final double scale;
  final Duration duration;
  final Widget child;

  @override
  State<PulseOnChange> createState() => _PulseOnChangeState();
}

class _PulseOnChangeState extends State<PulseOnChange> {
  int _pulses = 0;

  @override
  void didUpdateWidget(PulseOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.enabled) _pulses++;
  }

  @override
  Widget build(BuildContext context) {
    // La valeur avance d'une unité par battement ; sa partie décimale décrit
    // le battement en cours, et vaut 0 au repos (échelle 1).
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _pulses.toDouble()),
      duration: Motion.duration(context, widget.duration),
      child: widget.child,
      builder: (context, value, child) {
        final phase = value - value.floorToDouble();
        final scale = 1 + (widget.scale - 1) * math.sin(math.pi * phase);
        return Transform.scale(scale: scale, child: child);
      },
    );
  }
}

/// Affiche [value] via [builder] ; quand la valeur augmente, le nouvel
/// affichage monte légèrement en apparaissant. Une baisse est instantanée.
class RollingNumber extends StatefulWidget {
  const RollingNumber({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 280),
  });

  final int value;
  final Widget Function(BuildContext context, int value) builder;
  final Duration duration;

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> {
  int _rolls = 0;

  @override
  void didUpdateWidget(RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value > oldWidget.value) _rolls++;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _rolls.toDouble()),
      duration: Motion.duration(context, widget.duration),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        // En cours d'animation : progression de 0 à 1 ; au repos : 1.
        final progress =
            value < _rolls ? value - value.floorToDouble() : 1.0;
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 8),
            child: widget.builder(context, widget.value),
          ),
        );
      },
    );
  }
}
