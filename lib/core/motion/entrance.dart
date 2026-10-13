import 'package:flutter/material.dart';

import 'reduce_motion.dart';

/// Chorégraphie d'entrée des écrans (maquette de référence).
///
/// Trois gestes, échelonnés : la structure se pose d'abord (« panel
/// settle »), puis les grands titres se dévoilent (« type unmask »), enfin
/// les détails montent doucement (« content rise »). Chaque geste ne joue
/// qu'une fois, à l'apparition du widget, et disparaît entièrement en
/// animations réduites : l'état final s'affiche directement.
abstract final class Entrance {
  /// Courbe de la maquette : `cubic-bezier(.16, 1, .3, 1)`.
  static const Curve curve = Cubic(0.16, 1, 0.3, 1);

  static const Duration settle = Duration(milliseconds: 700);
  static const Duration unmask = Duration(milliseconds: 650);
  static const Duration rise = Duration(milliseconds: 600);

  /// Écart entre deux éléments d'une même vague.
  static const Duration stagger = Duration(milliseconds: 60);

  /// Retard des titres sur la structure, puis des détails sur les titres.
  static const Duration titleDelay = Duration(milliseconds: 120);
  static const Duration detailDelay = Duration(milliseconds: 220);

  /// Au-delà, les éléments suivants entrent ensemble : une longue liste ne
  /// doit pas mettre une seconde à apparaître.
  static const int maxStaggered = 6;

  /// Retard du [index]-ième élément d'une vague commençant à [base].
  static Duration delayFor(int index, {Duration base = Duration.zero}) =>
      base + stagger * index.clamp(0, maxStaggered);
}

/// Base commune : un contrôleur joué une fois, après [delay].
abstract class _EntranceState<T extends StatefulWidget> extends State<T>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> progress;

  Duration get delay;
  Duration get duration;

  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    final total = delay + duration;
    controller = AnimationController(vsync: this, duration: total);
    final start = total.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;
    progress = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1, curve: Entrance.curve),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = Motion.reduced(context);
    if (_reduced) {
      controller.value = 1;
    } else if (!controller.isAnimating && controller.value == 0) {
      controller.forward();
    }
  }

  bool get reduced => _reduced;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// « Panel settle » : la carte se pose (fondu, légère montée, échelle 0,98
/// → 1).
class PanelSettle extends StatefulWidget {
  const PanelSettle({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<PanelSettle> createState() => _PanelSettleState();
}

class _PanelSettleState extends _EntranceState<PanelSettle> {
  @override
  Duration get delay => widget.delay;

  @override
  Duration get duration => Entrance.settle;

  static final Tween<Offset> _slide =
      Tween(begin: const Offset(0, 0.04), end: Offset.zero);
  static final Tween<double> _scale = Tween(begin: 0.98, end: 1);

  @override
  Widget build(BuildContext context) {
    if (reduced) return widget.child;
    return FadeTransition(
      opacity: progress,
      child: SlideTransition(
        position: _slide.animate(progress),
        child: ScaleTransition(
          scale: _scale.animate(progress),
          child: widget.child,
        ),
      ),
    );
  }
}

/// « Type unmask » : le titre monte depuis le bas, révélé par un masque à sa
/// propre hauteur.
class TypeUnmask extends StatefulWidget {
  const TypeUnmask({
    super.key,
    required this.child,
    this.delay = Entrance.titleDelay,
  });

  final Widget child;
  final Duration delay;

  @override
  State<TypeUnmask> createState() => _TypeUnmaskState();
}

class _TypeUnmaskState extends _EntranceState<TypeUnmask> {
  @override
  Duration get delay => widget.delay;

  @override
  Duration get duration => Entrance.unmask;

  static final Tween<Offset> _slide =
      Tween(begin: const Offset(0, 1), end: Offset.zero);

  @override
  Widget build(BuildContext context) {
    if (reduced) return widget.child;
    return ClipRect(
      child: SlideTransition(
        position: _slide.animate(progress),
        child: widget.child,
      ),
    );
  }
}

/// « Content rise » : sous-titres et étiquettes montent doucement en
/// apparaissant.
class ContentRise extends StatefulWidget {
  const ContentRise({
    super.key,
    required this.child,
    this.delay = Entrance.detailDelay,
  });

  final Widget child;
  final Duration delay;

  @override
  State<ContentRise> createState() => _ContentRiseState();
}

class _ContentRiseState extends _EntranceState<ContentRise> {
  @override
  Duration get delay => widget.delay;

  @override
  Duration get duration => Entrance.rise;

  static final Tween<Offset> _slide =
      Tween(begin: const Offset(0, 0.35), end: Offset.zero);

  @override
  Widget build(BuildContext context) {
    if (reduced) return widget.child;
    return FadeTransition(
      opacity: progress,
      child: SlideTransition(
        position: _slide.animate(progress),
        child: widget.child,
      ),
    );
  }
}
