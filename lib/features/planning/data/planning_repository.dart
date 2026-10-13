import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_queue.dart';
import '../../../shared/models/planning_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/data/note_repository.dart';

abstract interface class PlanningRepository {
  Stream<List<StudyGoal>> watchGoals();
  Stream<List<PlanItem>> watchPlanItems();
  Stream<List<SpeedSample>> watchSpeedSamples();
  Stream<List<ExamTarget>> watchExamTargets();

  Future<void> saveGoal(StudyGoal goal);
  Future<void> deleteGoal(String id);

  Future<void> savePlanItem(PlanItem item);
  Future<void> savePlanItems(List<PlanItem> items);
  Future<void> deletePlanItem(String id);

  Future<void> saveSpeedSample(SpeedSample sample);

  Future<void> saveExamTarget(ExamTarget target);
  Future<void> deleteExamTarget(String id);

  Future<void> sync();
}

class LocalFirstPlanningRepository implements PlanningRepository {
  LocalFirstPlanningRepository({
    required AppDatabase database,
    required SupabaseClient client,
    required String userId,
    bool syncEnabled = true,
  })  : _db = database,
        _client = client,
        _userId = userId,
        _syncEnabled = syncEnabled;

  final AppDatabase _db;
  final SupabaseClient _client;
  final String _userId;

  /// `false` sans vraie session (mode `DEV_BYPASS_AUTH`) : tout reste local,
  /// aucune requête ne part avec l'utilisateur fictif.
  final bool _syncEnabled;

  late final SyncQueue _queue = SyncQueue(_db);

  static const String _goalsTable = 'study_goals';
  static const String _itemsTable = 'plan_items';
  static const String _samplesTable = 'speed_samples';
  static const String _targetsTable = 'exam_targets';

  // ── Lecture ──────────────────────────────────────────────────────────────

  @override
  Stream<List<StudyGoal>> watchGoals() {
    final query = _db.select(_db.localStudyGoals)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([(t) => OrderingTerm.asc(t.deadline)]);

    return query.watch().map((rows) => rows
        .map((row) => StudyGoal(
              id: row.id,
              userId: row.userId,
              title: row.title,
              subject: row.subject,
              metricLabel: row.metricLabel,
              targetValue: row.targetValue,
              currentValue: row.currentValue,
              achievablePlan: row.achievablePlan,
              relevance: row.relevance,
              deadline: row.deadline,
              createdAt: row.createdAt,
              completedAt: row.completedAt,
              isSynced: row.isSynced,
            ))
        .toList());
  }

  @override
  Stream<List<PlanItem>> watchPlanItems() {
    final query = _db.select(_db.localPlanItems)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([(t) => OrderingTerm.asc(t.startDate)]);

    return query.watch().map((rows) => rows
        .map((row) => PlanItem(
              id: row.id,
              userId: row.userId,
              goalId: row.goalId,
              taskId: row.taskId,
              title: row.title,
              subject: row.subject,
              startDate: row.startDate,
              endDate: row.endDate,
              progress: row.progress,
              isMilestone: row.isMilestone,
              dependsOnId: row.dependsOnId,
              createdAt: row.createdAt,
              isSynced: row.isSynced,
            ))
        .toList());
  }

  @override
  Stream<List<SpeedSample>> watchSpeedSamples() {
    final query = _db.select(_db.localSpeedSamples)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.watch().map((rows) => rows
        .map((row) => SpeedSample(
              id: row.id,
              userId: row.userId,
              activity: StudyActivity.fromValue(row.activity),
              subject: row.subject,
              units: row.units,
              durationSeconds: row.durationSeconds,
              createdAt: row.createdAt,
              isSynced: row.isSynced,
            ))
        .toList());
  }

  @override
  Stream<List<ExamTarget>> watchExamTargets() {
    final query = _db.select(_db.localExamTargets)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([(t) => OrderingTerm.asc(t.examDate)]);

    return query.watch().map((rows) => rows
        .map((row) => ExamTarget(
              id: row.id,
              userId: row.userId,
              noteId: row.noteId,
              title: row.title,
              subject: row.subject,
              examWeight: row.examWeight,
              currentGrade: row.currentGrade,
              reachableGrade: row.reachableGrade,
              lengthHours: row.lengthHours,
              difficulty: row.difficulty,
              examDate: row.examDate,
              createdAt: row.createdAt,
              isSynced: row.isSynced,
            ))
        .toList());
  }

  // ── Écriture ─────────────────────────────────────────────────────────────

