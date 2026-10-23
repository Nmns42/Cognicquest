import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../router/app_router.dart';
import '../../../shared/models/planning_model.dart';
import '../domain/adaptive_schedule.dart';
import '../providers/planning_provider.dart';
import '../../../core/theme/tokens.dart';

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
      appBar: AppBar(title: const Text('Planification & échéances')),
      body: RefreshIndicator(
        color: context.cq.vertDark,
        onRefresh: () => ref.read(planningActionsProvider).sync(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Space.xl, Space.xs, Space.xl, Space.xxxl * 2),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _NextDeadlineCard(upcoming: upcoming),
            const SizedBox(height: Space.xl),

            _ToolTile(
              icon: Icons.view_timeline_outlined,
              title: 'Diagramme de Gantt',
              onTap: () => context.push(AppRoute.gantt),
            ),
            const SizedBox(height: Space.md),
            _ToolTile(
              icon: Icons.trending_up,
              title: 'Ordre de révision',
              subtitle: ranked.isEmpty
                  ? null
                  : '${ranked.length} chapitre${ranked.length > 1 ? 's' : ''} '
                      'classé${ranked.length > 1 ? 's' : ''}',
              onTap: () => context.push(AppRoute.revisionOrder),
            ),
            const SizedBox(height: Space.md),
            _ToolTile(
              icon: Icons.speed_outlined,
              title: 'Vitesse de travail',
              onTap: () => context.push(AppRoute.studySpeed),
            ),
            const SizedBox(height: Space.md),
            _ToolTile(
              icon: Icons.flag_outlined,
              title: 'Objectifs SMART',
              subtitle: goals.isEmpty ? null : '${goals.length} en cours',
              onTap: () => context.push(AppRoute.goals),
            ),

            if (!plan.isEmpty) ...[
              const SizedBox(height: Space.xl),
              _PlanSummaryCard(plan: plan),
            ],

            if (goals.isNotEmpty) ...[
              const SizedBox(height: Space.xl),
              Text('Objectifs en cours',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Space.md),
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
    final cq = context.cq;
    BoxDecoration banner() => BoxDecoration(
          color: cq.parchemin,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: cq.beigeDark),
        );

    if (upcoming.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.lg),
        decoration: banner(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.event_note_outlined,
                size: Sizes.iconMd, color: cq.vertSauge),
            const SizedBox(width: Space.md),
            Expanded(
              child: Text(
                'Aucune échéance planifiée. '
                'Ajoute tes examens et rendus pour voir venir.',
                style: TextStyle(
                    color: cq.textMuted, fontSize: TypeScale.body, height: 1.45),
              ),
            ),
          ],
        ),
      );
    }

    final next = upcoming.first;
    final today = DateTime.now();
    final days = DateTime(next.endDate.year, next.endDate.month, next.endDate.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    // Proche (3 jours ou moins) : le rouge d'alerte ; sinon l'écorce.
    final accent = days <= 3 ? cq.errorColor : cq.terre;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      decoration: banner(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_outlined, size: Sizes.iconMd, color: accent),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prochaine échéance · '
                  '${days == 0 ? "aujourd'hui" : (days == 1 ? 'demain' : 'dans $days jours')}',
                  style: TextStyle(
                    color: accent,
                    fontSize: TypeScale.caption,
                    fontWeight: FontWeight.w600,
                    fontFeatures: TypeScale.tabular,
                  ),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  next.title,
                  style: TextStyle(
                    color: cq.textPrimary,
                    fontSize: TypeScale.bodyLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Space.xs / 2),
                Text(
                  '${next.endDate.day} ${_months[next.endDate.month - 1]}'
                  '${upcoming.length > 1 ? ' · + ${upcoming.length - 1} autre'
                      '${upcoming.length > 2 ? 's' : ''} à venir' : ''}',
                  style: TextStyle(
                    color: cq.textMuted,
                    fontSize: TypeScale.caption,
                    fontFeatures: TypeScale.tabular,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte blanche sobre : filet fin, coins `Radii.card`, sans ombre.
BoxDecoration _plainCard(BuildContext context) => BoxDecoration(
      color: context.cq.cardColor,
      borderRadius: BorderRadius.circular(Radii.card),
      border: Border.all(color: context.cq.beigeDark),
    );

class _PlanSummaryCard extends ConsumerWidget {
  const _PlanSummaryCard({required this.plan});

  final AdaptivePlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feasible = plan.isFeasible;

    return DecoratedBox(
      decoration: _plainCard(context),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  feasible ? Icons.event_available : Icons.warning_amber_rounded,
                  size: Sizes.iconMd,
                  color: feasible ? context.cq.vertSauge : context.cq.warning,
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
                  fontSize: TypeScale.caption, color: context.cq.textMuted, height: 1.4),
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

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.card),
      side: BorderSide(color: context.cq.beigeDark),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Material(
      color: context.cq.cardColor,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoute.goals),
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
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
                          fontSize: TypeScale.body,
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
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: Space.xs,
                    backgroundColor: context.cq.sauge,
                    color: context.cq.vertSauge,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${goal.currentValue.toStringAsFixed(0)} / '
                  '${goal.targetValue.toStringAsFixed(0)} ${goal.metricLabel}'
                  '${pace != null && pace > 0 ? ' · ${pace.toStringAsFixed(1)} / jour pour tenir' : ''}',
                  style: TextStyle(
                    fontSize: TypeScale.caption,
                    color: context.cq.textMuted,
                    fontFeatures: TypeScale.tabular,
                  ),
                ),
              ],
            ],
          ),
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
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;

  /// Donnée utile (un compte), jamais une description : sans donnée, la
  /// tuile n'a qu'un titre.
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.card),
      side: BorderSide(color: cq.beigeDark),
    );
    return Material(
      color: cq.cardColor,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        hoverColor: cq.sauge,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.control),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.lg, vertical: Space.md),
            child: Row(
              children: [
                // Icône linéaire délicate, sans pastille.
                Icon(icon, size: Sizes.iconMd, color: cq.vertSauge),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: TypeScale.body,
                              fontWeight: FontWeight.w600,
                              color: cq.textPrimary)),
                      if (subtitle != null)
                        Text(subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: TypeScale.caption,
                              color: cq.terre,
                              fontFeatures: TypeScale.tabular,
                            )),
                    ],
                  ),
                ),
                const SizedBox(width: Space.sm),
                Icon(Icons.arrow_forward, size: Sizes.iconMd, color: cq.vertSauge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
