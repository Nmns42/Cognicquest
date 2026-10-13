import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/note_link_model.dart';
import '../../notes/providers/note_provider.dart';
import '../providers/graph_provider.dart';
import '../../../core/theme/tokens.dart';

/// Analyse du graphe et suggestions d'association.
///
/// CdC : « Analyse du graphe de connaissances pour détecter les zones
/// sous-connectées ou surchargées » et « Suggestions d'association dans le
/// graphe pour mieux connecter les connaissances ».
class GraphInsightsSheet extends ConsumerWidget {
  const GraphInsightsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        sheetAnimationStyle: Motion.style(context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const GraphInsightsSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(graphInsightsProvider);
    final suggestions = ref.watch(suggestedLinksProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration:  BoxDecoration(
        color: context.cq.beige,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.md)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.cq.beigeDark,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Analyse de ta carte',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              insights.summary,
              style:  TextStyle(
                  fontSize: TypeScale.body, color: context.cq.textMuted, height: 1.4),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _Metric(
                    value: '${insights.componentCount}',
                    label: insights.componentCount > 1 ? 'îlots' : 'îlot',
                  ),
                ),
                Expanded(
                  child: _Metric(
                    value: insights.averageDegree.toStringAsFixed(1),
                    label: 'liens / fiche',
                  ),
                ),
                Expanded(
                  child: _Metric(
                    value: '${insights.isolatedNotes.length}',
                    label: 'isolées',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (insights.hubs.isNotEmpty) ...[
                      const _SectionLabel('Tes notions pivots'),
                      const SizedBox(height: 4),
                       Text(
                        'Les plus connectées : ce sont elles qui structurent '
                        'ta compréhension.',
                        style: TextStyle(
                            fontSize: TypeScale.caption, color: context.cq.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final note in insights.hubs)
                            Chip(
                              label: Text(note.displayTitle,
                                  style: const TextStyle(fontSize: TypeScale.caption)),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (insights.isolatedNotes.isNotEmpty) ...[
                      const _SectionLabel('Fiches isolées'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final note in insights.isolatedNotes.take(12))
                            Chip(
                              label: Text(note.displayTitle,
                                  style: const TextStyle(fontSize: TypeScale.caption)),
                              avatar: const Icon(Icons.link_off, size: 13),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    const _SectionLabel('Associations suggérées'),
                    const SizedBox(height: 4),
                     Text(
                      'Déduites des tags partagés. Tu valides, rien n\'est '
                      'créé automatiquement.',
                      style:
                          TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted),
                    ),
                    const SizedBox(height: 8),
                    if (suggestions.isEmpty)
                       Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Aucune suggestion pour l\'instant. Ajoute des tags '
                          'à tes fiches : c\'est ce qui permet de repérer les '
                          'proximités.',
                          style: TextStyle(
                              fontSize: TypeScale.caption,
                              color: context.cq.textHint,
                              height: 1.4),
                        ),
                      )
                    else
                      for (final suggestion in suggestions)
                        _SuggestionRow(suggestion: suggestion),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style:  TextStyle(
            fontSize: TypeScale.title,
            fontWeight: FontWeight.w700,
            color: context.cq.textPrimary,
          ),
        ),
        Text(label,
            style:  TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:  TextStyle(
        fontSize: TypeScale.body,
        fontWeight: FontWeight.w600,
        color: context.cq.textPrimary,
      ),
    );
  }
}

class _SuggestionRow extends ConsumerWidget {
  const _SuggestionRow({required this.suggestion});

  final SuggestedLink suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(noteByIdProvider(suggestion.sourceId));
    final target = ref.watch(noteByIdProvider(suggestion.targetId));
    if (source == null || target == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${source.displayTitle}  ↔  ${target.displayTitle}',
                    maxLines: 2,
                    style:  TextStyle(
                        fontSize: TypeScale.caption,
                        color: context.cq.textPrimary,
                        height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion.reason,
                    style:  TextStyle(
                        fontSize: TypeScale.caption, color: context.cq.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Créer ce lien',
              visualDensity: VisualDensity.compact,
              icon:  Icon(Icons.add_link, size: 18,
                  color: context.cq.vertDark),
              onPressed: () =>
                  ref.read(graphActionsProvider).acceptSuggestion(suggestion),
            ),
          ],
        ),
      ),
    );
  }
}
