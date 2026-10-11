import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/remote_pagination.dart';
import '../../../core/database/sync_queue.dart';
import '../../../shared/models/pomodoro_session_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/data/note_repository.dart';

abstract interface class PomodoroRepository {
  /// Sessions des [limitDays] derniers jours, plus récentes d'abord.
  Stream<List<PomodoroSession>> watchRecent({int limitDays = 90});
  Future<List<PomodoroSession>> fetchRecent({int limitDays = 90});

  Future<PomodoroSession> record({
    required DateTime startedAt,
    required int durationSeconds,
    String? taskId,
  });

  /// Pousse les sessions en attente puis rapatrie celles des autres appareils.
  Future<void> sync();
}

/// Implémentation **local-first** de l'historique Pomodoro (Lot 10).
///
/// Une session terminée dans le train ou en bibliothèque sans wifi est
/// désormais comptée tout de suite, puis envoyée au retour du réseau. Avant,
/// elle était perdue en silence.
class LocalFirstPomodoroRepository implements PomodoroRepository {
  LocalFirstPomodoroRepository({
    required AppDatabase database,
    required SupabaseClient client,
    required String userId,
  })  : _db = database,
        _queue = SyncQueue(database),
        _client = client,
        _userId = userId;

  final AppDatabase _db;
  final SyncQueue _queue;
  final SupabaseClient _client;
  final String _userId;

  static const String table = 'pomodoro_sessions';

  /// Fenêtre rapatriée du serveur : les statistiques affichées ne vont pas
  /// au-delà du trimestre, inutile de télécharger tout l'historique.
  static const int pullWindowDays = 90;

  // ── Lecture ──────────────────────────────────────────────────────────────

  SimpleSelectStatement<$LocalPomodoroSessionsTable, LocalPomodoroSession>
      _recentQuery(int limitDays) {
    final since = DateTime.now().subtract(Duration(days: limitDays));
    return _db.select(_db.localPomodoroSessions)
      ..where((t) =>
          t.userId.equals(_userId) & t.startedAt.isBiggerOrEqualValue(since))
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
  }

  @override
  Stream<List<PomodoroSession>> watchRecent({int limitDays = 90}) =>
      _recentQuery(limitDays)
          .watch()
          .map((rows) => rows.map(_toSession).toList());

  @override
  Future<List<PomodoroSession>> fetchRecent({int limitDays = 90}) async =>
      (await _recentQuery(limitDays).get()).map(_toSession).toList();

  // ── Écriture ─────────────────────────────────────────────────────────────

  @override
  Future<PomodoroSession> record({
    required DateTime startedAt,
    required int durationSeconds,
    String? taskId,
  }) async {
    final session = PomodoroSession(
      id: LocalFirstNoteRepository.newId(),
      userId: _userId,
      startedAt: startedAt,
      durationSeconds: durationSeconds,
      taskId: taskId,
    );

    await _db.transaction(() async {
      await _db.into(_db.localPomodoroSessions).insert(
            LocalPomodoroSessionsCompanion.insert(
              id: session.id,
              userId: _userId,
              startedAt: startedAt,
              durationSeconds: durationSeconds,
              taskId: Value(taskId),
            ),
          );
      await _queue.enqueue(table, session.id, 'upsert');
    });

    sync().catchError((_) {});
    return session;
  }

  // ── Synchronisation ──────────────────────────────────────────────────────

  late final SerialSync _serialSync = SerialSync(() async {
    await _queue.drain(table, _push);
    await _pull();
  });

  @override
  Future<void> sync() => _serialSync();

  Future<void> _push(SyncQueueEntry entry) async {
    final row = await (_db.select(_db.localPomodoroSessions)
          ..where((t) => t.id.equals(entry.entityId)))
        .getSingleOrNull();
    if (row == null) return;
    if (row.userId != _userId) throw const SkipEntry();

    final payload = {
      ..._toSession(row).toJson(),
      'id': row.id,
      'user_id': _userId,
    };

    try {
      await _client.from(table).upsert(payload);
    } on PostgrestException catch (error) {
      // 23503 : la tâche liée a été supprimée entre-temps. Le temps d'étude,
      // lui, reste acquis — même règle que le `on delete set null` serveur.
      if (error.code != '23503') rethrow;
      await _client.from(table).upsert({...payload, 'task_id': null});
    }

    await (_db.update(_db.localPomodoroSessions)
          ..where((t) => t.id.equals(row.id)))
        .write(const LocalPomodoroSessionsCompanion(isSynced: Value(true)));
  }

  Future<void> _pull() async {
    final since = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: pullWindowDays))
        .toIso8601String();

    final rows = await fetchAllPages(
      () => _client
          .from(table)
          .select()
          .eq('user_id', _userId)
          .gte('started_at', since),
    );

    // Les sessions sont immuables une fois terminées : un simple ajout de
    // celles qui manquent suffit, sans résolution de conflit.
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.localPomodoroSessions, [
        for (final row in rows)
          LocalPomodoroSessionsCompanion.insert(
            id: row['id'] as String,
            userId: _userId,
            startedAt: DateTime.parse(row['started_at'] as String).toLocal(),
            durationSeconds: (row['duration_seconds'] as num).toInt(),
            taskId: Value(row['task_id'] as String?),
            isSynced: const Value(true),
          ),
      ]);
    });
  }

  static PomodoroSession _toSession(LocalPomodoroSession row) =>
      PomodoroSession(
        id: row.id,
        userId: row.userId,
        startedAt: row.startedAt,
        durationSeconds: row.durationSeconds,
        taskId: row.taskId,
      );
}

final pomodoroRepositoryProvider = Provider<PomodoroRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return LocalFirstPomodoroRepository(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    userId: userId,
  );
});
