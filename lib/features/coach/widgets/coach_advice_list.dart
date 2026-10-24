import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../domain/tree_coach.dart';
import '../providers/coach_provider.dart';

/// Conseils de l'Arbre-Coach : pastilles sauge, titre, explication et, si
/// utile, un lien vers l'écran qui aide.
class CoachAdviceList extends ConsumerWidget {
  const CoachAdviceList({super.key, this.limit = 3});

  final int limit;

  static IconData iconFor(CoachTopic topic) => switch (topic) {
        CoachTopic.rest => Icons.bedtime_outlined,
        CoachTopic.mood => Icons.psychology_alt_outlined,
        CoachTopic.retention => Icons.replay_outlined,
        CoachTopic.understanding => Icons.lightbulb_outline,
        CoachTopic.habits => Icons.event_repeat_outlined,
        CoachTopic.journal => Icons.edit_note_outlined,
        CoachTopic.cheer => Icons.spa_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cq = context.cq;
    final advice = ref.watch(treeCoachProvider).advice(limit: limit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in advice)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cq.sauge,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(iconFor(item.topic),
                        size: Sizes.iconMd,
                        color: item.topic == CoachTopic.rest ||
                                item.topic == CoachTopic.mood
                            ? cq.terre
                            : cq.vertSauge),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: TypeScale.body,
                              fontWeight: FontWeight.w600,
                              color: cq.textPrimary,
                            ),
                          ),
                          const SizedBox(height: Space.xs),
                          Text(
                            item.body,
                            style: TextStyle(
                              fontSize: TypeScale.caption,
                              color: cq.textMuted,
                              height: TypeScale.bodyHeight,
                            ),
                          ),
                          if (item.route != null && item.actionLabel != null)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  foregroundColor: cq.vertSauge,
                                ),
                                onPressed: () => context.push(item.route!),
                                child: Text(item.actionLabel!),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Phrase de vitalité sous l'arbre.
class CoachHeadline extends ConsumerWidget {
  const CoachHeadline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coach = ref.watch(treeCoachProvider);
    return Text(
      '${coach.headline} Vitalité : ${(coach.vitality * 100).round()} %.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: TypeScale.caption,
        color: context.cq.textMuted,
        fontFeatures: TypeScale.tabular,
      ),
    );
  }
}
