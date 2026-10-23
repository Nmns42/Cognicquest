import 'package:flutter/material.dart';

import '../motion/reduce_motion.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Rend visible son enfant au survol de la souris (ou quand [visible] le
/// force, par exemple pendant un glisser), avec un fondu.
///
/// Masqué, l'enfant reste à sa place et reste attrapable : la mise en page
/// ne saute pas quand il apparaît. Au doigt, il n'y a pas de survol : la
/// poignée ne s'affiche pas, et l'appui long sur l'élément prend le relais.
class HoverReveal extends StatelessWidget {
  const HoverReveal({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: Motion.duration(context, CqMotion.fast),
      curve: CqMotion.standard,
      child: child,
    );
  }
}

/// Suit le survol de la souris sur [builder] : `true` tant que le pointeur
/// est au-dessus.
class HoverBuilder extends StatefulWidget {
  const HoverBuilder({super.key, required this.builder, this.cursor});

  final Widget Function(BuildContext context, bool hovered) builder;
  final MouseCursor? cursor;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor ?? MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(context, _hovered),
    );
  }
}

/// Élément d'une `ReorderableListView` (avec `buildDefaultDragHandles:
/// false`) : poignée discrète qui n'apparaît qu'au survol, et appui long sur
/// tout l'élément au doigt.
///
/// [longPressAnywhere] à `false` quand l'élément contient un champ de texte :
/// l'appui long y sert à sélectionner, pas à déplacer.
class CqReorderableItem extends StatelessWidget {
  const CqReorderableItem({
    super.key,
    required this.index,
    required this.child,
    this.gripLeading = false,
    this.longPressAnywhere = true,
    this.semanticLabel = 'Déplacer',
  });

  final int index;
  final Widget child;
  final bool gripLeading;
  final bool longPressAnywhere;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (context, hovered) {
        final grip = ReorderableDragStartListener(
          index: index,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Semantics(
              label: semanticLabel,
              child: SizedBox(
                width: Sizes.iconLg,
                child: HoverReveal(
                  visible: hovered,
                  child: Icon(Icons.drag_indicator,
                      size: Sizes.iconMd, color: context.cq.textMuted),
                ),
              ),
            ),
          ),
        );

        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (gripLeading) ...[grip, const SizedBox(width: Space.xs)],
            Expanded(child: child),
            if (!gripLeading) ...[const SizedBox(width: Space.xs), grip],
          ],
        );

        if (!longPressAnywhere) return row;
        return ReorderableDelayedDragStartListener(index: index, child: row);
      },
    );
  }
}

/// Élément que l'on peut attraper et déposer sur un `DragTarget<T>`.
///
/// - À la souris : le glisser démarre aussitôt (curseur « main »), comme sur
///   un bureau.
/// - Au doigt : il démarre après un court appui, pour laisser la liste
///   défiler normalement.
///
/// Le mode est figé pendant un glisser : le pointeur qui sort de l'élément
/// ne doit pas l'interrompre.
class CqDraggable<T extends Object> extends StatefulWidget {
  const CqDraggable({
    super.key,
    required this.data,
    required this.child,
    required this.feedback,
    this.childWhenDragging,
    this.feedbackWidth,
    this.onDragUpdate,
    this.onDragEnd,
  });

  final T data;
  final Widget child;

  /// Ce qui suit le pointeur ; légèrement soulevé par [CqDraggable].
  final Widget feedback;
  final Widget? childWhenDragging;
  final double? feedbackWidth;
  final DragUpdateCallback? onDragUpdate;
  final DragEndCallback? onDragEnd;

  /// Délai de l'appui long au doigt.
  static const Duration touchDelay = Duration(milliseconds: 180);

  @override
  State<CqDraggable<T>> createState() => _CqDraggableState<T>();
}

class _CqDraggableState<T extends Object> extends State<CqDraggable<T>> {
  bool _mouseOver = false;
  bool _dragging = false;

  /// Garde l'enfant (et son état, par exemple « survolé ») quand on passe
  /// du mode doigt au mode souris : sans elle, l'enfant était recréé et
  /// oubliait le survol en cours.
  final GlobalKey _childKey = GlobalKey();

  void _setDragging(bool value) {
    if (mounted) setState(() => _dragging = value);
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _LiftedFeedback(
      width: widget.feedbackWidth,
      child: widget.feedback,
    );

    final Widget draggable;
    if (_mouseOver) {
      draggable = Draggable<T>(
        data: widget.data,
        feedback: feedback,
        childWhenDragging: widget.childWhenDragging,
        onDragStarted: () => _setDragging(true),
        onDragUpdate: widget.onDragUpdate,
        onDragEnd: (details) {
          _setDragging(false);
          widget.onDragEnd?.call(details);
        },
        child: KeyedSubtree(key: _childKey, child: widget.child),
      );
    } else {
      draggable = LongPressDraggable<T>(
        data: widget.data,
        delay: CqDraggable.touchDelay,
        feedback: feedback,
        childWhenDragging: widget.childWhenDragging,
        onDragStarted: () => _setDragging(true),
        onDragUpdate: widget.onDragUpdate,
        onDragEnd: (details) {
          _setDragging(false);
          widget.onDragEnd?.call(details);
        },
        child: KeyedSubtree(key: _childKey, child: widget.child),
      );
    }

    return MouseRegion(
      cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _mouseOver = true),
      onExit: (_) {
        // Pendant un glisser, on garde le mode souris jusqu'au dépôt.
        if (!_dragging) setState(() => _mouseOver = false);
      },
      child: draggable,
    );
  }
}

/// Retour visuel du glisser : l'élément se soulève (légère mise à l'échelle,
/// filet d'accent) au lieu d'une ombre portée.
class _LiftedFeedback extends StatelessWidget {
  const _LiftedFeedback({required this.child, this.width});

  final Widget child;
  final double? width;

  static const double _lift = 1.03;

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: Colors.transparent,
      child: SizedBox(width: width, child: child),
    );
    if (Motion.reduced(context)) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: _lift),
      duration: Motion.duration(context, CqMotion.fast),
      curve: CqMotion.enter,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: content,
    );
  }
}

/// Sélecteur segmenté sobre (2 à 4 options) : bascule entre des vues d'un
/// même contenu, par exemple Kanban et matrice d'Eisenhower.
class CqSegmentedControl<T> extends StatelessWidget {
  const CqSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  /// Valeur → libellé, dans l'ordre d'affichage.
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    // Garde sa largeur naturelle même dans une colonne étirée.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      child: _segments(context, cq),
    );
  }

  Widget _segments(BuildContext context, CognicColors cq) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: cq.beigeDark, width: Borders.thin),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final MapEntry(key: value, value: label) in options.entries)
            Semantics(
              selected: value == selected,
              button: true,
              child: InkWell(
                onTap: value == selected ? null : () => onChanged(value),
                child: AnimatedContainer(
                  duration: Motion.duration(context, CqMotion.fast),
                  curve: CqMotion.standard,
                  constraints:
                      const BoxConstraints(minHeight: Sizes.touchTarget),
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                  alignment: Alignment.center,
                  // Sélection : aplat pierre (le vert reste aux actions).
                  color: value == selected
                      ? cq.beigeDark
                      : Colors.transparent,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: appFontFamily,
                      fontSize: TypeScale.body,
                      letterSpacing:
                          TypeScale.tracking(TypeScale.body, TypeScale.labelEm),
                      fontWeight: value == selected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: value == selected ? cq.textPrimary : cq.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
