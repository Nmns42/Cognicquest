import 'package:cognicquest/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests d'intégration sur une vraie base SQLite en mémoire : ils valident le
/// schéma Drift et les contraintes, pas seulement la logique Dart.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Future<void> insertNote(String id, {String title = 'Fiche'}) async {
    final now = DateTime.now();
    await db.into(db.localNotes).insert(
          LocalNotesCompanion.insert(
            id: id,
            userId: 'u1',
            title: title,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  group('schéma', () {
    test('insère et relit une fiche avec ses valeurs par défaut', () async {
      await insertNote('n1', title: 'Mécanique');

      final note = await (db.select(db.localNotes)
            ..where((t) => t.id.equals('n1')))
          .getSingle();

      expect(note.title, 'Mécanique');
      expect(note.content, '');
      expect(note.tags, '[]');
      expect(note.importance, 1);
      expect(note.isDeleted, isFalse);
      // Une fiche fraîchement écrite localement n'est pas encore synchronisée.
      expect(note.isSynced, isFalse);
    });

    test('la suppression d\'une fiche emporte ses blocs', () async {
      await insertNote('n1');
      await db.into(db.localNoteBlocks).insert(
            LocalNoteBlocksCompanion.insert(
              id: 'b1',
              noteId: 'n1',
              type: 'todo',
              position: 0,
            ),
          );

      expect(await db.select(db.localNoteBlocks).get(), hasLength(1));

      await (db.delete(db.localNotes)..where((t) => t.id.equals('n1'))).go();

      // Vérifie que `PRAGMA foreign_keys = ON` est bien appliqué : sans lui,
      // SQLite laisserait des blocs orphelins.
      expect(await db.select(db.localNoteBlocks).get(), isEmpty);
    });

    test('refuse un bloc rattaché à une fiche inexistante', () async {
      expect(
        () => db.into(db.localNoteBlocks).insert(
              LocalNoteBlocksCompanion.insert(
                id: 'b1',
                noteId: 'fiche-fantome',
                type: 'todo',
                position: 0,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('insertOnConflictUpdate met à jour au lieu de dupliquer', () async {
      await insertNote('n1', title: 'Avant');

      final now = DateTime.now();
      await db.into(db.localNotes).insertOnConflictUpdate(
            LocalNotesCompanion.insert(
              id: 'n1',
              userId: 'u1',
              title: 'Après',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final notes = await db.select(db.localNotes).get();
      expect(notes, hasLength(1));
      expect(notes.single.title, 'Après');
    });
  });

  group('file de synchronisation', () {
    test('enregistre une intention d\'écriture', () async {
      await db.into(db.syncQueueEntries).insert(
            SyncQueueEntriesCompanion.insert(
              entityTable: 'notes',
              entityId: 'n1',
              operation: 'upsert',
              queuedAt: DateTime.now(),
            ),
          );

      final entries = await db.select(db.syncQueueEntries).get();
      expect(entries.single.entityId, 'n1');
      expect(entries.single.attempts, 0);
      expect(entries.single.lastError, isNull);
    });

    test('compte les tentatives et conserve la dernière erreur', () async {
      await db.into(db.syncQueueEntries).insert(
            SyncQueueEntriesCompanion.insert(
              entityTable: 'notes',
              entityId: 'n1',
              operation: 'upsert',
              queuedAt: DateTime.now(),
            ),
          );

      await (db.update(db.syncQueueEntries)
            ..where((t) => t.entityId.equals('n1')))
          .write(const SyncQueueEntriesCompanion(
        attempts: Value(2),
        lastError: Value('Pas de connexion internet.'),
      ));

      final entry = await db.select(db.syncQueueEntries).getSingle();
      expect(entry.attempts, 2);
      expect(entry.lastError, contains('connexion'));
    });
  });

  group('requêtes de lecture', () {
    test('exclut les fiches supprimées logiquement', () async {
      await insertNote('n1');
      await insertNote('n2');
      await (db.update(db.localNotes)..where((t) => t.id.equals('n2')))
          .write(const LocalNotesCompanion(isDeleted: Value(true)));

      final visible = await (db.select(db.localNotes)
            ..where((t) => t.userId.equals('u1') & t.isDeleted.equals(false)))
          .get();

      expect(visible.map((n) => n.id), ['n1']);
    });

    test('isole les fiches par utilisateur', () async {
      await insertNote('n1');
      final now = DateTime.now();
      await db.into(db.localNotes).insert(
            LocalNotesCompanion.insert(
              id: 'n2',
              userId: 'autre-utilisateur',
              title: 'Pas la mienne',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final mine = await (db.select(db.localNotes)
            ..where((t) => t.userId.equals('u1')))
          .get();

      expect(mine.map((n) => n.id), ['n1']);
    });
  });
}
