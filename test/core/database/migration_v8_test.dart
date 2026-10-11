import 'package:cognicquest/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Montée v7 → v8 : index sur les filtres et tris des écrans et de la
/// synchronisation.
void main() {
  late Database raw;

  setUp(() {
    raw = sqlite3.openInMemory();
  });

  tearDown(() => raw.close());

  List<String> appIndexes() => [
        for (final row in raw.select(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name NOT LIKE 'sqlite_autoindex%' ORDER BY name",
        ))
          row['name'] as String,
      ];

  test('crée les index sans toucher aux données', () async {
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
    final expected = appIndexes();
    await seed.close();
    expect(expected, hasLength(27));

    // On simule une base restée en v7 : aucun des index n'existe.
    for (final name in expected) {
      raw.execute('DROP INDEX $name;');
    }
    raw.execute('PRAGMA user_version = 7;');
    expect(appIndexes(), isEmpty);

    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    expect((await db.select(db.localNotes).get()).single.title,
        'Fiche avant migration');
    expect(appIndexes(), expected);
    expect(raw.userVersion, db.schemaVersion);
  });

  group('les requêtes chaudes utilisent un index', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.opened(raw)));
    tearDown(() => db.close());

    Future<String> plan(String sql) async {
      final rows = await db
          .customSelect('EXPLAIN QUERY PLAN $sql',
              variables: [Variable.withString('u1')])
          .get();
      return rows.map((r) => r.read<String>('detail')).join(' | ');
    }

    test('liste des fiches', () async {
      expect(
        await plan('SELECT * FROM local_notes WHERE user_id = ? '
            'AND is_deleted = 0 ORDER BY updated_at DESC'),
        contains('local_notes_user_updated'),
      );
    });

    test('cartes à réviser', () async {
      expect(
        await plan('SELECT * FROM local_flashcards WHERE user_id = ? '
            'AND is_deleted = 0 ORDER BY due_at'),
        contains('local_flashcards_user_due'),
      );
    });

    test('tableau Kanban', () async {
      expect(
        await plan('SELECT * FROM local_tasks WHERE user_id = ? '
            'ORDER BY position, created_at'),
        contains('local_tasks_user_position'),
      );
    });

    test('file de synchronisation', () async {
      expect(
        await plan('SELECT * FROM sync_queue_entries '
            "WHERE entity_table = 'notes' AND entity_id = ?"),
        contains('sync_queue_entries_entity'),
      );
    });
  });
}
