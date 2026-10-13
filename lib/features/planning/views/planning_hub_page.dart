import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../router/app_router.dart';
import '../../../shared/models/planning_model.dart';
import '../domain/adaptive_schedule.dart';
import '../providers/planning_provider.dart';

/// Accueil de la planification : objectifs, échéances, accès aux outils.
class PlanningHubPage extends ConsumerStatefulWidget {
  const PlanningHubPage({super.key});

  @override
  ConsumerState<PlanningHubPage> createState() => _PlanningHubPageState();
}

class _PlanningHubPageState extends ConsumerState<PlanningHubPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planningActionsProvider).sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(activeGoalsProvider);
    final upcoming = ref.watch(upcomingPlanItemsProvider);
    final ranked = ref.watch(rankedTargetsProvider);
    final plan = ref.watch(adaptivePlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Planification')),
      body: RefreshIndicator(
        color: context.cq.vert,
        onRefresh: () => ref.read(planningActionsProvider).sync(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _NextDeadlineCard(upcoming: upcoming),
            const SizedBox(height: 20),

            const _SectionLabel('Outils'),
            const SizedBox(height: 10),
            _ToolTile(
              icon: Icons.view_timeline_outlined,
              title: 'Diagramme de Gantt',
              subtitle: 'Voir le plan dans le temps, gérer les dépendances',
              onTap: () => context.push(AppRoute.gantt),
            ),
            const SizedBox(height: 8),
            _ToolTile(
              icon: Icons.trending_up,
              title: 'Ordre de révision',
              subtitle: ranked.isEmpty
                  ? 'Classer les chapitres par rentabilité'
                  : '${ranked.length} chapitre${ranked.length > 1 ? 's' : ''} '
                      'classé${ranked.length > 1 ? 's' : ''}',
              onTap: () => context.push(AppRoute.revisionOrder),
            ),
            const SizedBox(height: 8),
            _ToolTile(
              icon: Icons.speed_outlined,
              title: 'Ma vitesse de travail',
              subtitle: 'Mesurer pour estimer le temps qu\'il te faut',
              onTap: () => context.push(AppRoute.studySpeed),
            ),
            const SizedBox(height: 8),
            _ToolTile(
              icon: Icons.flag_outlined,
              title: 'Objectifs SMART',
              subtitle: goals.isEmpty
                  ? 'Formuler un objectif précis et mesurable'
                  : '${goals.length} en cours',
              onTap: () => context.push(AppRoute.goals),
            ),

            if (!plan.isEmpty) ...[
              const SizedBox(height: 22),
              _PlanSummaryCard(plan: plan),
            ],

            if (goals.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionLabel('Objectifs en cours'),
              const SizedBox(height: 10),
              for (final goal in goals.take(4)) _GoalRow(goal: goal),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextDeadlineCard extends StatelessWidget {
  const _NextDeadlineCard({required this.upcoming});

  final List<PlanItem> upcoming;

  static const List<String> _months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  @override
  Widget build(BuildContext context) {
    if (upcoming.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.cq.beigeDark.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child:  Text(
          'Aucune échéance planifiée.\n'
          'Ajoute tes examens et rendus pour voir venir.',
          style: TextStyle(
              color: context.cq.textMuted, fontSize: 13, height: 1.45),
        ),
      );
    }

    final next = upcoming.first;
    final today = DateTime.now();
    final days = DateTime(next.endDate.year, next.endDate.month, next.endDate.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: days <= 3 ? context.cq.errorColor : context.cq.vert,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            days == 0
                ? "Aujourd'hui"
                : (days == 1 ? 'Demain' : 'Dans $days jours'),
            style: TextStyle(
              color: context.onAccent,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            next.title,
            style: TextStyle(
                color: context.onAccent, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            '${next.endDate.day} ${_months[next.endDate.month - 1]}',
            style:  TextStyle(color: context.cq.onVertMuted, fontSize: 12),
          ),
          if (upcoming.length > 1) ...[
            const SizedBox(height: 12),
            Text(
              '+ ${upcoming.length - 1} autre'
              '${upcoming.length > 2 ? 's' : ''} échéance'
              '${upcoming.length > 2 ? 's' : ''} à venir',
              style:  TextStyle(color: context.cq.onVertMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanSummaryCard extends ConsumerWidget {
  const _PlanSummaryCard({required this.plan});

  final AdaptivePlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feasible = plan.isFeasible;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  feasible ? Icons.event_available : Icons.warning_amber_rounded,
                  size: 18,
                  color: feasible ? context.cq.vertDark : context.cq.warning,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text('Plan de révision proposé',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              plan.summary,
              style:  TextStyle(
                  fontSize: 12.5, color: context.cq.textMuted, height: 1.4),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                final count =
                    await ref.read(planningActionsProvider).materialisePlan();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  snackBarAnimationStyle: Motion.style(context),
                  SnackBar(
                    content: Text(count == 0
                        ? 'Rien à placer dans le planning.'
                        : '$count étape${count > 1 ? 's' : ''} ajoutée'
                            '${count > 1 ? 's' : ''} au Gantt.'),
                  ),
                );
              },
              icon: const Icon(Icons.add_chart, size: 18),
              label: const Text('Reporter dans le Gantt'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends ConsumerWidget {
  const _GoalRow({required this.goal});

  final StudyGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pace = goal.requiredPacePerDay;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push(AppRoute.goals),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:  TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.cq.textPrimary,
                          height: 1.3),
                    ),
                  ),
                  if (goal.isOverdue)
                     Icon(Icons.warning_amber_rounded,
                        size: 16, color: context.cq.errorColor)
                  else if (!goal.isFullySmart)
                    Tooltip(
                      message:
                          '${goal.missingCriteria.length} critère(s) SMART manquant(s)',
                      child: Icon(Icons.info_outline,
                          size: 15, color: context.cq.warning),
                    ),
                ],
              ),
              if (goal.targetValue > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 6,
                    backgroundColor: context.cq.beigeDark,
                    color: context.cq.vertDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${goal.currentValue.toStringAsFixed(0)} / '
                  '${goal.targetValue.toStringAsFixed(0)} ${goal.metricLabel}'
                  '${pace != null && pace > 0 ? ' · ${pace.toStringAsFixed(1)} / jour pour tenir' : ''}',
                  style:  TextStyle(
                      fontSize: 11.5, color: context.cq.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.cq.vert.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: context.cq.vertDark),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:  TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.cq.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:  TextStyle(
                            fontSize: 12, color: context.cq.textMuted)),
                  ],
                ),
              ),
               Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: context.cq.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style:  TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.cq.textPrimary,
        ),
      );
}
