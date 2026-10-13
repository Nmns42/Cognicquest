import 'package:flutter/material.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/task_model.dart';
import '../../../core/theme/tokens.dart';

Color priorityColor(BuildContext context, TaskPriority priority) =>
    switch (priority) {
      TaskPriority.high => context.cq.errorColor,
      TaskPriority.medium => context.cq.vert,
      TaskPriority.low => context.cq.textHint,
    };

/// Carte de tâche du Kanban et de la matrice d'Eisenhower.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleDone,
    this.isDragging = false,
    this.trailing,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final bool isDragging;

  /// Commande affichée à droite de la carte (menu « Déplacer vers… »).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;

    return Opacity(
      opacity: isDragging ? 0.4 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Checkbox(done: done, onTap: onToggleDone),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: TypeScale.body,
                          height: 1.3,
                          color: done ? context.cq.textMuted : context.cq.textPrimary,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: context.cq.textMuted,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:  TextStyle(
                            fontSize: TypeScale.caption,
                            color: context.cq.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (_hasBadges) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (task.dueDate != null) _dueBadge(context),
                            if (task.isUrgent)
                               _Badge(label: 'Urgent', color: context.cq.errorColor),
                            if (task.isImportant)
                               _Badge(label: 'Important', color: context.cq.vert),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: priorityColor(context, task.priority),
                    shape: BoxShape.circle,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasBadges =>
      task.dueDate != null || task.isUrgent || task.isImportant;

  Widget _dueBadge(BuildContext context) {
    final color = task.isOverdue
        ? context.cq.errorColor
        : (task.isDueToday ? context.cq.vert : context.cq.textMuted);
    final label = task.isDueToday
        ? "Aujourd'hui"
        : '${task.dueDate!.day.toString().padLeft(2, '0')}/'
            '${task.dueDate!.month.toString().padLeft(2, '0')}';

    return _Badge(
      label: label,
      color: color,
      icon: task.isOverdue ? Icons.warning_amber_rounded : Icons.event_outlined,
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: done,
      label: 'Marquer comme terminée',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: Motion.duration(context, const Duration(milliseconds: 180)),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: done ? context.cq.vert : Colors.transparent,
              border: Border.all(
                color: done ? context.cq.vert : context.cq.beigeDark,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: done
                ? Icon(Icons.check, size: 13, color: context.onAccent)
                : null,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          // En très grand texte sur petit écran, le badge est plus large que
          // la carte : il s'abrège au lieu de déborder.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: TypeScale.caption,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
