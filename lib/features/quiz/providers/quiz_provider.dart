import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/metacognition_model.dart';
import '../../../shared/models/note_model.dart';
import '../../kanban/providers/task_provider.dart';
import '../../metacognition/data/metacognition_repository.dart';
import '../../metacognition/providers/metacognition_provider.dart';
import '../../notes/providers/note_provider.dart';
import '../../planning/providers/planning_provider.dart';
import '../../review/domain/spaced_repetition.dart';
import '../../review/data/review_repository.dart';
import '../../review/providers/review_provider.dart';
import '../data/quiz_repository.dart';
import '../domain/quiz_generator.dart';
import '../domain/quiz_loops.dart';

final quizAttemptsProvider = StreamProvider<List<QuizAttempt>>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  if (repository == null) return Stream.value(const <QuizAttempt>[]);
  return repository.watchAll();
});

/// Titres flous de chaque fiche, d'après les réponses des 30 derniers jours.
final fuzzyHeadingsProvider = Provider<Map<String, Set<String>>>((ref) =>
    fuzzyHeadingsFrom(ref.watch(quizAttemptsProvider).valueOrNull ?? const []));

/// Titres flous d'une fiche (étude guidée).
final fuzzyHeadingsForNoteProvider = Provider.family<Set<String>, String>(
    (ref, noteId) => ref.watch(fuzzyHeadingsProvider)[noteId] ?? const {});

/// Priorités de révision du jour.
final revisionFocusProvider = Provider<List<RevisionFocusItem>>((ref) {
  final notes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
  return RevisionEngine.rank(
    notes: notes,
    cards: ref.watch(flashcardsProvider).valueOrNull ?? const [],
    attempts: ref.watch(quizAttemptsProvider).valueOrNull ?? const [],
    targets: ref.watch(examTargetsProvider).valueOrNull ?? const [],
    goals: ref.watch(studyGoalsProvider).valueOrNull ?? const [],
    tasks: ref.watch(taskProvider).valueOrNull ?? const [],
    pagesPerHour: ref.watch(readingSpeedProvider),
  );
});

/// Paramètres d'un quiz : mode et, en option, une seule fiche.
typedef QuizRequest = ({QuizMode mode, String? noteId});

/// Questions d'un quiz, tirées une fois à l'ouverture (elles ne changent
/// pas quand une réponse modifie les cartes).
final quizQuestionsProvider = Provider.autoDispose
    .family<List<QuizQuestion>, QuizRequest>((ref, request) {
  final notes = ref.read(notesProvider).valueOrNull ?? const <Note>[];
  final cards = ref.read(flashcardsProvider).valueOrNull ?? const [];
  return QuizGenerator(seed: DateTime.now().millisecondsSinceEpoch)
      .generate(
    notes: notes.where((n) => !n.isArchived).toList(),
    cards: cards,
    mode: request.mode,
    onlyNoteId: request.noteId,
    focus: QuizFocus(
      noteIds: {for (final f in ref.read(revisionFocusProvider)) f.note.id},
      fuzzyHeadings: ref.read(fuzzyHeadingsProvider),
    ),
  );
});

/// Applique les boucles d'un quiz terminé : cartes ratées remises à J0,
/// cartes créées pour les notions de fiche ratées, fautes consignées dans
/// le Cahier d'erreurs.
class QuizActions {
  const QuizActions(this._ref);

  final Ref _ref;

  Future<void> record(QuizQuestion question, {required bool correct}) async =>
      _ref.read(quizRepositoryProvider)?.record(question, correct: correct);

  Future<QuizOutcome> finish(List<(QuizQuestion, bool)> answers) async {
    final cards = _ref.read(flashcardsProvider).valueOrNull ?? const [];
    final outcome = QuizOutcome.of(
      answers,
      existingCards: cards,
      // `.future` : le cahier n'est peut-être écouté par aucun écran.
      existingErrors: await _ref.read(errorLogsProvider.future),
    );
    final review = _ref.read(reviewActionsProvider);
    final repository = _ref.read(reviewRepositoryProvider);
    if (repository != null) {
      for (final id in outcome.cardsToRelearn) {
        final card = cards.where((c) => c.id == id).firstOrNull;
        // « À revoir » : la carte revient à J0, à réviser aujourd'hui.
        if (card != null) await repository.grade(card, ReviewGrade.again);
      }
    }
    String? subjectOf(String? noteId) => _ref
        .read(notesProvider)
        .valueOrNull
        ?.where((n) => n.id == noteId)
        .firstOrNull
        ?.subject;
    for (final draft in outcome.cardsToCreate) {
      await review.createCard(
        front: draft.front,
        back: draft.back,
        noteId: draft.noteId,
        deck: subjectOf(draft.noteId),
      );
    }
    final metacognition = _ref.read(metacognitionActionsProvider);
    final now = DateTime.now();
    for (final draft in outcome.errorsToLog) {
      await metacognition.saveError(ErrorLog(
        id: newMetacognitionId(),
        userId: '',
        noteId: draft.noteId,
        subject: subjectOf(draft.noteId),
        description: draft.description,
        errorType: draft.errorType,
        createdAt: now,
        isSynced: false,
      ));
    }
    return outcome;
  }
}

final quizActionsProvider = Provider<QuizActions>(QuizActions.new);
