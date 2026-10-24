import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/planning_model.dart';
import '../domain/goal_feasibility.dart';
import '../providers/planning_provider.dart';
import '../widgets/smart_goal_sheet.dart';
import '../../../core/theme/tokens.dart';

/// Objectifs SMART — « définir des objectifs précis, atteignables et
/// mesurables » (CdC).
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(studyGoalsProvider).valueOrNull ?? const <StudyGoal>[];
    final active = ref.watch(activeGoalsProvider);
    final done = goals.where((g) => g.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Objectifs SMART')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          if (goals.isEmpty)
            const _EmptyState()
          else ...[
            if (active.isNotEmpty) ...[
              for (final goal in active) _GoalCard(goal: goal),
            ],
            if (done.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('Atteints (${done.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              for (final goal in done) _GoalCard(goal: goal),
            ],
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final draft = await SmartGoalSheet.show(context);
          if (draft == null) return;
          await ref.read(planningActionsProvider).saveGoal(draft);
        },
        backgroundColor: context.cq.vert,
        tooltip: 'Nouvel objectif',
        child: Icon(Icons.add, color: context.onAccent),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final StudyGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pace = goal.requiredPacePerDay;
    final days = goal.daysRemaining;
    // Temps quotidien d'après la vitesse de travail mesurée, si l'unité de
    // l'objectif en a une.
    final feasibility =
        GoalFeasibility.of(goal, ref.watch(allSpeedEstimatesProvider));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          final draft = await SmartGoalSheet.show(context, goal: goal);
          if (draft == null) return;
          await ref.read(planningActionsProvider).saveGoal(draft);
        },
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: TypeScale.bodyLarge,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: goal.isCompleted
                            ? context.cq.textMuted
                            : context.cq.textPrimary,
                        decoration:
                            goal.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: context.cq.textMuted,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: goal.isCompleted
                        ? 'Rouvrir l\'objectif'
                        : 'Marquer comme atteint',
                    icon: Icon(
                      goal.isCompleted
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      size: 21,
                      color: goal.isCompleted
                          ? context.cq.vertSauge
                          : context.cq.textHint,
                    ),
                    onPressed: () => ref
                        .read(planningActionsProvider)
                        .toggleGoalCompleted(goal),
                  ),
                ],
              ),

              if (goal.targetValue > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 7,
                    backgroundColor: context.cq.beigeDark,
                    color: goal.isCompleted
                        ? context.cq.textMuted
                        : context.cq.vertDark,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${goal.currentValue.toStringAsFixed(0)} / '
                  '${goal.targetValue.toStringAsFixed(0)} ${goal.metricLabel}',
                  style:  TextStyle(
                      fontSize: TypeScale.caption, color: context.cq.textMuted),
                ),
              ],

              if (!goal.isCompleted && days != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      goal.isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.schedule,
                      size: 14,
                      color: goal.isOverdue
                          ? context.cq.errorColor
                          : context.cq.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        goal.isOverdue
                            ? 'Échéance dépassée de ${-days} j'
                            : (days == 0
                                ? 'Échéance aujourd\'hui'
                                : '$days jour${days > 1 ? 's' : ''} restant'
                                    '${days > 1 ? 's' : ''}'
                                    '${pace != null && pace > 0 ? ' · ${formatDecimal(pace, maxDigits: 1)} ${goal.metricLabel}/jour' : ''}'
                                    '${feasibility?.perDay == null ? '' : ' · ≈ ${formatHoursMinutes(feasibility!.perDay!)} / jour'}'),
                        style: TextStyle(
                          fontSize: TypeScale.caption,
                          color: goal.isOverdue
                              ? context.cq.errorColor
                              : context.cq.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (!goal.isFullySmart && !goal.isCompleted) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final criterion in goal.missingCriteria)
                      Tooltip(
                        message: criterion.hint,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.cq.warning
                                .withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                          child: Text(
                            criterion.label,
                            style: TextStyle(
                                fontSize: TypeScale.caption, color: context.cq.warning),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
           Icon(Icons.flag_outlined, size: 48, color: context.cq.textHint),
          const SizedBox(height: 16),
          Text('Aucun objectif',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
           Text(
            '« Travailler les maths » n\'est pas un objectif. '
            '« Faire 20 exercices de dérivées avant le 12 mai » en est un.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.cq.textMuted, fontSize: TypeScale.body, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Saisie d'un objectif, guidée par les cinq critères.
