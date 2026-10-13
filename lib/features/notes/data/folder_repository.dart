import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/sync_queue.dart';
import '../../auth/providers/auth_provider.dart';
import 'note_repository.dart';

/// Dossier de l'explorateur de fiches et de cartes.
class Folder {
  const Folder({
    required this.id,
    required this.name,
    this.parentId,
    this.position,
  });

  final String id;
  final String name;

  /// `null` : dossier racine.
  final String? parentId;
  final String? position;

  @override
  bool operator ==(Object other) =>
      other is Folder &&
      other.id == id &&
      other.name == name &&
      other.parentId == parentId &&
      other.position == position;

  @override
  int get hashCode => Object.hash(id, name, parentId, position);
}

/// Dossiers en **local-first**, comme le reste : SQLite d'abord, Supabase
/// ensuite. Ranger une fiche ou une carte la renvoie au serveur avec son
/// nouveau `folder_id`.
class LocalFirstFolderRepository {
  LocalFirstFolderRepository({
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

  /// `false` sans vraie session (mode `DEV_BYPASS_AUTH`) : tout reste local.
  final bool _syncEnabled;

  late final SyncQueue _queue = SyncQueue(_db);

  static const String table = 'folders';
  static const String notesTable = 'notes';
  static const String cardsTable = 'flashcards';

  Stream<List<Folder>> watchAll() => (_db.select(_db.localFolders)
        ..where((t) => t.userId.equals(_userId))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch()
      .map((rows) => rows.map(_toFolder).toList());

  Future<Folder> create(String name, {String? parentId}) async {
    final folder = Folder(
      id: LocalFirstNoteRepository.newId(),
      name: _clean(name),
      parentId: parentId,
    );
    await _db.transaction(() async {
      await _db.into(_db.localFolders).insert(LocalFoldersCompanion.insert(
            id: folder.id,
            userId: _userId,
            parentId: Value(parentId),
            name: folder.name,
            createdAt: DateTime.now(),
          ));
      await _queue.enqueue(table, folder.id, 'upsert');
    });
    _syncQuietly();
    return folder;
  }

  Future<void> rename(String id, String name) async {
    await _db.transaction(() async {
      await (_db.update(_db.localFolders)..where((t) => t.id.equals(id)))
          .write(LocalFoldersCompanion(
              name: Value(_clean(name)), isSynced: const Value(false)));
      await _queue.enqueue(table, id, 'upsert');
    });
    _syncQuietly();
  }

  /// Déplace un dossier sous [parentId] (`null` : à la racine). Refusé s'il
  /// irait sous lui-même ou sous l'un de ses descendants.
  Future<bool> move(String id, String? parentId) async {
    if (parentId != null) {
      final subtree = await _subtree(id);
      if (subtree.contains(parentId)) return false;
    }
    await _db.transaction(() async {
      await (_db.update(_db.localFolders)..where((t) => t.id.equals(id)))
          .write(LocalFoldersCompanion(
              parentId: Value(parentId), isSynced: const Value(false)));
      await _queue.enqueue(table, id, 'upsert');
    });
    _syncQuietly();
    return true;
  }

  /// Supprime un dossier et ses sous-dossiers. Les fiches et les cartes
  /// qu'ils contenaient reviennent à la racine, jamais supprimées (même
  /// règle que le serveur : `on delete set null`).
  Future<void> delete(String id) async {
    final subtree = await _subtree(id);
    await _db.transaction(() async {
      await (_db.update(_db.localNotes)
            ..where((t) => t.folderId.isIn(subtree)))
          .write(const LocalNotesCompanion(folderId: Value(null)));
      await (_db.update(_db.localFlashcards)
            ..where((t) => t.folderId.isIn(subtree)))
          .write(const LocalFlashcardsCompanion(folderId: Value(null)));
      await (_db.delete(_db.localFolders)..where((t) => t.id.isIn(subtree)))
          .go();
      // Les sous-dossiers partent avec le parent côté serveur (cascade) :
      // seule la suppression du dossier visé est envoyée.
      for (final child in subtree.where((f) => f != id)) {
        await _queue.remove(table, child);
      }
      await _queue.enqueue(table, id, 'delete');
    });
    _syncQuietly();
  }

  /// Range une fiche dans [folderId] (`null` : à la racine). La fiche repart
  /// au serveur par sa propre file, avec son nouveau dossier.
  Future<void> moveNote(String noteId, String? folderId) async {
    await _db.transaction(() async {
      await (_db.update(_db.localNotes)..where((t) => t.id.equals(noteId)))
          .write(LocalNotesCompanion(
              folderId: Value(folderId), isSynced: const Value(false)));
      await _queue.enqueue(notesTable, noteId, 'upsert');
    });
  }

  /// Range une carte dans [folderId] (`null` : à la racine).
  Future<void> moveCard(String cardId, String? folderId) async {
    await _db.transaction(() async {
      await (_db.update(_db.localFlashcards)
            ..where((t) => t.id.equals(cardId)))
          .write(LocalFlashcardsCompanion(
              folderId: Value(folderId), isSynced: const Value(false)));
      await _queue.enqueue(cardsTable, cardId, 'upsert');
    });
  }

  /// Le dossier et tous ses descendants.
  Future<Set<String>> _subtree(String id) async {
    final rows = await (_db.select(_db.localFolders)
          ..where((t) => t.userId.equals(_userId)))
        .get();
    final children = <String?, List<String>>{};
    for (final row in rows) {
      children.putIfAbsent(row.parentId, () => []).add(row.id);
    }
    final result = <String>{};
    final stack = [id];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (!result.add(current)) continue;
      stack.addAll(children[current] ?? const []);
    }
    return result;
  }

  void _syncQuietly() {
    sync().catchError((_) {});
  }

  Future<void> sync() async {
    if (!_syncEnabled) return;
    await _serialSync();
  }

  late final SerialSync _serialSync = SerialSync(() async {
    await _queue.drain(table, _push);
    await _pull();
  });

  Future<void> _push(SyncQueueEntry entry) async {
    if (entry.operation == 'delete') {
      await _client.from(table).delete().eq('id', entry.entityId);
      return;
    }
    final row = await (_db.select(_db.localFolders)
          ..where((t) => t.id.equals(entry.entityId)))
        .getSingleOrNull();
    if (row == null) return;
    await _client.from(table).upsert({
      'id': row.id,
      'user_id': row.userId,
      'parent_id': row.parentId,
      'name': row.name,
      'position': row.position,
      'created_at': row.createdAt.toUtc().toIso8601String(),
    });
    await (_db.update(_db.localFolders)..where((t) => t.id.equals(row.id)))
        .write(const LocalFoldersCompanion(isSynced: Value(true)));
  }

  /// Les dossiers sont peu nombreux : on rapatrie la liste entière.
  Future<void> _pull() async {
    final remote = await _client.from(table).select().eq('user_id', _userId);
    await _db.transaction(() async {
      final pending = await _queue.pendingIds(table);
      final remoteIds = <String>[];
      for (final row in remote) {
        final id = row['id'] as String;
        remoteIds.add(id);
        if (pending.contains(id)) continue;
        await _db.into(_db.localFolders).insertOnConflictUpdate(
              LocalFoldersCompanion.insert(
                id: id,
                userId: _userId,
                parentId: Value(row['parent_id'] as String?),
                name: row['name'] as String? ?? 'Dossier',
                position: Value(row['position'] as String?),
                createdAt:
                    DateTime.parse(row['created_at'] as String).toLocal(),
                isSynced: const Value(true),
              ),
            );
      }
      // Dossier synchronisé disparu du serveur : supprimé ailleurs.
      await (_db.delete(_db.localFolders)
            ..where((t) =>
                t.userId.equals(_userId) &
                t.isSynced.equals(true) &
                t.id.isNotIn(remoteIds) &
                t.id.isNotIn(pending)))
          .go();
    });
  }

  static String _clean(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Nouveau dossier';
    return trimmed.length > 120 ? trimmed.substring(0, 120) : trimmed;
  }

  static Folder _toFolder(LocalFolder row) => Folder(
        id: row.id,
        name: row.name,
        parentId: row.parentId,
        position: row.position,
      );
}

final folderRepositoryProvider =
    Provider<LocalFirstFolderRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return LocalFirstFolderRepository(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    userId: userId,
    syncEnabled: ref.watch(currentUserProvider) != null,
  );
});

final foldersProvider = StreamProvider<List<Folder>>((ref) {
  final repository = ref.watch(folderRepositoryProvider);
  if (repository == null) return Stream.value(const []);
  return repository.watchAll();
});
