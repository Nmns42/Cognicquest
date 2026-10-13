import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Champ de saisie avec un libellé **visible au-dessus** du champ.
///
/// Un texte indicatif seul disparaît dès qu'on tape : on ne sait plus ce
/// qu'on remplit (UI UX Pro Max : « placeholder-only label »). L'erreur
/// s'affiche sous le champ, à l'endroit du problème.
class CqTextField extends StatelessWidget {
  const CqTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;

  /// Message d'erreur ; `null` quand le champ est valide.
  final String? error;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autofocus;
  final bool enabled;
  final int? maxLines;

  /// Laisse les gestionnaires de mots de passe remplir le champ.
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Le libellé visuel n'est pas relu : le champ porte le même libellé
        // pour les lecteurs d'écran, qui l'annoncent avec la saisie.
        ExcludeSemantics(
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(height: Space.sm),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            autofocus: autofocus,
            enabled: enabled,
            maxLines: obscureText ? 1 : maxLines,
            autofillHints: autofillHints,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              errorText: error,
            ),
          ),
        ),
      ],
    );
  }
}
