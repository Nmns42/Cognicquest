import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/metacognition/data/metacognition_repository.dart';
import 'package:cognicquest/features/planning/data/planning_repository.dart';
import 'package:cognicquest/shared/models/metacognition_model.dart';
import 'package:cognicquest/shared/models/planning_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dépôts local-first de la planification et de la métacognition, sans
/// serveur joignable : chaque écriture doit être visible immédiatement en
/// local et mise en file d'attente pour la synchronisation.
void main() {
  late AppDatabase db;
  late SupabaseClient client;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    client = SupabaseClient(
      'http://offline.invalid',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await db.close();
  });

  Future<List<String>> queued() async => [
        for (final e in await db.select(db.syncQueueEntries).get())
          '${e.entityTable}:${e.entityId}:${e.operation}',
      ];

  group('planification', () {
    late LocalFirstPlanningRepository repository;

    setUp(() => repository = LocalFirstPlanningRepository(
          database: db,
          client: client,
          userId: 'u1',
          syncEnabled: false,
        ));

    StudyGoal goal(String id, {double done = 0}) => StudyGoal(
          id: id,
          userId: 'u1',
          title: 'Objectif $id',
          metricLabel: 'exercices',
          targetValue: 20,
          currentValue: done,
          deadline: DateTime(2030, 6, 1),
          createdAt: DateTime(2030),
        );

    test('objectif : création, mise à jour, suppression', () async {
      await repository.saveGoal(goal('g1'));
      var goals = await repository.watchGoals().first;
      expect(goals.single.title, 'Objectif g1');
      expect(goals.single.isSynced, isFalse);

      await repository.saveGoal(goal('g1', done: 12));
      goals = await repository.watchGoals().first;
      expect(goals.single.currentValue, 12, reason: 'upsert, pas de doublon');

      await repository.deleteGoal('g1');
      expect(await repository.watchGoals().first, isEmpty);
      expect(await queued(), ['study_goals:g1:delete'],
          reason: 'la file fusionne upsert puis delete en un seul delete');
    });

    test('isolation : un autre utilisateur ne voit rien', () async {
      await repository.saveGoal(goal('g1'));
      final other = LocalFirstPlanningRepository(
          database: db, client: client, userId: 'u2', syncEnabled: false);
      expect(await other.watchGoals().first, isEmpty);
    });

    test('lot vide : aucune écriture', () async {
      await repository.savePlanItems(const []);
      expect(await queued(), isEmpty);
    });
  });

  group('métacognition', () {
    late LocalFirstMetacognitionRepository repository;

    setUp(() => repository = LocalFirstMetacognitionRepository(
          database: db,
          client: client,
          userId: 'u1',
          syncEnabled: false,
        ));

    test('entrée de journal enregistrée et relue', () async {
      await repository.saveJournalEntry(JournalEntry(
        id: 'j1',
        userId: 'u1',
        mood: 4,
        energy: 3,
        rpe: 7,
        whatLearned: 'Les dérivées',
        createdAt: DateTime(2030, 1, 2),
      ));
      final entry = (await repository.watchJournal().first).single;
      expect(entry.mood, 4);
      expect(entry.rpe, 7);
      expect(entry.whatLearned, 'Les dérivées');
      expect(await queued(), contains('journal_entries:j1:upsert'));
    });

    test('erreurs : toutes relues avec leur type', () async {
      for (final (i, type) in ErrorType.values.indexed) {
        await repository.saveError(ErrorLog(
          id: 'e$i',
          userId: 'u1',
          description: 'Erreur $i',
          errorType: type,
          createdAt: DateTime(2030, 1, 1, i),
        ));
      }
      final errors = await repository.watchErrors().first;
      expect(errors.map((e) => e.errorType).toSet(), ErrorType.values.toSet());
    });
  });
}
