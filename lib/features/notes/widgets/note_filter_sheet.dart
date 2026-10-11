import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/note_model.dart';
import '../providers/note_provider.dart';

/// Filtres de la bibliothèque — « Filtres par sujet, date, importance, type de
/// contenu » (CdC).
class NoteFilterSheet extends ConsumerWidget {
  const NoteFilterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        sheetAnimationStyle: Motion.style(context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const NoteFilterSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(noteFilterProvider);
    final notifier = ref.read(noteFilterProvider.notifier);
    final subjects = ref.watch(noteSubjectsProvider);
    final tags = ref.watch(noteTagsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration:  BoxDecoration(
        color: context.cq.beige,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text('Filtrer les fiches',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (filter.activeFacetCount > 0)
                  TextButton(
                    onPressed: notifier.clearFacets,
                    child: const Text('Tout effacer'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (subjects.isNotEmpty) ...[
                      const _Label('Sujet'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final subject in subjects)
                            FilterChip(
                              label: Text(subject,
                                  style: const TextStyle(fontSize: 12)),
                              selected: filter.subject == subject,
                              onSelected: (selected) => notifier
                                  .setSubject(selected ? subject : null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (tags.isNotEmpty) ...[
                      const _Label('Tags'),
                      const SizedBox(height: 4),
                       Text(
                        'Plusieurs tags : les fiches doivent tous les porter.',
                        style: TextStyle(
                            fontSize: 11, color: context.cq.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in tags.take(24))
                            FilterChip(
                              label: Text('#$tag',
                                  style: const TextStyle(fontSize: 12)),
                              selected: filter.tags.contains(tag),
                              onSelected: (_) => notifier.toggleTag(tag),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    const _Label('Importance'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final importance in NoteImportance.values)
                          FilterChip(
                            label: Text(importance.label,
                                style: const TextStyle(fontSize: 12)),
                            selected: filter.importance == importance,
                            onSelected: (selected) => notifier
                                .setImportance(selected ? importance : null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const _Label('Modifiée depuis'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final entry in _dateRanges.entries)
                          FilterChip(
                            label: Text(entry.key,
                                style: const TextStyle(fontSize: 12)),
                            selected: _isRangeSelected(filter.updatedAfter,
                                entry.value),
                            onSelected: (selected) => notifier.setUpdatedAfter(
                              selected ? _startOfDaysAgo(entry.value) : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: filter.favoritesOnly,
                      onChanged: (_) => notifier.toggleFavoritesOnly(),
                      title: const Text('Favorites uniquement',
                          style: TextStyle(fontSize: 14)),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: filter.includeArchived,
                      onChanged: (_) => notifier.toggleIncludeArchived(),
                      title: const Text('Inclure les fiches archivées',
                          style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voir les résultats'),
            ),
          ],
        ),
      ),
    );
  }

  static const Map<String, int> _dateRanges = {
    "Aujourd'hui": 0,
    '7 jours': 7,
    '30 jours': 30,
  };

  static DateTime _startOfDaysAgo(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days));
  }

  static bool _isRangeSelected(DateTime? value, int days) {
    if (value == null) return false;
    final expected = _startOfDaysAgo(days);
    return value.year == expected.year &&
        value.month == expected.month &&
        value.day == expected.day;
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:  TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.cq.textMuted,
      ),
    );
  }
}
