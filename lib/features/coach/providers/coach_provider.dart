import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../habits/providers/habit_provider.dart';
import '../../metacognition/providers/metacognition_provider.dart';
import '../../notes/providers/note_provider.dart';
import '../../quiz/providers/quiz_provider.dart';
import '../../review/providers/review_provider.dart';
import '../../../shared/models/habit_model.dart';
import '../../../shared/models/metacognition_model.dart';
import '../domain/tree_coach.dart';

/// Fenêtre des moyennes « récentes » du journal.
const Duration coachRecentWindow = Duration(days: 7);

/// Signaux du coach, recalculés dès qu'une donnée change (bilan écrit,
/// habitude cochée, carte jugée, explication enregistrée).
final coachSignalsProvider = Provider<CoachSignals>((ref) {
  final insights = ref.watch(metacognitionInsightsProvider);
  final journal = ref.watch(journalProvider).valueOrNull ?? const [];
  final habits = ref.watch(habitProvider).valueOrNull ?? const [];
  final retention = ref.watch(retentionProvider).valueOrNull;
  final cards = ref.watch(flashcardsProvider).valueOrNull ?? const [];
  final explanations = ref.watch(explanationsProvider).valueOrNull ?? const [];
  final notes = ref.watch(notesProvider).valueOrNull ?? const [];
  final now = DateTime.now();

  // ── Journal : moyennes des 7 derniers jours ───────────────────────────
  final recent = journal
      .where((e) => now.difference(e.createdAt) <= coachRecentWindow)
      .toList();
  double? mean(num Function(JournalEntry e) pick) => recent.isEmpty
      ? null
      : recent.map(pick).fold<double>(0, (a, b) => a + b) / recent.length;
  final last = journal.isEmpty
      ? null
      : journal.map((e) => e.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
  final today = DateTime(now.year, now.month, now.day);

  // ── Notions floues : dernière confiance « Explique-moi » et oublis ────
  final latestConfidence = <String, (DateTime, int)>{};
  for (final e in explanations) {
    final known = latestConfidence[e.noteId];
    if (known == null || e.createdAt.isAfter(known.$1)) {
      latestConfidence[e.noteId] = (e.createdAt, e.confidence);
    }
  }
  final lapses = <String, int>{};
  // Erreurs de quiz récentes : elles comptent comme des oublis.
  final since = now.subtract(const Duration(days: 30));
  for (final attempt
      in ref.watch(quizAttemptsProvider).valueOrNull ?? const []) {
    final noteId = attempt.noteId;
    if (attempt.correct || noteId == null || attempt.answeredAt.isBefore(since)) {
      continue;
    }
    lapses[noteId] = (lapses[noteId] ?? 0) + 1;
  }
  for (final card in cards) {
    final noteId = card.noteId;
    if (noteId == null) continue;
    lapses[noteId] = (lapses[noteId] ?? 0) + card.schedule.lapses;
  }
  final titles = {for (final n in notes) n.id: n.title};
  final fuzzy = <FuzzyChapter>[
    for (final id in {...latestConfidence.keys, ...lapses.keys})
      if (titles[id] case final title? when title.trim().isNotEmpty)
        FuzzyChapter(
          noteId: id,
          title: title.trim(),
          confidence: latestConfidence[id]?.$2,
          lapses: lapses[id] ?? 0,
        ),
  ].where((c) => c.fuzziness > 0).toList()
    ..sort((a, b) => b.fuzziness.compareTo(a.fuzziness));

  return CoachSignals(
    recentMood: mean((e) => e.mood),
    recentEnergy: mean((e) => e.energy),
    recentEffort: mean((e) => e.rpe),
    journalEntries: journal.length,
    strainedDays: insights.strainedDays,
    daysSinceLastEntry: last == null
        ? null
        : today.difference(DateTime(last.year, last.month, last.day)).inDays,
    habitCount: habits.length,
    habitConsistency: habits.averageConsistency,
    habitsDoneToday: habits.where((h) => h.completedToday).length,
    retentionRate:
        retention != null && retention.isMeaningful ? retention.rate : null,
    reviewsLast30Days: retention?.reviews ?? 0,
    dueCards: ref.watch(dueCardsProvider).length,
    fuzzyChapters: fuzzy.take(3).toList(),
  );
});

final treeCoachProvider =
    Provider<TreeCoach>((ref) => TreeCoach(ref.watch(coachSignalsProvider)));