  @override
  Future<void> saveGoal(StudyGoal goal) async {
    await _db.transaction(() async {
      await _db.into(_db.localStudyGoals).insertOnConflictUpdate(
            LocalStudyGoalsCompanion.insert(
              id: goal.id,
              userId: _userId,
              title: goal.title,
              subject: Value(goal.subject),
              metricLabel: Value(goal.metricLabel),
              targetValue: Value(goal.targetValue),
              currentValue: Value(goal.currentValue),
              achievablePlan: Value(goal.achievablePlan),
              relevance: Value(goal.relevance),
              deadline: Value(goal.deadline),
              createdAt: goal.createdAt,
              completedAt: Value(goal.completedAt),
              isSynced: const Value(false),
            ),
          );
      await _enqueue(_goalsTable, goal.id, 'upsert');
    });
    _syncQuietly();
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.localStudyGoals)..where((t) => t.id.equals(id)))
          .go();
      await _enqueue(_goalsTable, id, 'delete');
    });
    _syncQuietly();
  }

  @override
  Future<void> savePlanItem(PlanItem item) => savePlanItems([item]);

  @override
  Future<void> savePlanItems(List<PlanItem> items) async {
    if (items.isEmpty) return;

    // Une seule transaction pour tout le lot : un décalage en cascade peut
    // toucher une dizaine de barres, et un état intermédiaire incohérent
    // s'afficherait brièvement à l'écran.
    await _db.transaction(() async {
      for (final item in items) {
        await _db.into(_db.localPlanItems).insertOnConflictUpdate(
              LocalPlanItemsCompanion.insert(
                id: item.id,
                userId: _userId,
                goalId: Value(item.goalId),
                taskId: Value(item.taskId),
                title: item.title,
                subject: Value(item.subject),
                startDate: item.startDate,
                endDate: item.endDate,
                progress: Value(item.progress),
                isMilestone: Value(item.isMilestone),
                dependsOnId: Value(item.dependsOnId),
                createdAt: item.createdAt,
                isSynced: const Value(false),
              ),
            );
        await _enqueue(_itemsTable, item.id, 'upsert');
      }
    });
    _syncQuietly();
  }

  @override
  Future<void> deletePlanItem(String id) async {
    await _db.transaction(() async {
      // Les éléments qui en dépendaient perdent leur dépendance plutôt que de
      // pointer dans le vide.
      await (_db.update(_db.localPlanItems)
            ..where((t) => t.dependsOnId.equals(id)))
          .write(const LocalPlanItemsCompanion(dependsOnId: Value(null)));

      await (_db.delete(_db.localPlanItems)..where((t) => t.id.equals(id)))
          .go();
      await _enqueue(_itemsTable, id, 'delete');
    });
    _syncQuietly();
  }

  @override
  Future<void> saveSpeedSample(SpeedSample sample) async {
    await _db.transaction(() async {
      await _db.into(_db.localSpeedSamples).insertOnConflictUpdate(
            LocalSpeedSamplesCompanion.insert(
              id: sample.id,
              userId: _userId,
              activity: sample.activity.value,
              subject: Value(sample.subject),
              units: sample.units,
              durationSeconds: sample.durationSeconds,
              createdAt: sample.createdAt,
              isSynced: const Value(false),
            ),
          );
      await _enqueue(_samplesTable, sample.id, 'upsert');
    });
    _syncQuietly();
  }

  @override
  Future<void> saveExamTarget(ExamTarget target) async {
    await _db.transaction(() async {
      await _db.into(_db.localExamTargets).insertOnConflictUpdate(
            LocalExamTargetsCompanion.insert(
              id: target.id,
              userId: _userId,
              noteId: Value(target.noteId),
              title: target.title,
              subject: Value(target.subject),
              examWeight: Value(target.examWeight),
              currentGrade: Value(target.currentGrade),
              reachableGrade: Value(target.reachableGrade),
              lengthHours: Value(target.lengthHours),
              difficulty: Value(target.difficulty),
              examDate: Value(target.examDate),
              createdAt: target.createdAt,
              isSynced: const Value(false),
            ),
          );
      await _enqueue(_targetsTable, target.id, 'upsert');
    });
    _syncQuietly();
  }

  @override
  Future<void> deleteExamTarget(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.localExamTargets)..where((t) => t.id.equals(id)))
          .go();
      await _enqueue(_targetsTable, id, 'delete');
    });
    _syncQuietly();
  }

  Future<void> _enqueue(String table, String entityId, String operation) async {
    await (_db.delete(_db.syncQueueEntries)
          ..where(
              (t) => t.entityTable.equals(table) & t.entityId.equals(entityId)))
        .go();

    await _db.into(_db.syncQueueEntries).insert(
          SyncQueueEntriesCompanion.insert(
            entityTable: table,
            entityId: entityId,
            operation: operation,
            queuedAt: DateTime.now(),
          ),
        );
  }

  void _syncQuietly() {
    sync().catchError((_) {});
  }

  // ── Synchronisation ──────────────────────────────────────────────────────

  @override
  Future<void> sync() async {
    if (!_syncEnabled) return;
    await _pushGoals();
    await _pushItems();
    await _pushSamples();
    await _pushTargets();
  }

  Future<void> _pushGoals() async {
    await _queue.drain(_goalsTable, (entry) async {
      if (entry.operation == 'delete') {
        await _client.from(_goalsTable).delete().eq('id', entry.entityId);
      } else {
        final row = await (_db.select(_db.localStudyGoals)
              ..where((t) => t.id.equals(entry.entityId)))
            .getSingleOrNull();
        if (row != null) {
          await _client.from(_goalsTable).upsert({
            'id': row.id,
            'user_id': row.userId,
            'title': row.title,
            'subject': row.subject,
            'metric_label': row.metricLabel,
            'target_value': row.targetValue,
            'current_value': row.currentValue,
            'achievable_plan': row.achievablePlan,
            'relevance': row.relevance,
            'deadline': row.deadline?.toUtc().toIso8601String(),
            'created_at': row.createdAt.toUtc().toIso8601String(),
            'completed_at': row.completedAt?.toUtc().toIso8601String(),
          });
          await (_db.update(_db.localStudyGoals)
                ..where((t) => t.id.equals(row.id)))
              .write(const LocalStudyGoalsCompanion(isSynced: Value(true)));
        }
      }
    });
  }

  Future<void> _pushItems() async {
    await _queue.drain(_itemsTable, (entry) async {
      if (entry.operation == 'delete') {
        await _client.from(_itemsTable).delete().eq('id', entry.entityId);
      } else {
        final row = await (_db.select(_db.localPlanItems)
              ..where((t) => t.id.equals(entry.entityId)))
            .getSingleOrNull();
        if (row != null) {
          await _client.from(_itemsTable).upsert({
            'id': row.id,
            'user_id': row.userId,
            'goal_id': row.goalId,
            'task_id': row.taskId,
            'title': row.title,
            'subject': row.subject,
            'start_date': row.startDate.toUtc().toIso8601String(),
            'end_date': row.endDate.toUtc().toIso8601String(),
            'progress': row.progress,
            'is_milestone': row.isMilestone,
            'depends_on_id': row.dependsOnId,
            'created_at': row.createdAt.toUtc().toIso8601String(),
          });
          await (_db.update(_db.localPlanItems)
                ..where((t) => t.id.equals(row.id)))
              .write(const LocalPlanItemsCompanion(isSynced: Value(true)));
        }
      }
    });
  }

  Future<void> _pushSamples() async {
    await _queue.drain(_samplesTable, (entry) async {
      final row = await (_db.select(_db.localSpeedSamples)
            ..where((t) => t.id.equals(entry.entityId)))
          .getSingleOrNull();
      if (row != null) {
        await _client.from(_samplesTable).upsert({
          'id': row.id,
          'user_id': row.userId,
          'activity': row.activity,
          'subject': row.subject,
          'units': row.units,
          'duration_seconds': row.durationSeconds,
          'created_at': row.createdAt.toUtc().toIso8601String(),
        });
        await (_db.update(_db.localSpeedSamples)
              ..where((t) => t.id.equals(row.id)))
            .write(const LocalSpeedSamplesCompanion(isSynced: Value(true)));
      }
    });
  }

  Future<void> _pushTargets() async {
    await _queue.drain(_targetsTable, (entry) async {
      if (entry.operation == 'delete') {
        await _client.from(_targetsTable).delete().eq('id', entry.entityId);
      } else {
        final row = await (_db.select(_db.localExamTargets)
              ..where((t) => t.id.equals(entry.entityId)))
            .getSingleOrNull();
        if (row != null) {
          await _client.from(_targetsTable).upsert({
            'id': row.id,
            'user_id': row.userId,
            'note_id': row.noteId,
            'title': row.title,
            'subject': row.subject,
            'exam_weight': row.examWeight,
            'current_grade': row.currentGrade,
            'reachable_grade': row.reachableGrade,
            'length_hours': row.lengthHours,
            'difficulty': row.difficulty,
            'exam_date': row.examDate?.toUtc().toIso8601String(),
            'created_at': row.createdAt.toUtc().toIso8601String(),
          });
          await (_db.update(_db.localExamTargets)
                ..where((t) => t.id.equals(row.id)))
              .write(const LocalExamTargetsCompanion(isSynced: Value(true)));
        }
      }
    });
  }


}

final planningRepositoryProvider = Provider<PlanningRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  return LocalFirstPlanningRepository(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    userId: userId,
    syncEnabled: ref.watch(currentUserProvider) != null,
  );
});

/// Identifiant client, réutilisé depuis le Lot 4.
String newPlanningId() => LocalFirstNoteRepository.newId();
