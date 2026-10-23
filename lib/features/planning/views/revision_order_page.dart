import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/planning_model.dart';
import '../domain/revision_priority.dart';
import '../providers/planning_provider.dart';
import '../widgets/exam_target_sheet.dart';
import '../../../core/theme/tokens.dart';

/// Ordre de révision par rentabilité — « viser là où il y a le plus de points
/// en examen […] ⇒ ordre de révision » (CdC).
class RevisionOrderPage extends ConsumerWidget {
  const RevisionOrderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranked = ref.watch(rankedTargetsProvider);
    final excluded = ref.watch(excludedTargetsProvider);
    final capacity = ref.watch(dailyCapacityProvider);
    final plan = ref.watch(adaptivePlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ordre de révision')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          if (ranked.isEmpty && excluded.isEmpty)
            const _EmptyState()
          else ...[
             Text(
              'Chaque chapitre est classé par points récupérables à l\'heure, '
              'ajustés selon la proximité de l\'examen.',
              style: TextStyle(
                  fontSize: TypeScale.caption, color: context.cq.textMuted, height: 1.45),
            ),
            const SizedBox(height: 18),

            _CapacitySlider(
              value: capacity,
              onChanged: (value) =>
                  ref.read(dailyCapacityProvider.notifier).state = value,
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: plan.isFeasible
                    ? context.cq.vertSauge.withValues(alpha: 0.08)
                    : context.cq.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Text(
                plan.summary,
                style: TextStyle(
                  fontSize: TypeScale.caption,
                  height: 1.4,
                  color: plan.isFeasible
                      ? context.cq.vertDark
                      : context.cq.warning,
                ),
              ),
            ),
            const SizedBox(height: 22),

            if (ranked.isNotEmpty) ...[
              Text(
                'Dans cet ordre',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Les 3 premiers : ~'
                '${RevisionPriority.effortFor(ranked).toStringAsFixed(1)} h',
                style:  TextStyle(
                    fontSize: TypeScale.caption, color: context.cq.textMuted),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < ranked.length; i++)
                _RankedRow(rank: i + 1, entry: ranked[i]),
            ],

            if (excluded.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                'Écartés du classement',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
               Text(
                // Les montrer évite de croire à un oubli.
                'Ils restent dans ta liste, mais ne rapporteraient rien.',
                style: TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted),
              ),
              const SizedBox(height: 10),
              for (final entry in excluded)
                _ExcludedRow(target: entry.$1, reason: entry.$2),
            ],
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final draft = await ExamTargetSheet.show(context);
          if (draft == null) return;
          await ref.read(planningActionsProvider).saveExamTarget(draft);
        },
        backgroundColor: context.cq.vert,
        tooltip: 'Ajouter un chapitre',
        child: Icon(Icons.add, color: context.onAccent),
      ),
    );
  }
}

class _CapacitySlider extends StatelessWidget {
  const _CapacitySlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             Text('Temps d\'étude par jour',
                style: TextStyle(
                    fontSize: TypeScale.body,
                    fontWeight: FontWeight.w600,
                    color: context.cq.textPrimary)),
            const Spacer(),
            Text('${value.toStringAsFixed(1)} h',
                style:  TextStyle(
                    fontSize: TypeScale.body,
                    fontWeight: FontWeight.w700,
                    color: context.cq.vertDark)),
          ],
        ),
        Slider(
          value: value,
          min: 0.5,
          max: 8,
          divisions: 15,
          activeColor: context.cq.vertDark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RankedRow extends ConsumerWidget {
  const _RankedRow({required this.rank, required this.entry});

  final int rank;
  final RankedTarget entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = entry.target;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          final draft = await ExamTargetSheet.show(context, target: target);
          if (draft == null) return;
          await ref.read(planningActionsProvider).saveExamTarget(draft);
        },
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? context.cq.vertSauge
                      : context.cq.beigeDark.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: TypeScale.caption,
                    fontWeight: FontWeight.w700,
                    color: rank <= 3 ? context.cq.beige : context.cq.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:  TextStyle(
                          fontSize: TypeScale.body,
                          fontWeight: FontWeight.w600,
                          color: context.cq.textPrimary,
                          height: 1.3),
                    ),
                    const SizedBox(height: 3),
                    // On explique le classement plutôt que de l'imposer.
                    Text(
                      entry.rationale,
                      style:  TextStyle(
                          fontSize: TypeScale.caption, color: context.cq.textMuted),
                    ),
                    if (target.subject != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        target.subject!,
                        style:  TextStyle(
                            fontSize: TypeScale.caption, color: context.cq.textHint),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.score.toStringAsFixed(1),
                    style:  TextStyle(
                        fontSize: TypeScale.bodyLarge,
                        fontWeight: FontWeight.w700,
                        color: context.cq.vertDark),
                  ),
                   Text('pts pondérés/h',
                      style: TextStyle(
                          fontSize: TypeScale.caption, color: context.cq.textHint)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcludedRow extends StatelessWidget {
  const _ExcludedRow({required this.target, required this.reason});

  final ExamTarget target;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
           Icon(Icons.remove_circle_outline,
              size: 14, color: context.cq.textHint),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              target.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:  TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted),
            ),
          ),
          Text(reason,
              style:  TextStyle(fontSize: TypeScale.caption, color: context.cq.textHint)),
        ],
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
           Icon(Icons.trending_up, size: 48, color: context.cq.textHint),
          const SizedBox(height: 16),
          Text('Aucun chapitre déclaré',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
           Text(
            'Déclare tes chapitres avec leur coefficient à l\'examen, ta note '
            'actuelle et la note que tu penses pouvoir atteindre. '
            'CognicQuest te dira par quoi commencer.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.cq.textMuted, fontSize: TypeScale.body, height: 1.45),
          ),
        ],
      ),
    );
  }
}
