import 'package:flutter/material.dart';

import '../../../core/motion/micro_animations.dart';
import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/habit_model.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';

/// Chiffre de tête du Dashboard : le temps de focus du jour.
///
/// Un seul nombre → une figure héro, pas un graphe à une barre. Chiffres
/// proportionnels (pas de `tabularFigures` sur un grand nombre isolé).
class HeroFocusCard extends StatelessWidget {
  const HeroFocusCard({
    super.key,
    required this.value,
    required this.caption,
    required this.trailing,
  });

  final String value;
  final String caption;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: context.cardShape,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: TypeScale.display,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: context.cq.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: TextStyle(
                        fontSize: TypeScale.body, color: context.cq.textMuted),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Tuile de statistique. Une rangée de tuiles remplace avantageusement un
/// graphe groupé pour quelques nombres de tête.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.warm = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Pastille écorce (chaleureuse) plutôt que sauge.
  final bool warm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Tuile légère (sauge) : pas une carte surélevée.
    return CqCard(
      tone: CqCardTone.soft,
      radius: Radii.card,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CqScoreBadge(icon: icon, warm: warm),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: TypeScale.title,
                    color: context.cq.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                    color: context.cq.textMuted, fontSize: TypeScale.caption),
              ),
            ],
          ),
        ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.onMore,
    this.trailingLabel = 'Voir tout',
  });

  final String title;
  final VoidCallback onMore;
  final String trailingLabel;

  @override
  Widget build(BuildContext context) {
    // Pas de titre affiché sur l'accueil (épure) : le contenu parle de
    // lui-même. Une flèche discrète ouvre la section ; son nom reste
    // annoncé par l'infobulle et les lecteurs d'écran.
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: IconButton(
        tooltip: '$trailingLabel : $title',
        visualDensity: VisualDensity.compact,
        onPressed: onMore,
        icon: Icon(Icons.arrow_outward,
            size: Sizes.iconMd, color: context.cq.textMuted),
      ),
    );
  }
}

/// Aperçu compact d'une habitude.
class HabitPreviewRow extends StatelessWidget {
  const HabitPreviewRow({
    super.key,
    required this.habit,
    required this.onToggle,
  });

  final Habit habit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final done = habit.completedToday;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: context.cq.sauge,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card)),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Micro-animation n° 1, comme sur la page Habitudes.
              PulseOnChange(
                trigger: done,
                enabled: done,
                scale: 1.2,
                child: AnimatedContainer(
                  duration: Motion.duration(
                      context, const Duration(milliseconds: 200)),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: done ? context.cq.vertSauge : Colors.transparent,
                    border: Border.all(
                      color: done ? context.cq.vertSauge : context.cq.beigeDark,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: done
                      ? Icon(Icons.check, size: 13, color: context.cq.beige)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: TypeScale.body,
                    color: context.cq.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: context.cq.textMuted,
                  ),
                ),
              ),
              RollingNumber(
                value: habit.streak,
                builder: (context, streak) => streak == 0
                    ? const SizedBox.shrink()
                    : CqScoreBadge(
                        value: '$streak',
                        semanticLabel: 'Série : $streak',
                        warm: !done,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptySection extends StatelessWidget {
  const EmptySection({
    super.key,
    required this.icon,
    required this.message,
    this.onAction,
    this.actionLabel,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cq.sauge,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.cq.textHint, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: context.cq.textMuted, fontSize: TypeScale.body),
            ),
          ),
          if (onAction != null && actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
