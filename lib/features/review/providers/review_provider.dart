import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/flashcard_model.dart';
import '../data/review_repository.dart';
import '../domain/spaced_repetition.dart';

final flashcardsProvider = StreamProvider<List<Flashcard>>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  if (repository == null) return Stream.value(const <Flashcard>[]);
  return repository.watchCards();
});

final explanationsProvider = StreamProvider<List<Explanation>>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  if (repository == null) return Stream.value(const <Explanation>[]);
  return repository.watchExplanations();
});

/// Sessions d'étude guidée (« fiches de révision »), la plus récente d'abord.
final studySessionsProvider = StreamProvider<List<Sq3rSession>>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  if (repository == null) return Stream.value(const <Sq3rSession>[]);
  return repository.watchSessions();
});

/// Session d'étude d'une fiche, si elle existe.
final studySessionForNoteProvider =
    Provider.family<Sq3rSession?, String>((ref, noteId) {
  final sessions =
      ref.watch(studySessionsProvider).valueOrNull ?? const <Sq3rSession>[];
  return sessions.where((s) => s.noteId == noteId).firstOrNull;
});

/// Paquet sélectionné, `null` = tous.
final selectedDeckProvider = StateProvider<String?>((ref) => null);

final decksProvider = Provider<List<String>>((ref) {
  final cards = ref.watch(flashcardsProvider).valueOrNull ?? const <Flashcard>[];
  final decks = cards
      .map((c) => c.deck)
      .whereType<String>()
      .map((d) => d.trim())
      .where((d) => d.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return decks;
});

/// File de révision du jour : cartes échues, dans l'ordre le plus utile.
final dueCardsProvider = Provider<List<Flashcard>>((ref) {
  final cards = ref.watch(flashcardsProvider).valueOrNull ?? const <Flashcard>[];
  final deck = ref.watch(selectedDeckProvider);

  final due = cards
      .where((c) => c.isDue && (deck == null || c.deck == deck))
      .toList();

  due.sort((a, b) {
    // Les rappels passent avant les nouveautés : oublier ce qu'on a déjà
    // appris coûte plus cher que de retarder une découverte.
    if (a.isNew != b.isNew) return a.isNew ? 1 : -1;
    return a.schedule.dueAt.compareTo(b.schedule.dueAt);
  });
  return due;
});

final reviewedTodayProvider = FutureProvider<int>((ref) async {
  // Se recalcule dès qu'une carte change d'état.
  ref.watch(flashcardsProvider);
  final repository = ref.watch(reviewRepositoryProvider);
  if (repository == null) return 0;
  return repository.reviewedTodayCount();
});

/// Taux de rétention sur 30 jours glissants (cf. [RetentionStats]).
final retentionProvider = FutureProvider<RetentionStats>((ref) async {
  // Se recalcule dès qu'une carte est jugée.
  ref.watch(flashcardsProvider);
  final repository = ref.watch(reviewRepositoryProvider);
  if (repository == null) return const RetentionStats.empty();
  final since = DateTime.now().subtract(RetentionStats.window);
  return RetentionStats.fromGrades(await repository.gradesSince(since));
});

final reviewStatsProvider = Provider<ReviewQueueStats>((ref) {
  final cards = ref.watch(flashcardsProvider).valueOrNull ?? const <Flashcard>[];
  if (cards.isEmpty) return const ReviewQueueStats.empty();

  final due = ref.watch(dueCardsProvider);
  final reviewedToday = ref.watch(reviewedTodayProvider).valueOrNull ?? 0;

  // Charge des 7 prochains jours, pour anticiper les pics.
  final upcoming = List<int>.filled(7, 0);
  for (final card in cards) {
    final days = card.daysUntilDue;
    if (days >= 0 && days < 7) upcoming[days]++;
  }

  return ReviewQueueStats(
    dueCount: due.length,
    newCount: due.where((c) => c.isNew).length,
    totalCards: cards.length,
    reviewedToday: reviewedToday,
    upcomingWeek: upcoming,
  );
});

/// Cartes rattachées à une fiche donnée.
final cardsForNoteProvider =
    Provider.family<List<Flashcard>, String>((ref, noteId) {
  final cards = ref.watch(flashcardsProvider).valueOrNull ?? const <Flashcard>[];
  return cards.where((c) => c.noteId == noteId).toList();
});

/// Auto-explications d'une fiche, de la plus récente à la plus ancienne.
final explanationsForNoteProvider =
    Provider.family<List<Explanation>, String>((ref, noteId) {
  final all =
      ref.watch(explanationsProvider).valueOrNull ?? const <Explanation>[];
  return all.where((e) => e.noteId == noteId).toList();
});

class ReviewActions {
  const ReviewActions(this._ref);

  final Ref _ref;

  ReviewRepository? get _repository => _ref.read(reviewRepositoryProvider);

  Future<Flashcard?> createCard({
    required String front,
    required String back,
    String? noteId,
    String? deck,
  }) async =>
      _repository?.createCard(
        front: front,
        back: back,
        noteId: noteId,
        deck: deck,
      );

  Future<void> saveCard(Flashcard card) async => _repository?.saveCard(card);

  Future<void> deleteCard(String id) async => _repository?.deleteCard(id);

  Future<void> grade(Flashcard card, ReviewGrade grade) async =>
      _repository?.grade(card, grade);

  Future<void> saveExplanation(Explanation explanation) async =>
      _repository?.saveExplanation(explanation);

  Future<Sq3rSession?> sessionForNote(String noteId) async =>
      _repository?.sessionForNote(noteId);

  Future<void> saveSession(Sq3rSession session) async =>
      _repository?.saveSession(session);

  Future<void> sync() async {
    try {
      await _repository?.sync();
    } catch (_) {
      // Hors ligne : la file conserve les jugements portés.
    }
  }
}

final reviewActionsProvider = Provider<ReviewActions>(ReviewActions.new);
