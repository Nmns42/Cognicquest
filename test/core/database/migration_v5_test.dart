import 'package:cognicquest/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Vérifie que la montée v4 → v5 (Lot 8) préserve les données existantes.
void main() {
  late Database raw;

  Future<void> seedV4() async {
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
    await seed.into(seed.localJournalEntries).insert(
          LocalJournalEntriesCompanion.insert(
            id: 'j1',
            userId: 'u1',
            createdAt: now,
          ),
        );
    await seed.close();

    // On simule une base restée en v4 : les tables du Lot 8 n'existent pas.
    raw.execute('DROP TABLE IF EXISTS local_study_goals;');
    raw.execute('DROP TABLE IF EXISTS local_plan_items;');
    raw.execute('DROP TABLE IF EXISTS local_speed_samples;');
    raw.execute('DROP TABLE IF EXISTS local_exam_targets;');
    raw.execute('PRAGMA user_version = 4;');
  }

  setUp(() {
    raw = sqlite3.openInMemory();
  });

  tearDown(() => raw.close());

  group('migration v4 → v5', () {
    test('conserve les données et crée les tables du Lot 8', () async {
      await seedV4();

      final db = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      expect(await db.select(db.localNotes).get(), hasLength(1));
      expect(await db.select(db.localJournalEntries).get(), hasLength(1));

      expect(await db.select(db.localStudyGoals).get(), isEmpty);
      expect(await db.select(db.localPlanItems).get(), isEmpty);
      expect(await db.select(db.localSpeedSamples).get(), isEmpty);
      expect(await db.select(db.localExamTargets).get(), isEmpty);

      expect(raw.userVersion, db.schemaVersion);
    });
  });

  group('contraintes du Lot 8', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.opened(raw));
      final now = DateTime.now();
      await db.into(db.localNotes).insert(
            LocalNotesCompanion.insert(
              id: 'n1',
              userId: 'u1',
              title: 'Fiche',
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    tearDown(() async => db.close());

    Future<void> insertGoal(String id) => db.into(db.localStudyGoals).insert(
          LocalStudyGoalsCompanion.insert(
            id: id,
            userId: 'u1',
            title: 'Objectif',
            createdAt: DateTime.now(),
          ),
        );

    Future<void> insertItem(String id, {String? goalId, String? dependsOn}) =>
        db.into(db.localPlanItems).insert(
              LocalPlanItemsCompanion.insert(
                id: id,
                userId: 'u1',
                title: 'Étape $id',
                startDate: DateTime.now(),
                endDate: DateTime.now().add(const Duration(days: 2)),
                goalId: Value(goalId),
                dependsOnId: Value(dependsOn),
                createdAt: DateTime.now(),
              ),
            );

    test('supprimer un objectif détache ses étapes sans les détruire', () async {
      await insertGoal('g1');
      await insertItem('p1', goalId: 'g1');

      await (db.delete(db.localStudyGoals)..where((t) => t.id.equals('g1')))
          .go();

      final items = await db.select(db.localPlanItems).get();
      expect(items, hasLength(1));
      expect(items.single.goalId, isNull);
    });

    test('une cible d\'examen survit à la suppression de sa fiche', () async {
      await db.into(db.localExamTargets).insert(
            LocalExamTargetsCompanion.insert(
              id: 'e1',
              userId: 'u1',
              noteId: const Value('n1'),
              title: 'Chapitre 3',
              createdAt: DateTime.now(),
            ),
          );

      await (db.delete(db.localNotes)..where((t) => t.id.equals('n1'))).go();

      final targets = await db.select(db.localExamTargets).get();
      expect(targets, hasLength(1));
      expect(targets.single.noteId, isNull);
    });

    test('les valeurs par défaut des cibles sont cohérentes', () async {
      await db.into(db.localExamTargets).insert(
            LocalExamTargetsCompanion.insert(
              id: 'e1',
              userId: 'u1',
              title: 'Chapitre',
              createdAt: DateTime.now(),
            ),
          );

      final target = await db.select(db.localExamTargets).getSingle();
      expect(target.difficulty, 3);
      expect(target.reachableGrade, 20);
      expect(target.lengthHours, 1);
      expect(target.isSynced, isFalse);
    });

    test('une mesure de vitesse se relit telle quelle', () async {
      await db.into(db.localSpeedSamples).insert(
            LocalSpeedSamplesCompanion.insert(
              id: 's1',
              userId: 'u1',
              activity: 'reading',
              units: 12.5,
              durationSeconds: 1800,
              createdAt: DateTime.now(),
            ),
          );

      final sample = await db.select(db.localSpeedSamples).getSingle();
      expect(sample.units, 12.5);
      expect(sample.durationSeconds, 1800);
    });

    test('une dépendance entre étapes se conserve', () async {
      await insertItem('p1');
      await insertItem('p2', dependsOn: 'p1');

      final items = await (db.select(db.localPlanItems)
            ..where((t) => t.id.equals('p2')))
          .getSingle();
      expect(items.dependsOnId, 'p1');
    });
  });
}
