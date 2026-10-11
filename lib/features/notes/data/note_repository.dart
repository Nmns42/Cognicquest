import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/incremental_pull.dart';
import '../../../core/database/remote_pagination.dart';
import '../../../core/database/sync_queue.dart';
import '../../../core/errors/data_failure.dart';
import '../../../shared/models/note_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Contrat de persistance des fiches.
abstract interface class NoteRepository {
  /// Flux des fiches locales : l'UI se met à jour dès l'écriture SQLite, sans
  /// attendre le réseau.
  Stream<List<Note>> watchAll();

  Future<Note> create({String title, String? subject});
  Future<void> save(Note note);
  Future<void> delete(String id);

  /// Pousse la file d'attente vers Supabase et récupère les changements
  /// distants. Sans réseau, échoue silencieusement : la file est conservée.
  Future<void> sync();
}

/// Implémentation **local-first** : SQLite est la source de vérité, Supabase
/// la copie de sauvegarde synchronisée.
///
/// C'est la réponse à la dette « offline » signalée depuis le Lot 2 : les
/// écritures n'attendent jamais le réseau, et une coupure ne perd rien.
class LocalFirstNoteRepository implements NoteRepository {
  LocalFirstNoteRepository({
    required AppDatabase database,
    required SupabaseClient client,
    required String userId,
  })  : _db = database,
        _client = client,
        _userId = userId;

  final AppDatabase _db;
  final SupabaseClient _client;
  final String _userId;

  static const String _notesTable = 'notes';
  static const String _blocksTable = 'note_blocks';

  /// Générateur cryptographique (crypto.getRandomValues sur le web) : les
  /// identifiants servent de clés primaires côté serveur, ils ne doivent pas
  /// être prévisibles à partir de ceux déjà vus. `Random()` est un
  /// générateur pseudo-aléatoire non cryptographique.
  static final _random = Random.secure();

  /// Identifiant unique généré côté client, au format UUID v4.
  ///
  /// Indispensable au mode hors ligne : une fiche créée sans réseau doit déjà
  /// porter son identifiant définitif, sinon il faudrait réécrire toutes ses
  /// références à la synchronisation.
  static String newId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant RFC 4122
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  // ── Lecture ──────────────────────────────────────────────────────────────

  /// Blocs déjà chargés, par fiche, avec la révision à laquelle ils ont été
  /// lus (cf. [LocalNotes.revision]).
  final Map<String, (int, List<NoteBlock>)> _blockCache = {};

  /// Nombre total de blocs lus en base par [watchAll] depuis la création du
  /// repository. Sert uniquement aux tests et aux mesures.
  @visibleForTesting
  int blocksLoaded = 0;

  /// Fiches dont les blocs sont en cache. Sert uniquement aux tests.
  @visibleForTesting
  Iterable<String> get cachedNoteIds => _blockCache.keys;

