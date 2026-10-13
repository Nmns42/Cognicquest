import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/incremental_pull.dart';
import '../../../core/database/sync_queue.dart';
import '../../../shared/models/note_link_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/data/note_repository.dart';

abstract interface class NoteLinkRepository {
  Stream<List<NoteLink>> watchAll();

  Future<void> link({
    required String sourceId,
    required String targetId,
    required NoteLinkType type,
    String? label,
  });

  Future<void> unlink(String linkId);
  Future<void> sync();
}

/// Même patron local-first que les fiches : SQLite d'abord, file de
/// synchronisation ensuite.
class LocalFirstNoteLinkRepository implements NoteLinkRepository {
  LocalFirstNoteLinkRepository({
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

  static const String _table = 'note_links';

  @override
  Stream<List<NoteLink>> watchAll() {
    final query = _db.select(_db.localNoteLinks)
      ..where((t) => t.userId.equals(_userId) & t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.watch().map((rows) => rows.map(_toLink).toList());
  }

  @override
  Future<void> link({
    required String sourceId,
    required String targetId,
    required NoteLinkType type,
    String? label,
  }) async {
    // Une fiche ne se relie pas à elle-même : l'arête n'apprendrait rien et
    // fausserait le calcul des degrés.
    if (sourceId == targetId) return;

    final existing = await _findEquivalent(sourceId, targetId, type);
    if (existing != null) return;

    await _db.transaction(() async {
      final id = LocalFirstNoteRepository.newId();
      await _db.into(_db.localNoteLinks).insert(
            LocalNoteLinksCompanion.insert(
              id: id,
              userId: _userId,
              sourceId: sourceId,
              targetId: targetId,
              type: Value(type.value),
              label: Value(label),
              createdAt: DateTime.now(),
            ),
          );
      await _enqueue(id, 'upsert');
    });

    _syncQuietly();
  }

  /// Cherche une arête équivalente, en tenant compte du sens pour les
  /// relations non orientées : « A lié à B » et « B lié à A » sont la même.
  Future<LocalNoteLink?> _findEquivalent(
    String sourceId,
    String targetId,
    NoteLinkType type,
  ) async {
    final rows = await (_db.select(_db.localNoteLinks)
          ..where((t) => t.userId.equals(_userId) & t.isDeleted.equals(false)))
        .get();

    for (final row in rows) {
      if (row.type != type.value) continue;
      if (row.sourceId == sourceId && row.targetId == targetId) return row;
      if (!type.isDirected &&
          row.sourceId == targetId &&
          row.targetId == sourceId) {
        return row;
      }
    }
    return null;
  }

  @override
  Future<void> unlink(String linkId) async {
    await _db.transaction(() async {
      await (_db.update(_db.localNoteLinks)..where((t) => t.id.equals(linkId)))
          .write(const LocalNoteLinksCompanion(
        isDeleted: Value(true),
        isSynced: Value(false),
      ));
      await _enqueue(linkId, 'delete');
    });

    _syncQuietly();
  }

  Future<void> _enqueue(String entityId, String operation) async {
    await (_db.delete(_db.syncQueueEntries)
          ..where((t) =>
              t.entityTable.equals(_table) & t.entityId.equals(entityId)))
        .go();

    await _db.into(_db.syncQueueEntries).insert(
          SyncQueueEntriesCompanion.insert(
            entityTable: _table,
            entityId: entityId,
            operation: operation,
            queuedAt: DateTime.now(),
          ),
        );
  }

  void _syncQuietly() {
    sync().catchError((_) {});
  }

  @override
  Future<void> sync() async {
    if (!_syncEnabled) return;
    await _pushQueue();
    await _pullRemote();
  }

  Future<void> _pushQueue() async {
    await SyncQueue(_db).drain(_table, (entry) async {
      if (entry.operation == 'delete') {
        await _client.from(_table).delete().eq('id', entry.entityId);
        await (_db.delete(_db.localNoteLinks)
              ..where((t) => t.id.equals(entry.entityId)))
            .go();
      } else {
        final row = await (_db.select(_db.localNoteLinks)
              ..where((t) => t.id.equals(entry.entityId)))
            .getSingleOrNull();
        if (row != null) {
          await _client.from(_table).upsert({
            'id': row.id,
            'user_id': row.userId,
            'source_id': row.sourceId,
            'target_id': row.targetId,
            'type': row.type,
            'label': row.label,
            'created_at': row.createdAt.toUtc().toIso8601String(),
          });
          await (_db.update(_db.localNoteLinks)
                ..where((t) => t.id.equals(row.id)))
              .write(const LocalNoteLinksCompanion(isSynced: Value(true)));
        }
      }
    });
  }

  late final PullCursors _cursors = PullCursors(_db, _userId);

  Future<void> _pullRemote() async {
    final delta = await fetchDelta(
      rows: () => _client.from(_table).select().eq('user_id', _userId),
      ids: () => _client.from(_table).select('id').eq('user_id', _userId),
      since: await _cursors.read(_table),
    );

    // Les fiches référencées doivent exister localement, sinon la contrainte
    // de clé étrangère rejette l'insertion.
    final knownNotes = (await (_db.select(_db.localNotes)
              ..where((t) => t.userId.equals(_userId)))
            .get())
        .map((n) => n.id)
        .toSet();

    await _db.transaction(() async {
      // Un lien créé ou supprimé localement et pas encore envoyé n'est jamais
      // écrasé par la version distante.
      final pending = await SyncQueue(_db).pendingIds(_table);
      var skippedUnknownNote = false;

      for (final row in delta.changed) {
        if (pending.contains(row['id'] as String)) continue;
        final sourceId = row['source_id'] as String;
        final targetId = row['target_id'] as String;
        if (!knownNotes.contains(sourceId) || !knownNotes.contains(targetId)) {
          skippedUnknownNote = true;
          continue;
        }

        await _db.into(_db.localNoteLinks).insertOnConflictUpdate(
              LocalNoteLinksCompanion.insert(
                id: row['id'] as String,
                userId: _userId,
                sourceId: sourceId,
                targetId: targetId,
                type: Value(row['type'] as String? ?? 'related'),
                label: Value(row['label'] as String?),
                createdAt:
                    DateTime.parse(row['created_at'] as String).toLocal(),
                isSynced: const Value(true),
              ),
            );
      }

      // Lien synchronisé absent du serveur : supprimé depuis un autre
      // appareil. Ce cas n'était pas traité.
      await (_db.delete(_db.localNoteLinks)
            ..where((t) =>
                t.userId.equals(_userId) &
                t.isSynced.equals(true) &
                t.id.isNotIn(delta.remoteIds!) &
                t.id.isNotIn(pending)))
          .go();

      // Un lien écarté faute de fiche locale doit être retenté au prochain
      // pull : avancer le curseur l'aurait fait oublier pour toujours.
      if (!skippedUnknownNote) await _cursors.write(_table, delta.cursor);
    });
  }

  static NoteLink _toLink(LocalNoteLink row) => NoteLink(
        id: row.id,
        userId: row.userId,
        sourceId: row.sourceId,
        targetId: row.targetId,
        type: NoteLinkType.fromValue(row.type),
        label: row.label,
        createdAt: row.createdAt,
        isSynced: row.isSynced,
      );
}

final noteLinkRepositoryProvider = Provider<NoteLinkRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  return LocalFirstNoteLinkRepository(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    userId: userId,
    syncEnabled: ref.watch(currentUserProvider) != null,
  );
});
