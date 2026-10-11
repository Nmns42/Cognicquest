import 'package:flutter/material.dart';

import '../../../core/motion/micro_animations.dart';
import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/habit_model.dart';
import '../../../shared/models/task_model.dart';
import '../../kanban/widgets/task_card.dart';

/// Bandeau d'accueil.
class GreetingCard extends StatelessWidget {
  const GreetingCard({
    super.key,
    required this.greeting,
    required this.name,
    required this.dateLabel,
  });

  final String greeting;
  final String name;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: context.cq.vert,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? '$greeting !' : '$greeting, $name !',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            // Le gris `textMuted` sur fond vert échouait au contraste WCAG :
            // on utilise le ton clair dédié.
            style:  TextStyle(color: context.cq.onVertMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

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
                    style:  TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: context.cq.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style:  TextStyle(
                        fontSize: 13, color: context.cq.textMuted),
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
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style:  TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: context.cq.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style:
                     TextStyle(color: context.cq.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickStartCard extends StatelessWidget {
  const QuickStartCard({super.key, required this.onTap, required this.subtitle});

  final VoidCallback onTap;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: context.cq.vert.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: context.cq.vert.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration:  BoxDecoration(
                color: context.cq.vert,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Démarrer une session',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: context.cq.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:  TextStyle(
                        color: context.cq.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
             Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: context.cq.textMuted),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        TextButton(onPressed: onMore, child: Text(trailingLabel)),
      ],
    );
  }
}

/// Aperçu compact d'une tâche.
class TaskPreviewRow extends StatelessWidget {
  const TaskPreviewRow({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onOpen,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: context.cq.beigeDark, width: 2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:  TextStyle(
                      fontSize: 14, color: context.cq.textPrimary),
                ),
              ),
              if (task.isOverdue)
                 Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.warning_amber_rounded,
                      size: 15, color: context.cq.errorColor),
                ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: priorityColor(context, task.priority),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
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
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppTheme.radius),
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
                duration: Motion.duration(context, const Duration(milliseconds: 200)),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: done ? context.cq.vert : Colors.transparent,
                  border: Border.all(
                    color: done ? context.cq.vert : context.cq.beigeDark,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: done
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
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
                    fontSize: 14,
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
                    : Text(
                        '🔥 $streak',
                        style: TextStyle(
                            fontSize: 12, color: context.cq.errorColor),
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
        color: context.cq.beigeDark.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.cq.textHint, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style:
                   TextStyle(color: context.cq.textMuted, fontSize: 14),
            ),
          ),
          if (onAction != null && actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
