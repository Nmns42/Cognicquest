import 'package:cognicquest/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Montée v9 → v10 : clé d'ordre manuel des fiches (LocalNotes.position).
void main() {
  late Database raw;

  setUp(() => raw = sqlite3.openInMemory());
  tearDown(() => raw.close());

  test('ajoute position sans perdre de données ni changer l\'ordre', () async {
    final seed =
        AppDatabase(NativeDatabase.opened(raw, closeUnderlyingOnClose: false));
    final now = DateTime.now();
    await seed.into(seed.localNotes).insert(LocalNotesCompanion.insert(
        id: 'n1', userId: 'u1', title: 'Fiche avant migration',
        content: const Value('corps'), createdAt: now, updatedAt: now));
    await seed.close();

    raw.execute('ALTER TABLE local_notes DROP COLUMN position;');
    raw.execute('PRAGMA user_version = 9;');

    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    final note = await db.select(db.localNotes).getSingle();
    expect(note.title, 'Fiche avant migration');
    expect(note.content, 'corps');
    // Aucune clé posée : la fiche garde l'ordre habituel.
    expect(note.position, isNull);
    expect(raw.userVersion, db.schemaVersion);
  });

  test('la montée est rejouable (colonne déjà présente)', () async {
    final seed =
        AppDatabase(NativeDatabase.opened(raw, closeUnderlyingOnClose: false));
    await seed.select(seed.localNotes).get();
    await seed.close();

    raw.execute('PRAGMA user_version = 9;');
    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);
    await db.select(db.localNotes).get();
    expect(raw.userVersion, db.schemaVersion);
  });
}
