import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'cq_pressable_button.dart';

/// Rang d'un bouton. Règle « zen » : **un seul [primary] par écran**, les
/// autres actions en [secondary] ou [text].
enum CqButtonVariant { primary, secondary, text }

/// Bouton de l'application, toujours d'au moins 48 dp de haut.
///
/// [CqButton.primary] et [CqButton.secondary] sont des boutons tactiles en
/// relief ([CqPressableButton]) ; [CqButton.text] reste un bouton plat.
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
    // Principal et secondaire : boutons tactiles en relief.
    if (variant != CqButtonVariant.text) {
      return CqPressableButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
        expand: expand,
        tone: variant == CqButtonVariant.primary
            ? CqPressableTone.primary
            : CqPressableTone.secondary,
      );
    }

    final action = isLoading ? null : onPressed;
    final leading = isLoading
        ? SizedBox.square(
            dimension: Sizes.iconSm,
            child: CircularProgressIndicator(
              strokeWidth: Sizes.spinnerStroke,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        : (icon == null ? null : Icon(icon, size: Sizes.iconMd));

    final text = Text(label);
    const minimum = Size(Sizes.touchTarget, Sizes.touchTarget);
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
          expand ? Size(double.infinity, minimum.height) : minimum),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: Space.lg)),
    );

    final button = leading == null
        ? TextButton(onPressed: action, style: style, child: text)
        : TextButton.icon(
            onPressed: action, style: style, icon: leading, label: text);

    return Semantics(
      // Annonce l'attente aux lecteurs d'écran, pas seulement à l'œil.
      value: isLoading ? 'En cours' : null,
      child: button,
    );
  }
}
