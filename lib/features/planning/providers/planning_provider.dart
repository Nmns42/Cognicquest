import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/planning_model.dart';
import '../data/planning_repository.dart';
import '../domain/adaptive_schedule.dart';
import '../domain/gantt_timeline.dart';
import '../domain/revision_priority.dart';
import '../domain/study_speed.dart';

final studyGoalsProvider = StreamProvider<List<StudyGoal>>((ref) {
  final repository = ref.watch(planningRepositoryProvider);
  if (repository == null) return Stream.value(const <StudyGoal>[]);
  return repository.watchGoals();
});

final planItemsProvider = StreamProvider<List<PlanItem>>((ref) {
  final repository = ref.watch(planningRepositoryProvider);
  if (repository == null) return Stream.value(const <PlanItem>[]);
  return repository.watchPlanItems();
});

final speedSamplesProvider = StreamProvider<List<SpeedSample>>((ref) {
  final repository = ref.watch(planningRepositoryProvider);
  if (repository == null) return Stream.value(const <SpeedSample>[]);
  return repository.watchSpeedSamples();
});

final examTargetsProvider = StreamProvider<List<ExamTarget>>((ref) {
  final repository = ref.watch(planningRepositoryProvider);
  if (repository == null) return Stream.value(const <ExamTarget>[]);
  return repository.watchExamTargets();
});

/// Niveau de zoom du Gantt.
final ganttZoomProvider = StateProvider<GanttZoom>((ref) => GanttZoom.week);

/// Mise en page du diagramme.
final ganttLayoutProvider = Provider<GanttLayout>((ref) {
  final items = ref.watch(planItemsProvider).valueOrNull ?? const <PlanItem>[];
  return GanttTimeline.layout(items);
});

/// Enchaînements incohérents à signaler.
final dependencyViolationsProvider = Provider<List<PlanItem>>((ref) {
  final items = ref.watch(planItemsProvider).valueOrNull ?? const <PlanItem>[];
  return GanttTimeline.violatedDependencies(items);
});

/// Prochaines échéances du planning.
final upcomingPlanItemsProvider = Provider<List<PlanItem>>((ref) {
  final items = ref.watch(planItemsProvider).valueOrNull ?? const <PlanItem>[];
  return GanttTimeline.upcoming(items);
});

/// Classement des chapitres par rentabilité.
/// Vitesse de lecture mesurée (pages par heure), toutes matières.
final readingSpeedProvider = Provider<double?>((ref) {
  final samples =
      ref.watch(speedSamplesProvider).valueOrNull ?? const <SpeedSample>[];
  return StudySpeed.readingPagesPerHour(samples);
});

/// Chapitres classés par rentabilité estimée, le temps venant de la vitesse
/// de lecture mesurée quand elle existe.
final rankedTargetsProvider = Provider<List<RankedTarget>>((ref) {
  final targets =
      ref.watch(examTargetsProvider).valueOrNull ?? const <ExamTarget>[];
  return RevisionPriority.rank(targets,
      pagesPerHour: ref.watch(readingSpeedProvider));
});

/// Chapitres écartés du classement, avec la raison.
final excludedTargetsProvider = Provider<List<(ExamTarget, String)>>((ref) {
  final targets =
      ref.watch(examTargetsProvider).valueOrNull ?? const <ExamTarget>[];
  return RevisionPriority.excluded(targets);
});

/// Capacité de travail quotidienne, en heures, réglée par l'utilisateur.
final dailyCapacityProvider = StateProvider<double>((ref) => 2);

/// Plan de révision généré à partir des chapitres et de la capacité.
final adaptivePlanProvider = Provider<AdaptivePlan>((ref) {
  final targets =
      ref.watch(examTargetsProvider).valueOrNull ?? const <ExamTarget>[];
  return AdaptiveSchedule.generate(
    targets,
    dailyCapacityHours: ref.watch(dailyCapacityProvider),
  );
});

/// Matière sélectionnée pour l'estimation de vitesse.
final speedSubjectProvider = StateProvider<String?>((ref) => null);

final speedEstimatesProvider = Provider<List<SpeedEstimate>>((ref) {
  final samples =
      ref.watch(speedSamplesProvider).valueOrNull ?? const <SpeedSample>[];
  return StudySpeed.allEstimates(samples,
      subject: ref.watch(speedSubjectProvider));
});

