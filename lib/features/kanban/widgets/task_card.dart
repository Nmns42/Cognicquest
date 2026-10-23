import 'package:flutter/material.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/task_model.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/cq_interactions.dart';

/// Puce de priorité : écorce (haute), sauge (moyenne), gris (basse).
Color priorityColor(BuildContext context, TaskPriority priority) =>
    switch (priority) {
      TaskPriority.high => context.cq.terre,
      TaskPriority.medium => context.cq.vertSauge,
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
    this.gripVisible = false,
    this.onDelete,
    this.trailing,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final bool isDragging;

  /// Poignée de déplacement : masquée par défaut (vue zen), visible au
  /// survol de la souris et pendant un glisser. Sa place est toujours
  /// réservée, pour que rien ne bouge quand elle apparaît.
  final bool gripVisible;

  /// Suppression en un clic (corbeille discrète). `null` : pas de corbeille
  /// (carte en cours de glisser, aperçu).
  final VoidCallback? onDelete;

  /// Commande affichée à droite de la carte (menu « Déplacer vers… »).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;

    final radius = BorderRadius.circular(Radii.card);
    return Opacity(
      opacity: isDragging ? 0.4 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        // Carte blanche, filet fin, ombre ultra-légère ; une tâche en cours
        // est cerclée de sauge.
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [context.chrome.shadow],
          ),
          child: Card(
        margin: EdgeInsets.zero,
        color: context.cq.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
              color: task.isDoing ? context.cq.vertSauge : context.cq.beigeDark),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: HoverReveal(
                    visible: gripVisible,
                    child: Icon(Icons.drag_indicator,
                        size: Sizes.iconMd, color: context.cq.textMuted),
                  ),
                ),
                const SizedBox(width: Space.xs),
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
                          fontWeight: FontWeight.w600,
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
                              _Badge(
                                  label: 'Urgent',
                                  color: context.cq.terre,
                                  filled: true),
                            if (task.isImportant)
                              _Badge(
                                  label: 'Important',
                                  color: context.cq.vertSauge),
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
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Supprimer la tâche',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline,
                        size: Sizes.iconSm, color: context.cq.textMuted),
                  ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
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
        : (task.isDueToday ? context.cq.terre : context.cq.textMuted);
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
        borderRadius: BorderRadius.circular(Radii.xs),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: Motion.duration(context, const Duration(milliseconds: 180)),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: done ? context.cq.vertSauge : context.cq.cardColor,
              border: Border.all(
                color: done ? context.cq.vertSauge : context.cq.textHint,
                width: Borders.thin,
              ),
              borderRadius: BorderRadius.circular(Radii.xs),
            ),
            child: done
                ? Icon(Icons.check, size: 13, color: context.cq.beige)
                : null,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color color;
  final IconData? icon;

  /// Aplat plein (texte couleur du fond, ≥ 4,5:1) plutôt que teinté.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ink = filled ? context.cq.beige : color;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.sm, vertical: Space.xs / 2),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: ink),
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
                color: ink,
                fontWeight: FontWeight.w600,
                fontFeatures: TypeScale.tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
