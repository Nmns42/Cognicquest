import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/metacognition_model.dart';
import '../data/metacognition_repository.dart';
import '../domain/learning_profile.dart';
import '../domain/metacognition_insights.dart';

final journalProvider = StreamProvider<List<JournalEntry>>((ref) {
  final repository = ref.watch(metacognitionRepositoryProvider);
  if (repository == null) return Stream.value(const <JournalEntry>[]);
  return repository.watchJournal();
});

final reframesProvider = StreamProvider<List<Reframe>>((ref) {
  final repository = ref.watch(metacognitionRepositoryProvider);
  if (repository == null) return Stream.value(const <Reframe>[]);
  return repository.watchReframes();
});

final whyChainsProvider = StreamProvider<List<WhyChain>>((ref) {
  final repository = ref.watch(metacognitionRepositoryProvider);
  if (repository == null) return Stream.value(const <WhyChain>[]);
  return repository.watchWhyChains();
});

final errorLogsProvider = StreamProvider<List<ErrorLog>>((ref) {
  final repository = ref.watch(metacognitionRepositoryProvider);
  if (repository == null) return Stream.value(const <ErrorLog>[]);
  return repository.watchErrors();
});

final learningProfileProvider = StreamProvider<LearningProfile>((ref) {
  final repository = ref.watch(metacognitionRepositoryProvider);
  if (repository == null) return Stream.value(LearningProfile.empty);
  return repository.watchProfile();
});

/// Lecture d'ensemble du journal : humeur, effort, risque d'épuisement.
final metacognitionInsightsProvider = Provider<MetacognitionInsights>((ref) {
  final entries = ref.watch(journalProvider).valueOrNull ?? const <JournalEntry>[];
  return MetacognitionInsights.from(entries);
});

/// Motifs d'erreurs, toutes matières confondues.
final errorPatternProvider = Provider<ErrorPattern>((ref) {
  final errors = ref.watch(errorLogsProvider).valueOrNull ?? const <ErrorLog>[];
  return ErrorPattern.from(errors);
});

/// Motifs d'erreurs filtrés sur une matière.
final errorPatternBySubjectProvider =
    Provider.family<ErrorPattern, String>((ref, subject) {
  final errors = ref.watch(errorLogsProvider).valueOrNull ?? const <ErrorLog>[];
  return ErrorPattern.from(
    errors.where((e) => e.subject == subject).toList(),
  );
});

/// Matières pour lesquelles au moins une erreur a été consignée.
final errorSubjectsProvider = Provider<List<String>>((ref) {
  final errors = ref.watch(errorLogsProvider).valueOrNull ?? const <ErrorLog>[];
  final subjects = errors
      .map((e) => e.subject)
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return subjects;
});

/// Entrée du journal déjà écrite aujourd'hui, s'il y en a une.
final todayJournalEntryProvider = Provider<JournalEntry?>((ref) {
  final entries = ref.watch(journalProvider).valueOrNull ?? const <JournalEntry>[];
  final now = DateTime.now();

  for (final entry in entries) {
    if (entry.createdAt.year == now.year &&
        entry.createdAt.month == now.month &&
        entry.createdAt.day == now.day) {
      return entry;
    }
  }
  return null;
});

/// Recadrages laissés en chantier : identifier une pensée bloquante sans la
/// transformer ne sert à rien.
final unfinishedReframesProvider = Provider<List<Reframe>>((ref) {
  final reframes = ref.watch(reframesProvider).valueOrNull ?? const <Reframe>[];
  return reframes.where((r) => !r.isComplete).toList();
});

class MetacognitionActions {
  const MetacognitionActions(this._ref);

  final Ref _ref;

  MetacognitionRepository? get _repository =>
      _ref.read(metacognitionRepositoryProvider);

  Future<void> saveJournalEntry(JournalEntry entry) async =>
      _repository?.saveJournalEntry(entry);

  Future<void> saveReframe(Reframe reframe) async =>
      _repository?.saveReframe(reframe);

  Future<void> saveWhyChain(WhyChain chain) async =>
      _repository?.saveWhyChain(chain);

  Future<void> saveError(ErrorLog error) async => _repository?.saveError(error);

  /// Enregistre les réponses du questionnaire et en déduit le profil.
  Future<void> saveProfileAnswers(
    Map<String, String> answers, {
    bool complete = false,
  }) async {
    final profile = ProfilingQuestionnaire.score(
      answers,
      completedAt: complete ? DateTime.now() : null,
    );
    await _repository?.saveProfile(profile);
  }

  Future<void> sync() async {
    try {
      await _repository?.sync();
    } catch (_) {
      // Hors ligne : la file conserve les entrées.
    }
  }
}

final metacognitionActionsProvider =
    Provider<MetacognitionActions>(MetacognitionActions.new);