  @override
  Stream<List<Note>> watchAll() {
    final notesQuery = _db.select(_db.localNotes)
      ..where((t) => t.userId.equals(_userId) & t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

    // Chaque émission de la liste (une sauvegarde, un pull…) rechargeait les
    // blocs de toutes les fiches. Seules celles dont la révision a bougé sont
    // désormais relues ; les autres viennent du cache.
    return notesQuery.watch().asyncMap((rows) async {
      final ids = {for (final row in rows) row.id};
      // Fiche supprimée (ou sortie de la liste) : elle quitte le cache.
      _blockCache.removeWhere((id, _) => !ids.contains(id));

      final stale = [
        for (final row in rows)
          if (_blockCache[row.id]?.$1 != row.revision) row.id,
      ];
      if (stale.isNotEmpty) await _loadBlocks(stale);

      return rows
          .map((row) => _toNote(row, _blockCache[row.id]?.$2 ?? const []))
          .toList();
    });
  }

  /// Relit les blocs de [noteIds] et les met en cache.
  ///
  /// La révision est relue **dans la même transaction** que les blocs : lue
  /// avant (dans l'émission), une sauvegarde intercalée aurait figé dans le
  /// cache un contenu plus récent sous une révision périmée — sans gravité —
  /// ou, lue après, un contenu périmé sous une révision à jour, qui ne serait
  /// plus jamais relu.
  Future<void> _loadBlocks(List<String> noteIds) => _db.transaction(() async {
        final revisions = {
          for (final row in await (_db.select(_db.localNotes)
                ..where((t) => t.id.isIn(noteIds)))
              .get())
            row.id: row.revision,
        };
        final blockRows = await (_db.select(_db.localNoteBlocks)
              ..where((t) => t.noteId.isIn(noteIds))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
        blocksLoaded += blockRows.length;

        // Regroupés en mémoire : une requête par fiche ferait un N+1.
        final blocksByNote = <String, List<NoteBlock>>{};
        for (final row in blockRows) {
          blocksByNote.putIfAbsent(row.noteId, () => []).add(_toBlock(row));
        }
        for (final id in noteIds) {
          final revision = revisions[id];
          if (revision == null) continue; // supprimée entre-temps
          _blockCache[id] = (revision, blocksByNote[id] ?? const []);
        }
      });

  // ── Écriture ─────────────────────────────────────────────────────────────

  @override
  Future<Note> create({String title = '', String? subject}) async {
    final now = DateTime.now();
    final note = Note(
      id: newId(),
      userId: _userId,
      title: title,
      content: '',
      subject: subject,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    await save(note);
    return note;
  }

  @override
  Future<void> save(Note note) async {
    final stamped = note.copyWith(updatedAt: DateTime.now(), isSynced: false);

    await _db.transaction(() async {
      await _db.into(_db.localNotes).insertOnConflictUpdate(
            LocalNotesCompanion.insert(
              id: stamped.id,
              userId: _userId,
              title: stamped.title,
              content: Value(stamped.content),
              subject: Value(stamped.subject),
              tags: Value(Note.encodeTags(stamped.tags)),
              importance: Value(stamped.importance),
              isFavorite: Value(stamped.isFavorite),
              isArchived: Value(stamped.isArchived),
              createdAt: stamped.createdAt,
              updatedAt: stamped.updatedAt,
              isSynced: const Value(false),
            ),
          );

      // Les blocs sont remplacés en bloc : diffuser un diff coûterait plus
      // cher que la réécriture, à ce volume.
      await (_db.delete(_db.localNoteBlocks)
            ..where((t) => t.noteId.equals(stamped.id)))
          .go();

      for (var i = 0; i < stamped.blocks.length; i++) {
        final block = stamped.blocks[i];
        await _db.into(_db.localNoteBlocks).insert(
              LocalNoteBlocksCompanion.insert(
                id: block.id,
                noteId: stamped.id,
                type: block.type.value,
                content: Value(block.content),
                isChecked: Value(block.isChecked),
                position: i,
              ),
            );
      }

      await _enqueue(stamped.id, 'upsert');
    });

    unawaitedSync();
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      // Suppression logique : la fiche doit survivre localement jusqu'à ce que
      // la suppression ait été propagée au serveur.
      await (_db.update(_db.localNotes)..where((t) => t.id.equals(id))).write(
        LocalNotesCompanion(
          isDeleted: const Value(true),
          isSynced: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _enqueue(id, 'delete');
    });

    unawaitedSync();
  }

  Future<void> _enqueue(String entityId, String operation) async {
    // Une seule entrée en attente par fiche : dix modifications successives
    // hors ligne ne doivent pas produire dix envois.
    await (_db.delete(_db.syncQueueEntries)
          ..where((t) =>
              t.entityTable.equals(_notesTable) & t.entityId.equals(entityId)))
        .go();

    await _db.into(_db.syncQueueEntries).insert(
          SyncQueueEntriesCompanion.insert(
            entityTable: _notesTable,
            entityId: entityId,
            operation: operation,
            queuedAt: DateTime.now(),
          ),
        );
  }

  /// Déclenche une synchronisation sans bloquer l'appelant ni propager
  /// l'erreur : l'écriture locale, elle, a déjà réussi.
  void unawaitedSync() {
    sync().catchError((_) {});
  }

  // ── Synchronisation ──────────────────────────────────────────────────────

  /// Sérialisée : chaque `save` déclenche un envoi, et deux synchronisations
  /// concurrentes poussaient les mêmes fiches puis se disputaient le pull.
  late final SerialSync _serialSync = SerialSync(() async {
    await _pushQueue();
    await _pullRemote();
  });

  @override
  Future<void> sync() => _serialSync();

  Future<void> _pushQueue() async {
    final pending = await (_db.select(_db.syncQueueEntries)
          ..where((t) => t.entityTable.equals(_notesTable))
          ..orderBy([(t) => OrderingTerm.asc(t.queuedAt)]))
        .get();

    for (final entry in pending) {
      try {
        if (entry.operation == 'delete') {
          await _client.from(_notesTable).delete().eq('id', entry.entityId);
          await (_db.delete(_db.localNotes)
                ..where((t) => t.id.equals(entry.entityId)))
              .go();
        } else {
          final row = await (_db.select(_db.localNotes)
                ..where((t) => t.id.equals(entry.entityId)))
              .getSingleOrNull();
          if (row == null) {
            await _dequeue(entry.id);
            continue;
          }

          final blocks = await (_db.select(_db.localNoteBlocks)
                ..where((t) => t.noteId.equals(row.id))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();

          // `updated_at` est posé par le serveur (trigger) : on relit sa
          // valeur pour que les comparaisons du pull se fassent entre deux
          // heures serveur, jamais avec l'horloge de cet appareil.
          final saved = await _client
              .from(_notesTable)
              .upsert(_toRemoteJson(row))
              .select('updated_at')
              .single();
          final serverUpdatedAt =
              DateTime.parse(saved['updated_at'] as String).toLocal();

          await _client.from(_blocksTable).delete().eq('note_id', row.id);
          if (blocks.isNotEmpty) {
            await _client.from(_blocksTable).insert([
              for (final block in blocks)
                {
                  'id': block.id,
                  'note_id': block.noteId,
                  'type': block.type,
                  'content': block.content,
                  'is_checked': block.isChecked,
                  'position': block.position,
                },
            ]);
          }

          // Conditionnel : une modification faite pendant l'envoi a changé
          // `updatedAt` et remis une entrée en file ; elle ne doit pas être
          // marquée synchronisée.
          await (_db.update(_db.localNotes)
                ..where((t) =>
                    t.id.equals(row.id) & t.updatedAt.equals(row.updatedAt)))
              .write(LocalNotesCompanion(
                isSynced: const Value(true),
                updatedAt: Value(serverUpdatedAt),
              ));
        }

        await _dequeue(entry.id);
      } catch (error) {
        // On conserve l'entrée et on note l'échec : la prochaine tentative
        // reprendra là où on s'est arrêté.
        await (_db.update(_db.syncQueueEntries)
              ..where((t) => t.id.equals(entry.id)))
            .write(
          SyncQueueEntriesCompanion(
            attempts: Value(entry.attempts + 1),
            lastError: Value(DataFailure.from(error).message),
          ),
        );
        rethrow;
      }
    }
  }

  Future<void> _dequeue(int id) =>
      (_db.delete(_db.syncQueueEntries)..where((t) => t.id.equals(id))).go();

  late final PullCursors _cursors = PullCursors(_db, _userId);

  Future<void> _pullRemote() async {
    // Incrémental : seules les fiches modifiées depuis le dernier pull
    // reviennent, avec leurs blocs. Auparavant, tout le carnet (contenu et
    // blocs compris) était retéléchargé toutes les 5 minutes.
    final delta = await fetchDelta(
      rows: () => _client.from(_notesTable).select().eq('user_id', _userId),
      ids: () => _client.from(_notesTable).select('id').eq('user_id', _userId),
      since: await _cursors.read(_notesTable),
    );
    final remoteNotes = delta.changed;
    final remoteIds = delta.remoteIds!;
    // Pas de retour anticipé sur une liste vide : toutes les fiches ont pu
    // être supprimées depuis un autre appareil, et la purge plus bas doit
    // quand même avoir lieu.

    final ids = remoteNotes.map((r) => r['id'] as String).toList();
    final remoteBlocks = await fetchAllPagesIn(
      () => _client.from(_blocksTable).select(),
      column: 'note_id',
      ids: ids,
    );

    final blocksByNote = <String, List<Map<String, dynamic>>>{};
    for (final block in remoteBlocks) {
      blocksByNote.putIfAbsent(block['note_id'] as String, () => []).add(block);
    }

    await _db.transaction(() async {
      // Relu dans la transaction : une écriture survenue pendant la requête
      // réseau ne doit pas être écrasée.
      final pending = await SyncQueue(_db).pendingIds(_notesTable);

      for (final remote in remoteNotes) {
        final id = remote['id'] as String;

        // Résolution de conflit : une modification locale pas encore envoyée
        // gagne toujours, elle partira au prochain push (même règle que les
        // tâches). Sinon, la copie locale synchronisée est exactement ce que
        // le serveur avait : la version reçue, modifiée depuis, la remplace.
        //
        // Pas de comparaison de dates : Drift stocke les `DateTime` à la
        // seconde, une heure serveur (microsecondes) paraissait donc toujours
        // plus récente que sa propre copie locale.
        if (pending.contains(id)) continue;

        final local = await (_db.select(_db.localNotes)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (local != null && !local.isSynced) continue;
        final remoteUpdatedAt =
            DateTime.parse(remote['updated_at'] as String).toLocal();

        await _db.into(_db.localNotes).insertOnConflictUpdate(
              LocalNotesCompanion.insert(
                id: id,
                userId: _userId,
                title: remote['title'] as String? ?? '',
                content: Value(remote['content'] as String? ?? ''),
                subject: Value(remote['subject'] as String?),
                tags: Value(Note.encodeTags(Note.decodeTags(remote['tags']))),
                importance: Value((remote['importance'] as num?)?.toInt() ?? 1),
                isFavorite: Value(remote['is_favorite'] as bool? ?? false),
                isArchived: Value(remote['is_archived'] as bool? ?? false),
                createdAt:
                    DateTime.parse(remote['created_at'] as String).toLocal(),
                updatedAt: remoteUpdatedAt,
                isSynced: const Value(true),
              ),
            );

        await (_db.delete(_db.localNoteBlocks)
              ..where((t) => t.noteId.equals(id)))
            .go();

        for (final block in blocksByNote[id] ?? const []) {
          await _db.into(_db.localNoteBlocks).insert(
                LocalNoteBlocksCompanion.insert(
                  id: block['id'] as String,
                  noteId: id,
                  type: block['type'] as String,
                  content: Value(block['content'] as String? ?? ''),
                  isChecked: Value(block['is_checked'] as bool? ?? false),
                  position: (block['position'] as num?)?.toInt() ?? 0,
                ),
              );
        }
      }

      // Une fiche déjà synchronisée qui a disparu du serveur a été supprimée
      // depuis un autre appareil. Ce cas n'était jamais traité : la fiche
      // restait indéfiniment sur cet appareil. Les blocs, liens et sessions
      // suivent par les clés étrangères locales (cascade / set null), comme
      // côté serveur.
      await (_db.delete(_db.localNotes)
            ..where((t) =>
                t.userId.equals(_userId) &
                t.isSynced.equals(true) &
                t.id.isNotIn(remoteIds) &
                t.id.isNotIn(pending)))
          .go();

      await _cursors.write(_notesTable, delta.cursor);
    });
  }

  Map<String, dynamic> _toRemoteJson(LocalNote row) => {
        'id': row.id,
        'user_id': row.userId,
        'title': row.title,
        'content': row.content,
        'subject': row.subject,
        'tags': Note.decodeTags(row.tags),
        'importance': row.importance,
        'is_favorite': row.isFavorite,
        'is_archived': row.isArchived,
        'created_at': row.createdAt.toUtc().toIso8601String(),
        // Pas d'`updated_at` : le serveur le pose lui-même (trigger).
      };

  static Note _toNote(LocalNote row, List<NoteBlock> blocks) => Note(
        id: row.id,
        userId: row.userId,
        title: row.title,
        content: row.content,
        subject: row.subject,
        tags: Note.decodeTags(row.tags),
        importance: row.importance,
        isFavorite: row.isFavorite,
        isArchived: row.isArchived,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        blocks: blocks,
        isSynced: row.isSynced,
      );

  static NoteBlock _toBlock(LocalNoteBlock row) => NoteBlock(
        id: row.id,
        noteId: row.noteId,
        type: NoteBlockType.fromValue(row.type),
        content: row.content,
        position: row.position,
        isChecked: row.isChecked,
      );
}

final noteRepositoryProvider = Provider<NoteRepository?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  return LocalFirstNoteRepository(
    database: ref.watch(appDatabaseProvider),
    client: ref.watch(supabaseClientProvider),
    userId: userId,
  );
});
