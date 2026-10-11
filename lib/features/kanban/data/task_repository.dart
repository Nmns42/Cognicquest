import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/incremental_pull.dart';
import '../../../core/database/sync_queue.dart';
import '../../../shared/models/task_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/data/note_repository.dart';

/// Contrat de persistance des tâches.
///
/// Les providers ne connaissent que cette interface : c'est ce qui a permis de
/// passer du tout-Supabase au local-first (Lot 10) sans toucher aux pages.
abstract interface class TaskRepository {
  /// Flux des tâches locales : l'UI suit SQLite, y compris les changements
  /// rapatriés par une synchronisation en arrière-plan.
  Stream<List<Task>> watchAll();

  Future<Task> create(Task task);
  Future<void> update(Task task);
  Future<void> delete(String id);

  /// Réordonne / déplace en lot après un glisser-déposer.
  Future<void> saveOrder(List<Task> tasks);

  /// Pousse la file d'attente puis rapatrie les changements distants. Hors
  /// ligne, échoue sans rien perdre : la file est conservée.
  Future<void> sync();
}

/// Implémentation **local-first** : SQLite est la source de vérité, Supabase
/// la copie synchronisée — même architecture que les fiches (Lot 4).
class LocalFirstTaskRepository implements TaskRepository {
  LocalFirstTaskRepository({
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

  static const String table = 'tasks';

  // ── Lecture ──────────────────────────────────────────────────────────────

  @override
  Stream<List<Task>> watchAll() {
    final query = _db.select(_db.localTasks)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.position),
        (t) => OrderingTerm.asc(t.createdAt),
      ]);
    return query.watch().map((rows) => rows.map(_toTask).toList());
  }

  // ── Écriture ─────────────────────────────────────────────────────────────

  @override
  Future<Task> create(Task task) async {
    // Identifiant généré côté client : une tâche créée hors ligne a déjà son
    // identité définitive, rien à remapper à la synchronisation.
    final created = Task(
      id: LocalFirstNoteRepository.newId(),
      userId: _userId,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      createdAt: task.createdAt,
      dueDate: task.dueDate,
      isUrgent: task.isUrgent,
      isImportant: task.isImportant,
      position: task.position,
    );
    await _write([created]);
    return created;
  }

  @override
  Future<void> update(Task task) => _write([task]);

  @override
  Future<void> saveOrder(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    await _write(tasks);
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.localTasks)..where((t) => t.id.equals(id))).go();
      await _queue.enqueue(table, id, 'delete');
    });
    _syncQuietly();
  }

  Future<void> _write(List<Task> tasks) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      for (final task in tasks) {
        await _db.into(_db.localTasks).insertOnConflictUpdate(
              LocalTasksCompanion.insert(
                id: task.id,
                userId: _userId,
                title: task.title,
                description: Value(task.description),
                status: Value(task.status.value),
                priority: Value(task.priority.value),
                dueDate: Value(task.dueDate),
                isUrgent: Value(task.isUrgent),
                isImportant: Value(task.isImportant),
                position: Value(task.position),
                createdAt: task.createdAt,
                updatedAt: now,
                isSynced: const Value(false),
              ),
            );
        await _queue.enqueue(table, task.id, 'upsert');
      }
    });
    _syncQuietly();
  }

  /// L'écriture locale a déjà réussi : l'envoi se fait en arrière-plan et son
  /// échec éventuel est rattrapé par le [SyncCoordinator].
  void _syncQuietly() {
    sync().catchError((_) {});
  }

  // ── Synchronisation ──────────────────────────────────────────────────────

  late final SerialSync _serialSync = SerialSync(() async {
    await _queue.drain(table, _push);
    await _pull();
  });

  @override
  Future<void> sync() => _serialSync();

  Future<void> _push(SyncQueueEntry entry) async {
    if (entry.operation == 'delete') {
      await _client.from(table).delete().eq('id', entry.entityId);
      return;
    }

    final row = await (_db.select(_db.localTasks)
          ..where((t) => t.id.equals(entry.entityId)))
        .getSingleOrNull();
    if (row == null) return;
    if (row.userId != _userId) throw const SkipEntry();

    await _client.from(table).upsert({
      ..._toTask(row).toJson(),
      'id': row.id,
      'user_id': _userId,
      'created_at': row.createdAt.toUtc().toIso8601String(),
    });
    await (_db.update(_db.localTasks)..where((t) => t.id.equals(row.id)))
        .write(const LocalTasksCompanion(isSynced: Value(true)));
  }

  late final PullCursors _cursors = PullCursors(_db, _userId);

  Future<void> _pull() async {
    // Incrémental : seules les tâches modifiées depuis le dernier pull
    // reviennent en entier, plus la liste légère des identifiants pour
    // repérer les suppressions.
    final delta = await fetchDelta(
      rows: () => _client.from(table).select().eq('user_id', _userId),
      ids: () => _client.from(table).select('id').eq('user_id', _userId),
      since: await _cursors.read(table),
    );
    final remoteIds = delta.remoteIds!;

    await _db.transaction(() async {
      // Relu dans la transaction : une écriture survenue pendant la requête
      // réseau ne doit pas être écrasée.
      final pending = await _queue.pendingIds(table);

      for (final remote in delta.changed) {
        final task = Task.fromJson(remote);
        if (pending.contains(task.id)) continue;

        await _db.into(_db.localTasks).insertOnConflictUpdate(
              LocalTasksCompanion.insert(
                id: task.id,
                userId: _userId,
                title: task.title,
                description: Value(task.description),
                status: Value(task.status.value),
                priority: Value(task.priority.value),
                dueDate: Value(task.dueDate),
                isUrgent: Value(task.isUrgent),
                isImportant: Value(task.isImportant),
                position: Value(task.position),
                createdAt: task.createdAt.toLocal(),
                updatedAt: remote['updated_at'] == null
                    ? DateTime.now()
                    : DateTime.parse(remote['updated_at'] as String).toLocal(),
                isSynced: const Value(true),
              ),
            );
      }

      // Une tâche déjà synchronisée qui a disparu du serveur a été supprimée
      // depuis un autre appareil.
      await (_db.delete(_db.localTasks)
            ..where((t) =>
                t.userId.equals(_userId) &
                t.isSynced.equals(true) &
                t.id.isNotIn(remoteIds) &
                t.id.isNotIn(pending)))
          .go();

      await _cursors.write(table, delta.cursor);
    });
  }

  static Task _toTask(LocalTask row) => Task(
        id: row.id,
        userId: row.userId,
        title: row.title,
        description: row.description,
        status: TaskStatus.fromValue(row.status),
        priority: TaskPriority.fromValue(row.priority),
        createdAt: row.createdAt,
        dueDate: row.dueDate,
        isUrgent: row.isUrgent,
        isImportant: row.isImportant,
        position: row.position,
      );
}

/// Repository courant, lié à l'utilisateur connecté.
///
/// Vaut `null` tant qu'aucune session n'est ouverte (y compris sous
/// `DEV_BYPASS_AUTH`) : les providers savent alors qu'il n'y a rien à charger
/// plutôt que d'échouer sur un `user_id` nul, ce qui était le bug du Lot 0.
final taskRepositoryProvider = Provider<TaskRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return LocalFirstTaskRepository(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    userId: userId,
  );
});
