import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'cq_button.dart';

/// État vide : une phrase, et au plus une action pour en sortir.
///
/// Pas d'illustration : une icône discrète suffit à signaler le vide sans
/// attirer l'œil plus que le contenu à venir.
class CqEmptyState extends StatelessWidget {
  const CqEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ExcludeSemantics(
              child:
                  Icon(icon, size: Sizes.iconXl, color: context.cq.textMuted),
            ),
            const SizedBox(height: Space.md),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.cq.textMuted),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Space.lg),
            CqButton.secondary(
              label: actionLabel!,
              onPressed: onAction,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}
