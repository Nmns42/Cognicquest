import 'package:cognicquest/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Montée v8 → v9 : compteur de révision des blocs (colonne + triggers).
void main() {
  late Database raw;

  setUp(() => raw = sqlite3.openInMemory());
  tearDown(() => raw.close());

  List<String> triggers() => [
        for (final row in raw.select(
            "SELECT name FROM sqlite_master WHERE type = 'trigger' ORDER BY name"))
          row['name'] as String,
      ];

  test('ajoute revision et les triggers sans perdre de données', () async {
    final seed =
        AppDatabase(NativeDatabase.opened(raw, closeUnderlyingOnClose: false));
    final now = DateTime.now();
    await seed.into(seed.localNotes).insert(LocalNotesCompanion.insert(
        id: 'n1', userId: 'u1', title: 'Fiche avant migration',
        content: const Value('corps'), createdAt: now, updatedAt: now,
        isSynced: const Value(true)));
    await seed.into(seed.localNoteBlocks).insert(
        LocalNoteBlocksCompanion.insert(
            id: 'b1', noteId: 'n1', type: 'paragraph',
            content: const Value('bloc'), position: 0));
    await seed.close();

    // Base restée en v8 : ni colonne revision, ni triggers.
    for (final name in triggers()) {
      raw.execute('DROP TRIGGER $name;');
    }
    raw.execute('ALTER TABLE local_notes DROP COLUMN revision;');
    raw.execute('PRAGMA user_version = 8;');

    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    final note = await db.select(db.localNotes).getSingle();
    expect(note.title, 'Fiche avant migration');
    expect(note.content, 'corps');
    expect(note.isSynced, isTrue);
    expect(note.revision, 0);
    expect((await db.select(db.localNoteBlocks).getSingle()).content, 'bloc');
    expect(triggers(), [
      'local_note_blocks_revision_delete',
      'local_note_blocks_revision_insert',
      'local_note_blocks_revision_update',
    ]);
    expect(raw.userVersion, db.schemaVersion);

    // Les triggers créés par la migration fonctionnent.
    await (db.delete(db.localNoteBlocks)..where((t) => t.id.equals('b1'))).go();
    expect((await db.select(db.localNotes).getSingle()).revision, 1);
  });

  test('la montée est rejouable (colonne et triggers déjà présents)',
      () async {
    final seed =
        AppDatabase(NativeDatabase.opened(raw, closeUnderlyingOnClose: false));
    await seed.select(seed.localNotes).get();
    await seed.close();

    raw.execute('PRAGMA user_version = 8;');
    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    await db.select(db.localNotes).get();
    expect(raw.userVersion, db.schemaVersion);
    expect(triggers(), hasLength(3));
  });
}
