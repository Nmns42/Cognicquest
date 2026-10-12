import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/incremental_pull.dart';
import '../../../core/database/remote_pagination.dart';
import '../../../core/database/sync_queue.dart';
import '../../../core/ordering/manual_order.dart';
import '../../../shared/models/habit_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/data/note_repository.dart';

abstract interface class HabitRepository {
  /// Flux des habitudes locales, avec leurs jours cochés.
  Stream<List<Habit>> watchAll();

  Future<Habit> create(
      {required String name, required HabitFrequency frequency});
  Future<void> update(Habit habit);
  Future<void> delete(String id);

  /// Enregistre des clés d'ordre manuel (cf. `ManualOrder.planMove`). Une
  /// écriture par habitude concernée — une seule lors d'un déplacement
  /// courant.
  Future<void> applyPositions(List<KeyUpdate> updates);
  Future<void> setCompletion(String habitId, DateTime day,
      {required bool done});

  /// Pousse la file d'attente puis rapatrie les changements distants.
  Future<void> sync();
}

/// Implémentation **local-first** des habitudes (Lot 10).
///
/// Un jour coché est identifié dans la file par `habitId|yyyy-MM-dd` : c'est
/// la clé naturelle de `habit_logs`, ce qui évite d'inventer un identifiant
/// que le serveur ne connaîtrait pas.
class LocalFirstHabitRepository implements HabitRepository {
  LocalFirstHabitRepository({
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

  static const String habitsTable = 'habits';
  static const String logsTable = 'habit_logs';

  static String logKey(String habitId, String dateKey) => '$habitId|$dateKey';

  // ── Lecture ──────────────────────────────────────────────────────────────

  @override
  Stream<List<Habit>> watchAll() {
    final habitsQuery = _db.select(_db.localHabits)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

    final logsQuery = _db.select(_db.localHabitLogs).join([
      innerJoin(
        _db.localHabits,
        _db.localHabits.id.equalsExp(_db.localHabitLogs.habitId),
      ),
    ])
      ..where(_db.localHabits.userId.equals(_userId));

    // On observe la jointure plutôt que la seule table des habitudes : Drift
    // la réémet alors aussi quand un jour est coché, ce qui ne touche que
    // `local_habit_logs`. La liste des habitudes est relue à chaque émission
    // pour inclure celles qui n'ont encore aucun jour coché.
    return logsQuery.watch().asyncMap((logRows) async {
      final completions = <String, List<String>>{};
      for (final row in logRows) {
        final log = row.readTable(_db.localHabitLogs);
        completions.putIfAbsent(log.habitId, () => []).add(log.date);
      }
      final habits = await habitsQuery.get();
      return Habit.manualOrder([
        for (final habit in habits) _toHabit(habit, completions[habit.id]),
      ]);
    });
  }

  // ── Écriture ─────────────────────────────────────────────────────────────

  @override
  Future<Habit> create({
    required String name,
    required HabitFrequency frequency,
  }) async {
    final habit = Habit(
      id: LocalFirstNoteRepository.newId(),
      userId: _userId,
      name: name,
      createdAt: DateTime.now(),
      frequency: frequency,
      completedDates: const [],
    );
    await _db.transaction(() async {
      await _db.into(_db.localHabits).insert(
            LocalHabitsCompanion.insert(
              id: habit.id,
              userId: _userId,
              name: habit.name,
              frequency: Value(habit.frequency.value),
              createdAt: habit.createdAt,
            ),
          );
      await _queue.enqueue(habitsTable, habit.id, 'upsert');
    });
    _syncQuietly();
    return habit;
  }

  @override
  Future<void> applyPositions(List<KeyUpdate> updates) async {
    if (updates.isEmpty) return;
    await _db.transaction(() async {
      final pending = await _queue.pendingIds(habitsTable);
      for (final update in updates) {
        await (_db.update(_db.localHabits)
              ..where((t) => t.id.equals(update.id) & t.userId.equals(_userId)))
            .write(LocalHabitsCompanion(position: Value(update.key)));
        // Envoi léger de la seule position ; une sauvegarde ou une
        // suppression déjà en file l'emporte.
        if (!pending.contains(update.id)) {
          await _queue.enqueue(habitsTable, update.id, 'position');
        }
      }
    });
    _syncQuietly();
  }

  @override
  Future<void> update(Habit habit) async {
    await _db.transaction(() async {
      await (_db.update(_db.localHabits)..where((t) => t.id.equals(habit.id)))
          .write(
        LocalHabitsCompanion(
          name: Value(habit.name),
          frequency: Value(habit.frequency.value),
          isSynced: const Value(false),
        ),
      );
      await _queue.enqueue(habitsTable, habit.id, 'upsert');
    });
    _syncQuietly();
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      final logs = await (_db.select(_db.localHabitLogs)
            ..where((t) => t.habitId.equals(id)))
          .get();
      // Les jours cochés en attente n'ont plus lieu d'être envoyés : le
      // serveur les supprimera en cascade, et les pousser après la
      // suppression de l'habitude violerait la clé étrangère.
      for (final log in logs) {
        await _queue.remove(logsTable, logKey(id, log.date));
      }
      await (_db.delete(_db.localHabits)..where((t) => t.id.equals(id))).go();
      await _queue.enqueue(habitsTable, id, 'delete');
    });
    _syncQuietly();
  }

