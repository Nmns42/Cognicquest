import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/reduce_motion.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Rôle d'un bouton tactile : couleur de sa face, de sa lèvre et du texte.
enum CqPressableTone { primary, secondary, amber }

/// Bouton « 3D » à la Duolingo : une face posée sur une lèvre plus sombre,
/// qui s'enfonce sous le doigt.
///
/// Au repos, la lèvre dépasse de [Press.depth] sous la face (ombre pleine,
/// sans flou). À l'appui, la face descend d'autant et la recouvre. L'action
/// part au relâcher, comme sur un vrai bouton ; un glissé hors du bouton
/// l'annule. La hauteur totale ne change pas : rien ne saute autour.
/// Animations réduites : l'enfoncement reste (il confirme l'appui), mais
/// instantané.
class CqPressableButton extends StatefulWidget {
  const CqPressableButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = CqPressableTone.primary,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;

  /// `null` : bouton désactivé (plat, sans lèvre).
  final VoidCallback? onPressed;
  final IconData? icon;
  final CqPressableTone tone;

  /// Remplace l'icône par un indicateur et désactive le bouton : pas de
  /// double envoi, et la largeur ne change pas.
  final bool isLoading;

  /// Pleine largeur (bouton principal d'un écran, d'une feuille).
  final bool expand;

  @override
  State<CqPressableButton> createState() => _CqPressableButtonState();
}

class _CqPressableButtonState extends State<CqPressableButton> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _activate() {
    HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final (face, lip, ink) = switch (widget.tone) {
      _ when !_enabled => (cq.beigeDark, cq.beigeDark, cq.textMuted),
      CqPressableTone.primary => (cq.vert, cq.vertLip, context.onAccent),
      CqPressableTone.secondary => (cq.cardColor, cq.beigeDark, cq.vertDark),
      CqPressableTone.amber => (cq.ambre, cq.ambreLip, cq.onAmbre),
    };
    final down = _pressed && _enabled ? Press.depth : 0.0;
    final radius = BorderRadius.circular(Radii.button);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLoading)
          SizedBox.square(
            dimension: Sizes.iconSm,
            child: CircularProgressIndicator(
                strokeWidth: Sizes.spinnerStroke, color: ink),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: Sizes.iconMd, color: ink),
        if (widget.isLoading || widget.icon != null)
          const SizedBox(width: Space.sm),
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appFontFamily,
              fontSize: TypeScale.bodyLarge,
              fontWeight: FontWeight.w700,
              letterSpacing:
                  TypeScale.tracking(TypeScale.bodyLarge, TypeScale.labelEm),
              color: ink,
            ),
          ),
        ),
      ],
    );

    final button = AnimatedContainer(
      duration: Motion.duration(context, CqMotion.press),
      curve: CqMotion.standard,
      // La face descend, la lèvre se réduit d'autant : hauteur constante.
      margin: EdgeInsets.only(top: down, bottom: Press.depth - down),
      constraints: const BoxConstraints(minHeight: Sizes.control),
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: face,
        borderRadius: radius,
        border: widget.tone == CqPressableTone.secondary
            ? Border.all(color: lip, width: Borders.focus)
            : null,
        boxShadow: [
          if (_enabled)
            BoxShadow(color: lip, offset: Offset(0, Press.depth - down)),
        ],
      ),
      // Focus clavier visible sans dépendre de la couleur seule.
      foregroundDecoration: _focused
          ? BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: cq.textPrimary, width: Borders.focus),
            )
          : null,
      child: content,
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      // Annonce l'attente aux lecteurs d'écran, pas seulement à l'œil.
      value: widget.isLoading ? 'En cours' : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) => _activate()),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: () => _setPressed(false),
          onTap: _enabled ? _activate : null,
          child: SizedBox(
            width: widget.expand ? double.infinity : null,
            child: button,
          ),
        ),
      ),
    );
  }
}
