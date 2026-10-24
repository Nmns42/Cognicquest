import 'package:cognicquest/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Montée complète v1 → version courante : une base installée avec la toute
/// première version doit aboutir **exactement** au schéma d'une installation
/// neuve (mêmes tables, colonnes, index et triggers), sans perdre ses fiches.
///
/// Les tests `migration_v*_test.dart` couvrent chaque palier ; celui-ci
/// détecte un palier oublié ou une colonne créée différemment.
void main() {
  /// Schéma v1 (Lot 4) : fiches, blocs et file de synchronisation.
  Database v1() {
    final raw = sqlite3.openInMemory();
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
      "VALUES ('n1', 'u1', 'Fiche v1', $stamp, $stamp);",
    );
    raw.execute(
      "INSERT INTO local_note_blocks (id, note_id, type, content, position) "
      "VALUES ('b1', 'n1', 'text', 'Contenu v1', 0);",
    );
    raw.execute('PRAGMA user_version = 1;');
    return raw;
  }

  /// Description comparable du schéma : colonnes (nom, type, non nul, clé)
  /// de chaque table, noms des index et des triggers. Les valeurs par
  /// défaut ne sont pas comparées : SQLite les garde telles qu'écrites, et
  /// un `ALTER TABLE ADD COLUMN` peut les formuler autrement.
  Future<Map<String, Object>> shape(AppDatabase db) async {
    final objects = await db
        .customSelect("SELECT type, name FROM sqlite_master "
            "WHERE name NOT LIKE 'sqlite_%' ORDER BY name")
        .get();
    final result = <String, Object>{};
    for (final row in objects) {
      final type = row.read<String>('type');
      final name = row.read<String>('name');
      if (type == 'table') {
        final columns = await db
            .customSelect("SELECT name, type, \"notnull\", pk "
                "FROM pragma_table_info('$name') ORDER BY name")
            .map((c) =>
                '${c.read<String>('name')} ${c.read<String>('type')} '
                'nn=${c.read<int>('notnull')} pk=${c.read<int>('pk')}')
            .get();
        result['table $name'] = columns;
      } else {
        result['$type $name'] = true;
      }
    }
    return result;
  }

  test('v1 → courante : même schéma qu\'une installation neuve', () async {
    final fresh = AppDatabase(NativeDatabase.memory());
    final migrated = AppDatabase(NativeDatabase.opened(v1()));
    addTearDown(fresh.close);
    addTearDown(migrated.close);

    final expected = await shape(fresh);
    final actual = await shape(migrated);

    expect(actual.keys.toSet(), expected.keys.toSet());
    for (final key in expected.keys) {
      expect(actual[key], expected[key], reason: key);
    }
    final version = await migrated
        .customSelect('PRAGMA user_version')
        .map((r) => r.read<int>('user_version'))
        .getSingle();
    expect(version, migrated.schemaVersion);
  });

  test('v1 → courante : les fiches et leurs blocs sont conservés', () async {
    final migrated = AppDatabase(NativeDatabase.opened(v1()));
    addTearDown(migrated.close);

    final note = await migrated.select(migrated.localNotes).getSingle();
    expect(note.title, 'Fiche v1');
    expect(note.folderId, isNull);
    final block = await migrated.select(migrated.localNoteBlocks).getSingle();
    expect(block.content, 'Contenu v1');

    // Les tables arrivées plus tard sont utilisables tout de suite.
    await migrated.into(migrated.syncRowVersions).insert(
          SyncRowVersionsCompanion.insert(
            remoteTable: 'notes',
            entityId: 'n1',
            serverUpdatedAt: '2030-01-01T00:00:00Z',
          ),
        );
    expect(await migrated.select(migrated.localMediaCache).get(), isEmpty);
  });
}