  @override
  Future<void> setCompletion(
    String habitId,
    DateTime day, {
    required bool done,
  }) async {
    final dateKey = Habit.toDateKey(day);
    await _db.transaction(() async {
      if (done) {
        await _db.into(_db.localHabitLogs).insertOnConflictUpdate(
              LocalHabitLogsCompanion.insert(habitId: habitId, date: dateKey),
            );
      } else {
        await (_db.delete(_db.localHabitLogs)
              ..where(
                  (t) => t.habitId.equals(habitId) & t.date.equals(dateKey)))
            .go();
      }
      await _queue.enqueue(
        logsTable,
        logKey(habitId, dateKey),
        done ? 'upsert' : 'delete',
      );
    });
    _syncQuietly();
  }

  void _syncQuietly() {
    sync().catchError((_) {});
  }

  // ── Synchronisation ──────────────────────────────────────────────────────

  late final SerialSync _serialSync = SerialSync(() async {
    // Les habitudes d'abord : un jour coché référence son habitude.
    await _queue.drain(habitsTable, _pushHabit);
    await _queue.drain(logsTable, _pushLog);
    await _pull();
  });

  @override
  Future<void> sync() => _serialSync();

  Future<void> _pushHabit(SyncQueueEntry entry) async {
    if (entry.operation == 'delete') {
      await _client.from(habitsTable).delete().eq('id', entry.entityId);
      return;
    }

    final row = await (_db.select(_db.localHabits)
          ..where((t) => t.id.equals(entry.entityId)))
        .getSingleOrNull();
    if (row == null) return;
    if (row.userId != _userId) throw const SkipEntry();

    if (entry.operation == 'position') {
      // Une seule colonne : déplacer une habitude ne renvoie rien d'autre.
      await _client
          .from(habitsTable)
          .update({'position': row.position}).eq('id', row.id);
      return;
    }

    await _client.from(habitsTable).upsert({
      'id': row.id,
      'user_id': _userId,
      'name': row.name,
      'frequency': row.frequency,
      'created_at': row.createdAt.toUtc().toIso8601String(),
      'position': row.position,
    });
    await (_db.update(_db.localHabits)..where((t) => t.id.equals(row.id)))
        .write(const LocalHabitsCompanion(isSynced: Value(true)));
  }

  Future<void> _pushLog(SyncQueueEntry entry) async {
    final separator = entry.entityId.lastIndexOf('|');
    final habitId = entry.entityId.substring(0, separator);
    final dateKey = entry.entityId.substring(separator + 1);

    final habit = await (_db.select(_db.localHabits)
          ..where((t) => t.id.equals(habitId)))
        .getSingleOrNull();
    if (habit != null && habit.userId != _userId) throw const SkipEntry();

    if (entry.operation == 'delete') {
      await _client
          .from(logsTable)
          .delete()
          .eq('habit_id', habitId)
          .eq('date', dateKey);
    } else {
      // `upsert` plutôt que `insert` : un jour déjà coché depuis un autre
      // appareil ne viole pas la contrainte d'unicité (habit_id, date).
      await _client.from(logsTable).upsert(
        {'habit_id': habitId, 'date': dateKey},
        onConflict: 'habit_id,date',
      );
    }
  }

  late final PullCursors _cursors = PullCursors(_db, _userId);

