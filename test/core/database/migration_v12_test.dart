import 'package:cognicquest/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Montée v11 → v12 : préférences hors ligne (LocalPreferences).
void main() {
  late Database raw;

  setUp(() => raw = sqlite3.openInMemory());
  tearDown(() => raw.close());

  test('crée local_preferences sans toucher aux données', () async {
    final seed =
        AppDatabase(NativeDatabase.opened(raw, closeUnderlyingOnClose: false));
    final now = DateTime.now();
    await seed.into(seed.localNotes).insert(LocalNotesCompanion.insert(
        id: 'n1', userId: 'u1', title: 'Fiche avant migration',
        createdAt: now, updatedAt: now));
    await seed.close();

    raw.execute('DROP TABLE local_preferences;');
    raw.execute('PRAGMA user_version = 11;');

    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    expect((await db.select(db.localNotes).getSingle()).title,
        'Fiche avant migration');
    expect(await db.select(db.localPreferences).get(), isEmpty);
    expect(raw.userVersion, db.schemaVersion);
  });

  test('la montée est rejouable (table déjà présente)', () async {
    final seed =
        AppDatabase(NativeDatabase.opened(raw, closeUnderlyingOnClose: false));
    await seed.select(seed.localPreferences).get();
    await seed.close();

    raw.execute('PRAGMA user_version = 11;');
    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);
    await db.select(db.localPreferences).get();
    expect(raw.userVersion, db.schemaVersion);
  });
}
