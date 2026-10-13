import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Ligne de liste : titre, sous-titre facultatif, icône et élément de fin.
///
/// Cliquable sur toute sa hauteur (48 dp minimum). L'icône de tête est
/// décorative quand le titre dit déjà tout : elle est cachée aux lecteurs
/// d'écran.
class CqListRow extends StatelessWidget {
  const CqListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final text = Theme.of(context).textTheme;
    // Sur la teinte de sélection, le texte reste en couleur de texte : le
    // vert le signale par la teinte et l'icône (contraste ≥ 4,5:1).
    final titleColor = cq.textPrimary;

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.lg, vertical: Space.md),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              ExcludeSemantics(
                child: Icon(leadingIcon,
                    size: Sizes.iconLg,
                    color: selected ? cq.vertDark : cq.textMuted),
              ),
              const SizedBox(width: Space.lg),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: text.bodyLarge?.copyWith(
                      color: titleColor,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: Space.xs),
                    Text(subtitle!, style: text.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: Space.md),
              trailing!,
            ],
          ],
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Material(
        color: selected
            ? cq.vert.withValues(alpha: Tints.selected)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? row : InkWell(onTap: onTap, child: row),
      ),
    );
  }
}
