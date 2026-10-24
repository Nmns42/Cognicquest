import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../router/app_router.dart';
import '../providers/quiz_provider.dart';

/// « Priorités du jour » : les chapitres à reprendre en premier, avec ce
/// qui les fait remonter (flou, rentabilité, objectif, tâche urgente).
class RevisionFocusSection extends ConsumerWidget {
  const RevisionFocusSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cq = context.cq;
    final focus = ref.watch(revisionFocusProvider).take(3).toList();
    if (focus.isEmpty) return const SizedBox.shrink();
    final fuzzy = ref.watch(fuzzyHeadingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Priorités du jour',
          style: TextStyle(
            fontSize: TypeScale.caption,
            fontWeight: FontWeight.w600,
            color: cq.terre,
            letterSpacing: TypeScale.tracking(TypeScale.caption, TypeScale.labelEm),
          ),
        ),
        const SizedBox(height: Space.sm),
        for (final (i, item) in focus.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Material(
              color: cq.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.card),
                side: BorderSide(color: cq.beigeDark),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontFamily: appSerifFamily,
                        fontSize: TypeScale.title,
                        color: cq.vertSauge,
                        fontFeatures: TypeScale.tabular,
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.note.displayTitle,
                              style: TextStyle(
                                  fontSize: TypeScale.body,
                                  fontWeight: FontWeight.w600,
                                  color: cq.textPrimary)),
                          const SizedBox(height: Space.xs),
                          Text(item.reasons.take(3).join(' · '),
                              style: TextStyle(
                                  fontSize: TypeScale.caption,
                                  color: cq.textMuted)),
                          Wrap(
                            spacing: Space.sm,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero),
                                onPressed: () => context.push(
                                    AppRoute.quizFor(noteId: item.note.id)),
                                child: const Text('Quiz'),
                              ),
                              if (fuzzy[item.note.id]?.isNotEmpty ?? false)
                                TextButton(
                                  style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero),
                                  onPressed: () => context
                                      .push(AppRoute.sq3rFor(item.note.id)),
                                  child: const Text('Étude guidée'),
                                ),
                            ],
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
