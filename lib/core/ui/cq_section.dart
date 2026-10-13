import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'cq_button.dart';

/// Bloc titré d'un écran : un titre, une action facultative, un contenu.
///
/// Remplace les en-têtes refaits écran par écran (taille, graisse et marge
/// différentes à chaque fois).
class CqSection extends StatelessWidget {
  const CqSection({
    super.key,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child:
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            if (actionLabel != null && onAction != null)
              CqButton.text(label: actionLabel!, onPressed: onAction),
          ],
        ),
        const SizedBox(height: Space.sm),
        child,
      ],
    );
  }
}
