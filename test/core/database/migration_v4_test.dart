import 'package:cognicquest/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Vérifie que la montée v3 → v4 (Lot 7) préserve les données existantes.
///
/// Plutôt que de réécrire à la main tout le schéma v3, on laisse Drift créer
/// une base complète, on y insère des données, puis on **redescend** le
/// marqueur de version pour rejouer la migration.
void main() {
  late Database raw;

  Future<void> seedV3() async {
    final seed = AppDatabase(NativeDatabase.opened(raw, closeUnderlyingOnClose: false));
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
    await seed.into(seed.localFlashcards).insert(
          LocalFlashcardsCompanion.insert(
            id: 'c1',
            userId: 'u1',
            front: 'Question',
            back: 'Réponse',
            dueAt: now,
            createdAt: now,
          ),
        );
    await seed.close();

    // On simule une base restée en v3 : les tables du Lot 7 n'existent pas.
    raw.execute('DROP TABLE IF EXISTS local_journal_entries;');
    raw.execute('DROP TABLE IF EXISTS local_reframes;');
    raw.execute('DROP TABLE IF EXISTS local_why_chains;');
    raw.execute('DROP TABLE IF EXISTS local_error_logs;');
    raw.execute('DROP TABLE IF EXISTS local_learning_profiles;');
    raw.execute('PRAGMA user_version = 3;');
  }

  setUp(() {
    raw = sqlite3.openInMemory();
  });

  tearDown(() => raw.close());

  group('migration v3 → v4', () {
    test('conserve fiches et cartes, et crée les tables du Lot 7', () async {
      await seedV3();

      final db = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      expect(await db.select(db.localNotes).get(), hasLength(1));
      expect(await db.select(db.localFlashcards).get(), hasLength(1));

      expect(await db.select(db.localJournalEntries).get(), isEmpty);
      expect(await db.select(db.localReframes).get(), isEmpty);
      expect(await db.select(db.localWhyChains).get(), isEmpty);
      expect(await db.select(db.localErrorLogs).get(), isEmpty);
      expect(await db.select(db.localLearningProfiles).get(), isEmpty);

      expect(raw.userVersion, db.schemaVersion);
    });
  });

  group('contraintes du Lot 7', () {
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

    test('une entrée de journal garde ses valeurs par défaut', () async {
      await db.into(db.localJournalEntries).insert(
            LocalJournalEntriesCompanion.insert(
              id: 'j1',
              userId: 'u1',
              createdAt: DateTime.now(),
            ),
          );

      final entry = await db.select(db.localJournalEntries).getSingle();
      expect(entry.mood, 3);
      expect(entry.rpe, 5);
      expect(entry.isSynced, isFalse);
    });

    test('supprimer une fiche détache le bilan sans le détruire', () async {
      await db.into(db.localJournalEntries).insert(
            LocalJournalEntriesCompanion.insert(
              id: 'j1',
              userId: 'u1',
              noteId: const Value('n1'),
              createdAt: DateTime.now(),
            ),
          );

      await (db.delete(db.localNotes)..where((t) => t.id.equals('n1'))).go();

      final entries = await db.select(db.localJournalEntries).get();
      // Le ressenti d'une session vécue survit à la suppression de la fiche.
      expect(entries, hasLength(1));
      expect(entries.single.noteId, isNull);
    });

    test('une erreur consignée survit à la suppression de sa fiche', () async {
      await db.into(db.localErrorLogs).insert(
            LocalErrorLogsCompanion.insert(
              id: 'err1',
              userId: 'u1',
              noteId: const Value('n1'),
              description: 'Signe oublié',
              errorType: 'inattention',
              createdAt: DateTime.now(),
            ),
          );

      await (db.delete(db.localNotes)..where((t) => t.id.equals('n1'))).go();

      final errors = await db.select(db.localErrorLogs).get();
      expect(errors, hasLength(1));
      expect(errors.single.noteId, isNull);
      expect(errors.single.errorType, 'inattention');
    });

    test('le profil est unique par utilisateur', () async {
      Future<void> upsert(String style) =>
          db.into(db.localLearningProfiles).insertOnConflictUpdate(
                LocalLearningProfilesCompanion.insert(
                  userId: 'u1',
                  processingStyle: Value(style),
                  updatedAt: DateTime.now(),
                ),
              );

      await upsert('global');
      await upsert('sequential');

      final profiles = await db.select(db.localLearningProfiles).get();
      expect(profiles, hasLength(1));
      expect(profiles.single.processingStyle, 'sequential');
    });
  });
}