  Future<void> _pull() async {
    // Habitudes : incrémental. Jours cochés : toujours en entier — deux
    // colonnes par ligne, et c'est la seule façon de voir un jour décoché.
    final delta = await fetchDelta(
      rows: () => _client.from(habitsTable).select().eq('user_id', _userId),
      ids: () => _client.from(habitsTable).select('id').eq('user_id', _userId),
      since: await _cursors.read(habitsTable),
    );
    final habitIds = delta.remoteIds!.toList();
    final logRows = habitIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await fetchAllPagesIn(
            () => _client.from(logsTable).select('habit_id, date'),
            column: 'habit_id',
            ids: habitIds,
          );

    await _db.transaction(() async {
      final pendingHabits = await _queue.pendingIds(habitsTable);
      final pendingLogs = await _queue.pendingIds(logsTable);

      for (final remote in delta.changed) {
        final id = remote['id'] as String;
        if (pendingHabits.contains(id)) continue;
        await _db.into(_db.localHabits).insertOnConflictUpdate(
              LocalHabitsCompanion.insert(
                id: id,
                userId: _userId,
                name: remote['name'] as String,
                frequency: Value(remote['frequency'] as String? ?? 'daily'),
                createdAt:
                    DateTime.parse(remote['created_at'] as String).toLocal(),
                position: Value(remote['position'] as String?),
                isSynced: const Value(true),
              ),
            );
      }

      // Habitude synchronisée absente du serveur : supprimée ailleurs. Ses
      // jours cochés partent avec, par cascade.
      await (_db.delete(_db.localHabits)
            ..where((t) =>
                t.userId.equals(_userId) &
                t.isSynced.equals(true) &
                t.id.isNotIn(habitIds) &
                t.id.isNotIn(pendingHabits)))
          .go();

      // Jours cochés : on aligne l'ensemble local sur l'ensemble distant, sauf
      // pour ceux qui ont une modification locale en attente.
      final remoteKeys = <String>{
        for (final log in logRows)
          logKey(
            log['habit_id'] as String,
            // Postgres renvoie un `date` sous la forme 'yyyy-MM-dd' ; on
            // tronque par sécurité si la colonne évoluait vers un timestamp.
            (log['date'] as String).split('T').first,
          ),
      };

      final localLogs = await (_db.select(_db.localHabitLogs).join([
        innerJoin(
          _db.localHabits,
          _db.localHabits.id.equalsExp(_db.localHabitLogs.habitId),
        ),
      ])
            ..where(_db.localHabits.userId.equals(_userId)))
          .map((row) => row.readTable(_db.localHabitLogs))
          .get();
      final localKeys = {
        for (final log in localLogs) logKey(log.habitId, log.date),
      };

      for (final log in localLogs) {
        final key = logKey(log.habitId, log.date);
        if (remoteKeys.contains(key) ||
            pendingLogs.contains(key) ||
            pendingHabits.contains(log.habitId)) {
          continue;
        }
        await (_db.delete(_db.localHabitLogs)
              ..where((t) =>
                  t.habitId.equals(log.habitId) & t.date.equals(log.date)))
            .go();
      }

      // Le pull étant incrémental, une habitude inchangée n'est pas réinsérée
      // ci-dessus : on vérifie qu'elle existe localement plutôt que de laisser
      // la clé étrangère faire échouer toute la transaction.
      final knownHabits = {
        for (final habit in await (_db.select(_db.localHabits)
              ..where((t) => t.userId.equals(_userId)))
            .get())
          habit.id,
      };

      for (final key in remoteKeys.difference(localKeys)) {
        if (pendingLogs.contains(key)) continue;
        final separator = key.lastIndexOf('|');
        final habitId = key.substring(0, separator);
        if (pendingHabits.contains(habitId) || !knownHabits.contains(habitId)) {
          continue;
        }
        await _db.into(_db.localHabitLogs).insertOnConflictUpdate(
              LocalHabitLogsCompanion.insert(
                habitId: habitId,
                date: key.substring(separator + 1),
              ),
            );
      }

      await _cursors.write(habitsTable, delta.cursor);
    });
  }

  static Habit _toHabit(LocalHabit row, List<String>? completions) => Habit(
        id: row.id,
        userId: row.userId,
        name: row.name,
        createdAt: row.createdAt,
        frequency: HabitFrequency.fromValue(row.frequency),
        completedDates: completions ?? const [],
        position: row.position,
      );
}

final habitRepositoryProvider = Provider<HabitRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return LocalFirstHabitRepository(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    userId: userId,
  );
});
