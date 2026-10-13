import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Rang d'un bouton. Règle « zen » : **un seul [primary] par écran**, les
/// autres actions en [secondary] ou [text].
enum CqButtonVariant { primary, secondary, text }

/// Bouton de l'application, toujours d'au moins 48 dp de haut.
///
/// [isLoading] remplace l'icône par un indicateur et désactive le bouton :
/// pas de double envoi, et l'état reste lisible sans changer la largeur.
class CqButton extends StatelessWidget {
  const CqButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = CqButtonVariant.primary;

  const CqButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = CqButtonVariant.secondary;

  const CqButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = CqButtonVariant.text;

  final String label;

  /// `null` : bouton désactivé.
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  /// Pleine largeur (boutons principaux d'un formulaire, d'une feuille).
  final bool expand;
  final CqButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final action = isLoading ? null : onPressed;
    final leading = isLoading
        ? SizedBox.square(
            dimension: Sizes.iconSm,
            child: CircularProgressIndicator(
              strokeWidth: Sizes.spinnerStroke,
              color: variant == CqButtonVariant.primary
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
            ),
          )
        : (icon == null ? null : Icon(icon, size: Sizes.iconMd));

    final text = Text(label);
    final minimum = variant == CqButtonVariant.text
        ? const Size(Sizes.touchTarget, Sizes.touchTarget)
        : const Size(Sizes.touchTarget, Sizes.control);
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
          expand ? Size(double.infinity, minimum.height) : minimum),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: Space.lg)),
    );

    final button = switch (variant) {
      CqButtonVariant.primary => leading == null
          ? FilledButton(onPressed: action, style: style, child: text)
          : FilledButton.icon(
              onPressed: action, style: style, icon: leading, label: text),
      CqButtonVariant.secondary => leading == null
          ? OutlinedButton(onPressed: action, style: style, child: text)
          : OutlinedButton.icon(
              onPressed: action, style: style, icon: leading, label: text),
      CqButtonVariant.text => leading == null
          ? TextButton(onPressed: action, style: style, child: text)
          : TextButton.icon(
              onPressed: action, style: style, icon: leading, label: text),
    };

    return Semantics(
      // Annonce l'attente aux lecteurs d'écran, pas seulement à l'œil.
      value: isLoading ? 'En cours' : null,
      child: button,
    );
  }
}
