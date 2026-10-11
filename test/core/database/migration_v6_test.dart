import 'package:cognicquest/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Vérifie que la montée v5 → v6 (Lot 10, hors ligne) préserve les données.
void main() {
  late Database raw;

  setUp(() {
    raw = sqlite3.openInMemory();
  });

  tearDown(() => raw.close());

  test('conserve les données et crée les tables hors ligne', () async {
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

    // On simule une base restée en v5 : les tables du Lot 10 n'existent pas.
    raw.execute('DROP TABLE IF EXISTS local_tasks;');
    raw.execute('DROP TABLE IF EXISTS local_habit_logs;');
    raw.execute('DROP TABLE IF EXISTS local_habits;');
    raw.execute('DROP TABLE IF EXISTS local_pomodoro_sessions;');
    raw.execute('PRAGMA user_version = 5;');

    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    expect(await db.select(db.localNotes).get(), hasLength(1));
    expect(await db.select(db.localTasks).get(), isEmpty);
    expect(await db.select(db.localHabits).get(), isEmpty);
    expect(await db.select(db.localHabitLogs).get(), isEmpty);
    expect(await db.select(db.localPomodoroSessions).get(), isEmpty);
    expect(raw.userVersion, db.schemaVersion);
  });

  test('supprimer une habitude emporte ses jours cochés', () async {
    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    await db.into(db.localHabits).insert(
          LocalHabitsCompanion.insert(
            id: 'h1',
            userId: 'u1',
            name: 'Lecture',
            createdAt: DateTime.now(),
          ),
        );
    await db.into(db.localHabitLogs).insert(
          LocalHabitLogsCompanion.insert(habitId: 'h1', date: '2026-10-06'),
        );

    await (db.delete(db.localHabits)..where((t) => t.id.equals('h1'))).go();

    expect(await db.select(db.localHabitLogs).get(), isEmpty);
  });

  test('un même jour ne peut pas être coché deux fois', () async {
    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    await db.into(db.localHabits).insert(
          LocalHabitsCompanion.insert(
            id: 'h1',
            userId: 'u1',
            name: 'Sport',
            createdAt: DateTime.now(),
          ),
        );
    final log =
        LocalHabitLogsCompanion.insert(habitId: 'h1', date: '2026-10-06');
    await db.into(db.localHabitLogs).insert(log);

    expect(
      () => db.into(db.localHabitLogs).insert(log),
      throwsA(isA<SqliteException>()),
    );
  });
}
