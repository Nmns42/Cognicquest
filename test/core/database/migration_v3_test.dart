import 'package:cognicquest/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Vérifie que la montée v2 → v3 (Lot 6) préserve les données existantes.
void main() {
  late Database raw;
  late AppDatabase db;

  setUp(() {
    // Base au schéma v2 : fiches, blocs, liens, file de synchronisation.
    raw = sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE local_notes (
        id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL DEFAULT '',
        subject TEXT NULL,
        tags TEXT NOT NULL DEFAULT '[]',
        importance INTEGER NOT NULL DEFAULT 1,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id)
      );
    ''');
    raw.execute('''
      CREATE TABLE local_note_blocks (
        id TEXT NOT NULL,
        note_id TEXT NOT NULL REFERENCES local_notes (id) ON DELETE CASCADE,
        type TEXT NOT NULL,
        content TEXT NOT NULL DEFAULT '',
        is_checked INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL,
        PRIMARY KEY (id)
      );
    ''');
    raw.execute('''
      CREATE TABLE local_note_links (
        id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        source_id TEXT NOT NULL REFERENCES local_notes (id) ON DELETE CASCADE,
        target_id TEXT NOT NULL REFERENCES local_notes (id) ON DELETE CASCADE,
        type TEXT NOT NULL DEFAULT 'related',
        label TEXT NULL,
        created_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id),
        UNIQUE (source_id, target_id, type)
      );
    ''');
    raw.execute('''
      CREATE TABLE sync_queue_entries (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        entity_table TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        queued_at INTEGER NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT NULL
      );
    ''');

    final stamp = DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000;
    for (final id in ['n1', 'n2']) {
      raw.execute(
        "INSERT INTO local_notes (id, user_id, title, created_at, updated_at) "
        "VALUES ('$id', 'u1', 'Fiche $id', $stamp, $stamp);",
      );
    }
    raw.execute(
      "INSERT INTO local_note_links (id, user_id, source_id, target_id, created_at) "
      "VALUES ('l1', 'u1', 'n1', 'n2', $stamp);",
    );
    raw.execute('PRAGMA user_version = 2;');

    db = AppDatabase(NativeDatabase.opened(raw));
  });

  tearDown(() async => db.close());

  group('migration v2 → v3', () {
    test('conserve les fiches', () async {
      expect(await db.select(db.localNotes).get(), hasLength(2));
    });

    test('conserve les liens du graphe', () async {
      final links = await db.select(db.localNoteLinks).get();
      expect(links.single.sourceId, 'n1');
    });

    test('crée les quatre nouvelles tables', () async {
      expect(await db.select(db.localFlashcards).get(), isEmpty);
      expect(await db.select(db.localReviewLogs).get(), isEmpty);
      expect(await db.select(db.localSq3rSessions).get(), isEmpty);
      expect(await db.select(db.localExplanations).get(), isEmpty);
    });

    test('migre jusqu au niveau courant du schema', () async {
      await db.select(db.localNotes).get();
      // Comparé à `schemaVersion` : chaque nouveau lot relève cette valeur, et
      // une assertion en dur casserait au lot suivant.
      expect(raw.userVersion, db.schemaVersion);
    });
  });

  group('contraintes des cartes', () {
    Future<void> insertCard(String id, {String? noteId}) =>
        db.into(db.localFlashcards).insert(
              LocalFlashcardsCompanion.insert(
                id: id,
                userId: 'u1',
                noteId: Value(noteId),
                front: 'Question',
                back: 'Réponse',
                dueAt: DateTime.now(),
                createdAt: DateTime.now(),
              ),
            );

    test('accepte une carte sans fiche d\'origine', () async {
      await insertCard('c1');
      expect(await db.select(db.localFlashcards).get(), hasLength(1));
    });

    test('supprimer la fiche détache la carte sans la détruire', () async {
      await insertCard('c1', noteId: 'n1');
      await (db.delete(db.localNotes)..where((t) => t.id.equals('n1'))).go();

      final cards = await db.select(db.localFlashcards).get();
      // `setNull` et non `cascade` : l'historique de mémorisation survit.
      expect(cards, hasLength(1));
      expect(cards.single.noteId, isNull);
    });

    test('supprimer une carte emporte son historique de révision', () async {
      await insertCard('c1');
      await db.into(db.localReviewLogs).insert(
            LocalReviewLogsCompanion.insert(
              id: 'log1',
              userId: 'u1',
              cardId: 'c1',
              grade: 'good',
              intervalDays: 3,
              reviewedAt: DateTime.now(),
            ),
          );

      await (db.delete(db.localFlashcards)..where((t) => t.id.equals('c1'))).go();
      expect(await db.select(db.localReviewLogs).get(), isEmpty);
    });
  });

  group('contraintes SQ3R', () {
    Future<void> insertSession(String id, String noteId) =>
        db.into(db.localSq3rSessions).insert(
              LocalSq3rSessionsCompanion.insert(
                id: id,
                userId: 'u1',
                noteId: noteId,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

    test('refuse deux sessions pour la même fiche', () async {
      await insertSession('s1', 'n1');
      expect(() => insertSession('s2', 'n1'), throwsA(isA<SqliteException>()));
    });

    test('autorise une session par fiche distincte', () async {
      await insertSession('s1', 'n1');
      await insertSession('s2', 'n2');
      expect(await db.select(db.localSq3rSessions).get(), hasLength(2));
    });

    test('supprimer la fiche emporte sa session', () async {
      await insertSession('s1', 'n1');
      await (db.delete(db.localNotes)..where((t) => t.id.equals('n1'))).go();
      expect(await db.select(db.localSq3rSessions).get(), isEmpty);
    });
  });
}