/// Toutes les estimations de vitesse, toutes matières (objectifs SMART).
final allSpeedEstimatesProvider = Provider<List<SpeedEstimate>>((ref) {
  final samples =
      ref.watch(speedSamplesProvider).valueOrNull ?? const <SpeedSample>[];
  return StudySpeed.allEstimates(samples);
});

final speedSubjectsProvider = Provider<List<String>>((ref) {
  final samples =
      ref.watch(speedSamplesProvider).valueOrNull ?? const <SpeedSample>[];
  return StudySpeed.subjectsOf(samples);
});

/// Objectifs en cours, les plus urgents d'abord.
final activeGoalsProvider = Provider<List<StudyGoal>>((ref) {
  final goals =
      ref.watch(studyGoalsProvider).valueOrNull ?? const <StudyGoal>[];
  final active = goals.where((g) => !g.isCompleted).toList()
    ..sort((a, b) {
      // Les objectifs en retard d'abord, puis par échéance, puis sans date.
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      final aDue = a.deadline;
      final bDue = b.deadline;
      if (aDue != null && bDue != null) return aDue.compareTo(bDue);
      if (aDue != null) return -1;
      if (bDue != null) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  return active;
});

class PlanningActions {
  const PlanningActions(this._ref);

  final Ref _ref;

  PlanningRepository? get _repository => _ref.read(planningRepositoryProvider);

  Future<void> saveGoal(StudyGoal goal) async => _repository?.saveGoal(goal);

  Future<void> deleteGoal(String id) async => _repository?.deleteGoal(id);

  Future<void> toggleGoalCompleted(StudyGoal goal) => saveGoal(
        goal.isCompleted
            ? goal.copyWith(clearCompletedAt: true)
            : goal.copyWith(completedAt: DateTime.now()),
      );

  Future<void> savePlanItem(PlanItem item) async =>
      _repository?.savePlanItem(item);

  Future<void> deletePlanItem(String id) async =>
      _repository?.deletePlanItem(id);

  /// Décale un élément **et sa chaîne de dépendances**.
  Future<void> shiftPlanItem(String itemId, Duration offset) async {
    final items =
        _ref.read(planItemsProvider).valueOrNull ?? const <PlanItem>[];
    final shifted = GanttTimeline.shift(items, itemId, offset);

    // On n'écrit que ce qui a réellement bougé.
    final byId = {for (final item in items) item.id: item};
    final changed = shifted
        .where((item) => byId[item.id]?.startDate != item.startDate)
        .toList();

    if (changed.isNotEmpty) await _repository?.savePlanItems(changed);
  }

  /// Établit une dépendance, en refusant celles qui créeraient un cycle.
  ///
  /// Renvoie `false` si la dépendance a été refusée, pour que l'interface
  /// puisse l'expliquer plutôt que d'échouer en silence.
  Future<bool> linkDependency(String itemId, String? dependsOnId) async {
    final items =
        _ref.read(planItemsProvider).valueOrNull ?? const <PlanItem>[];
    final item = items.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return false;

    if (dependsOnId != null &&
        GanttTimeline.wouldCreateCycle(items, itemId, dependsOnId)) {
      return false;
    }

    await _repository?.savePlanItem(
      item.copyWith(
        dependsOnId: dependsOnId,
        clearDependsOn: dependsOnId == null,
      ),
    );
    return true;
  }

  Future<void> saveSpeedSample(SpeedSample sample) async =>
      _repository?.saveSpeedSample(sample);

  Future<void> saveExamTarget(ExamTarget target) async =>
      _repository?.saveExamTarget(target);

  Future<void> deleteExamTarget(String id) async =>
      _repository?.deleteExamTarget(id);

  /// Transforme le plan généré en barres de Gantt.
  Future<int> materialisePlan() async {
    final plan = _ref.read(adaptivePlanProvider);
    final items = AdaptiveSchedule.toPlanItems(
      plan,
      userId: '',
      idGenerator: newPlanningId,
    );
    if (items.isEmpty) return 0;

    await _repository?.savePlanItems(items);
    return items.length;
  }

  Future<void> sync() async {
    try {
      await _repository?.sync();
    } catch (_) {
      // Hors ligne : la file conserve les écritures.
    }
  }
}

final planningActionsProvider = Provider<PlanningActions>(PlanningActions.new);
