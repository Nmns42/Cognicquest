import 'package:cognicquest/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Vérifie que la montée de schéma v1 → v2 (Lot 5) **préserve les données**.
///
/// C'est le risque principal du lot : une base déjà installée chez
/// l'utilisateur perdrait ses fiches si la nouvelle table était introduite
/// sans migration.
void main() {
  group('migration v1 → v2', () {
    late Database raw;
    late AppDatabase db;

    setUp(() {
      // On fabrique à la main une base au schéma v1 : les fiches et les blocs
      // existent, la table des liens non.
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
      raw.execute(
        "INSERT INTO local_notes (id, user_id, title, created_at, updated_at) "
        "VALUES ('n1', 'u1', 'Fiche avant migration', $stamp, $stamp);",
      );
      raw.execute(
        "INSERT INTO local_note_blocks (id, note_id, type, content, position) "
        "VALUES ('b1', 'n1', 'todo', 'Réviser', 0);",
      );
      raw.execute('PRAGMA user_version = 1;');

      db = AppDatabase(NativeDatabase.opened(raw));
    });

    tearDown(() async => db.close());

    test('conserve les fiches existantes', () async {
      final notes = await db.select(db.localNotes).get();

      expect(notes, hasLength(1));
      expect(notes.single.title, 'Fiche avant migration');
    });

    test('conserve les blocs existants', () async {
      final blocks = await db.select(db.localNoteBlocks).get();

      expect(blocks, hasLength(1));
      expect(blocks.single.content, 'Réviser');
    });

    test('crée la table des liens', () async {
      final links = await db.select(db.localNoteLinks).get();
      expect(links, isEmpty);
    });

    test('migre jusqu au niveau courant du schema', () async {
      // Force l'ouverture avant de lire la version.
      await db.select(db.localNotes).get();
      // Comparé à `schemaVersion` et non à un nombre en dur : une base v1
      // doit rattraper toutes les montées, pas seulement la suivante.
      expect(raw.userVersion, db.schemaVersion);
    });

    test('la nouvelle table accepte un lien entre fiches existantes', () async {
      final stamp = DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000;
      raw.execute(
        "INSERT INTO local_notes (id, user_id, title, created_at, updated_at) "
        "VALUES ('n2', 'u1', 'Deuxième', $stamp, $stamp);",
      );

      await db.into(db.localNoteLinks).insert(
            LocalNoteLinksCompanion.insert(
              id: 'l1',
              userId: 'u1',
              sourceId: 'n1',
              targetId: 'n2',
              createdAt: DateTime.now(),
            ),
          );

      final links = await db.select(db.localNoteLinks).get();
      expect(links.single.sourceId, 'n1');
      expect(links.single.type, 'related');
    });
  });

  group('contraintes de la table des liens', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.now();
      for (final id in ['n1', 'n2']) {
        await db.into(db.localNotes).insert(
              LocalNotesCompanion.insert(
                id: id,
                userId: 'u1',
                title: id,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });

    tearDown(() async => db.close());

    Future<void> insertLink(String id, {String type = 'related'}) =>
        db.into(db.localNoteLinks).insert(
              LocalNoteLinksCompanion.insert(
                id: id,
                userId: 'u1',
                sourceId: 'n1',
                targetId: 'n2',
                type: Value(type),
                createdAt: DateTime.now(),
              ),
            );

    test('refuse deux fois la même arête', () async {
      await insertLink('l1');
      expect(() => insertLink('l2'), throwsA(isA<SqliteException>()));
    });

    test('autorise deux types différents entre les mêmes fiches', () async {
      await insertLink('l1');
      await insertLink('l2', type: 'to_review');

      expect(await db.select(db.localNoteLinks).get(), hasLength(2));
    });

    test('supprimer une fiche emporte ses liens', () async {
      await insertLink('l1');
      await (db.delete(db.localNotes)..where((t) => t.id.equals('n1'))).go();

      expect(await db.select(db.localNoteLinks).get(), isEmpty);
    });

    test('refuse un lien vers une fiche inexistante', () async {
      expect(
        () => db.into(db.localNoteLinks).insert(
              LocalNoteLinksCompanion.insert(
                id: 'l1',
                userId: 'u1',
                sourceId: 'n1',
                targetId: 'fantome',
                createdAt: DateTime.now(),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
