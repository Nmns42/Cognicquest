import 'dart:async';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/database/sync_queue.dart';
import 'package:cognicquest/core/errors/data_failure.dart';
import 'package:cognicquest/features/habits/data/habit_repository.dart';
import 'package:cognicquest/features/kanban/data/task_repository.dart';
import 'package:cognicquest/features/pomodoro/data/pomodoro_repository.dart';
import 'package:cognicquest/shared/models/habit_model.dart';
import 'package:cognicquest/shared/models/task_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mode hors ligne du Lot 10 : tâches, habitudes et Pomodoro doivent
/// fonctionner sans réseau et garder une trace fidèle de ce qui reste à
/// envoyer.
///
/// Le client Supabase vise un domaine `.invalid` (réservé, jamais résolu) :
/// chaque appel réseau échoue comme sur un appareil sans connexion.
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

  Future<List<SyncQueueEntry>> queue() =>
      db.select(db.syncQueueEntries).get();

  group('tâches', () {
    late LocalFirstTaskRepository repository;

    setUp(() {
      repository = LocalFirstTaskRepository(
        database: db,
        client: client,
        userId: 'u1',
      );
    });

    // Laisse se terminer la synchronisation lancée en arrière-plan par la
    // dernière écriture avant de fermer la base.
    tearDown(() => repository.sync().catchError((_) {}));

    Task draft(String title) => Task(
          id: '',
          userId: '',
          title: title,
          description: '',
          status: TaskStatus.todo,
          priority: TaskPriority.medium,
          createdAt: DateTime.now(),
        );

    test('une tâche créée hors ligne est visible et mise en file', () async {
      final created = await repository.create(draft('Réviser la thermo'));

      expect(created.id, isNotEmpty);
      final tasks = await repository.watchAll().first;
      expect(tasks.single.title, 'Réviser la thermo');

      final pending = await queue();
      expect(pending.single.entityTable, 'tasks');
      expect(pending.single.entityId, created.id);
      expect(pending.single.operation, 'upsert');
    });

    test('plusieurs modifications ne produisent qu\'un envoi', () async {
      final created = await repository.create(draft('Exercices'));
      await repository.update(created.copyWith(status: TaskStatus.doing));
      await repository.update(created.copyWith(status: TaskStatus.done));

      expect(await queue(), hasLength(1));
      final tasks = await repository.watchAll().first;
      expect(tasks.single.status, TaskStatus.done);
    });

    test('une suppression remplace l\'envoi en attente', () async {
      final created = await repository.create(draft('Fiche'));
      await repository.delete(created.id);

      expect(await repository.watchAll().first, isEmpty);
      final pending = await queue();
      expect(pending.single.operation, 'delete');
    });

    test('sans réseau, la synchronisation échoue sans rien perdre', () async {
      final created = await repository.create(draft('Annales'));

      await expectLater(
        repository.sync(),
        throwsA(isA<DataFailure>().having((f) => f.isOffline, 'isOffline', true)),
      );

      final pending = await queue();
      expect(pending.single.entityId, created.id);
      expect(pending.single.attempts, greaterThanOrEqualTo(1));
      expect(await repository.watchAll().first, hasLength(1));
    });
  });

  group('changement de compte', () {
    test('une écriture d\'un autre compte reste en file, intacte', () async {
      final other = LocalFirstTaskRepository(
        database: db,
        client: client,
        userId: 'ancien-compte',
      );
      await other.create(Task(
        id: '',
        userId: '',
        title: 'Tâche de l\'ancien compte',
        description: '',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
      ));
      await other.sync().catchError((_) {});
      final before = (await queue()).single;

      final current = LocalFirstTaskRepository(
        database: db,
        client: client,
        userId: 'nouveau-compte',
      );
      // Le pull échoue hors ligne, mais le push a déjà eu lieu : c'est lui
      // qui ne doit ni envoyer ni retirer l'entrée de l'autre compte.
      await current.sync().catchError((_) {});

      final after = (await queue()).single;
      expect(after.entityId, before.entityId);
      expect(after.attempts, before.attempts);
      expect(await current.watchAll().first, isEmpty);
    });
  });

  group('habitudes', () {
    late LocalFirstHabitRepository repository;

    setUp(() {
      repository = LocalFirstHabitRepository(
        database: db,
        client: client,
        userId: 'u1',
      );
    });

    tearDown(() => repository.sync().catchError((_) {}));

    test('cocher un jour hors ligne met à jour la série', () async {
      final habit = await repository.create(
        name: 'Lecture',
        frequency: HabitFrequency.daily,
      );
      await repository.setCompletion(habit.id, DateTime.now(), done: true);

      final habits = await repository.watchAll().first;
      expect(habits.single.completedToday, isTrue);
      expect(habits.single.streak, 1);
    });

    test('cocher puis décocher ne laisse qu\'une suppression en file', () async {
      final habit = await repository.create(
        name: 'Sport',
        frequency: HabitFrequency.daily,
      );
      final today = DateTime.now();
      await repository.setCompletion(habit.id, today, done: true);
      await repository.setCompletion(habit.id, today, done: false);

      final habits = await repository.watchAll().first;
      expect(habits.single.completedToday, isFalse);

      final logs = (await queue()).where((e) => e.entityTable == 'habit_logs');
      expect(logs.single.operation, 'delete');
      expect(
        logs.single.entityId,
        LocalFirstHabitRepository.logKey(habit.id, Habit.toDateKey(today)),
      );
    });

    test('supprimer une habitude abandonne ses jours en attente', () async {
      final habit = await repository.create(
        name: 'Méditation',
        frequency: HabitFrequency.daily,
      );
      await repository.setCompletion(habit.id, DateTime.now(), done: true);
      await repository.delete(habit.id);

      expect(await repository.watchAll().first, isEmpty);
      final pending = await queue();
      expect(pending.single.entityTable, 'habits');
      expect(pending.single.operation, 'delete');
    });

    test('le flux se met à jour quand un jour est coché', () async {
      final habit = await repository.create(
        name: 'Flashcards',
        frequency: HabitFrequency.daily,
      );

      final emissions = <List<Habit>>[];
      final subscription = repository.watchAll().listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await repository.setCompletion(habit.id, DateTime.now(), done: true);
      await pumpEventQueue();

      expect(emissions.last.single.completedToday, isTrue);
    });
  });

  group('Pomodoro', () {
    late LocalFirstPomodoroRepository repository;

    setUp(() {
      repository = LocalFirstPomodoroRepository(
        database: db,
        client: client,
        userId: 'u1',
      );
    });

    tearDown(() => repository.sync().catchError((_) {}));

    test('une session terminée hors ligne est comptée tout de suite', () async {
      await repository.record(
        startedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        durationSeconds: 1500,
      );

      final sessions = await repository.fetchRecent();
      expect(sessions.single.durationSeconds, 1500);
      expect((await queue()).single.entityTable, 'pomodoro_sessions');
    });

    test('la fenêtre récente exclut les sessions anciennes', () async {
      await repository.record(
        startedAt: DateTime.now().subtract(const Duration(days: 10)),
        durationSeconds: 1500,
      );
      await repository.record(
        startedAt: DateTime.now(),
        durationSeconds: 1500,
      );

      expect(await repository.fetchRecent(limitDays: 8), hasLength(1));
      expect(await repository.fetchRecent(), hasLength(2));
    });
  });

  group('SerialSync', () {
    test('des appels concurrents ne lancent qu\'une relance', () async {
      var runs = 0;
      final gate = Completer<void>();
      final sync = SerialSync(() async {
        runs++;
        if (runs == 1) await gate.future;
      });

      final first = sync();
      unawaited(sync());
      unawaited(sync());
      gate.complete();
      await first;

      expect(runs, 2);
    });
  });

  group('DataFailure', () {
    test('reconnaît une coupure réseau sur le web', () {
      final failure = DataFailure.from(
        Exception('ClientException: Failed to fetch, uri=https://x.supabase.co'),
      );
      expect(failure.isOffline, isTrue);
    });
  });
}
