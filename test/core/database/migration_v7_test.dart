import 'package:cognicquest/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Vérifie que la montée v6 → v7 (curseurs du pull incrémental) préserve les
/// données.
void main() {
  late Database raw;

  setUp(() {
    raw = sqlite3.openInMemory();
  });

  tearDown(() => raw.close());

  test('conserve les données et crée la table des curseurs', () async {
    final seed =
        AppDatabase(NativeDatabase.opened(raw, closeUnderlyingOnClose: false));
    final now = DateTime.now();
    await seed.into(seed.localNotes).insert(
          LocalNotesCompanion.insert(
            id: 'n1',
            userId: 'u1',
            title: 'Fiche avant migration',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await seed.close();

    // On simule une base restée en v6 : la table des curseurs n'existe pas.
    raw.execute('DROP TABLE IF EXISTS sync_cursors;');
    raw.execute('PRAGMA user_version = 6;');

    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    final notes = await db.select(db.localNotes).get();
    expect(notes.single.title, 'Fiche avant migration');

    // Sans curseur, le premier pull après mise à jour est complet.
    expect(await db.select(db.syncCursors).get(), isEmpty);
    await db.into(db.syncCursors).insert(
          SyncCursorsCompanion.insert(
            userId: 'u1',
            remoteTable: 'notes',
            pulledUntil: '2030-01-01T12:00:00.123456Z',
          ),
        );
    final cursor = await db.select(db.syncCursors).getSingle();
    // Stocké en texte : la précision à la microseconde est conservée.
    expect(cursor.pulledUntil, '2030-01-01T12:00:00.123456Z');
  });
}
