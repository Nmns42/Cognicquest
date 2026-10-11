import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/database/sync_queue.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/kanban/data/task_repository.dart';
import 'package:cognicquest/features/notes/data/note_repository.dart';
import 'package:cognicquest/shared/models/note_model.dart';
import 'package:cognicquest/shared/models/task_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Purge locale à la déconnexion : les données du compte précédent ne doivent
/// plus être lisibles sur l'appareil.
///
/// Le client Supabase vise un domaine `.invalid` : tout appel réseau échoue,
/// comme hors ligne.
void main() {
  late AppDatabase db;
  late SupabaseClient client;
  late LocalFirstTaskRepository tasks;
  late LocalFirstNoteRepository notes;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    client = SupabaseClient(
      'http://offline.invalid',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    tasks = LocalFirstTaskRepository(
      database: db,
      client: client,
      userId: 'u1',
    );
    notes = LocalFirstNoteRepository(
      database: db,
      client: client,
      userId: 'u1',
    );

    await tasks.create(Task(
      id: '',
      userId: '',
      title: 'Réviser la cardio',
      description: '',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      createdAt: DateTime(2026, 10, 1),
    ));
    final note = await notes.create(title: 'Insuffisance cardiaque');
    await notes.save(note.copyWith(
      blocks: [
        NoteBlock(
          id: 'b1',
          noteId: note.id,
          type: NoteBlockType.paragraph,
          content: 'FEVG',
          position: 0,
        ),
      ],
    ));
    // Laisse échouer les envois lancés en arrière-plan avant de poursuivre.
    await tasks.sync().catchError((_) {});
    await notes.sync().catchError((_) {});
  });

  tearDown(() async {
    await client.dispose();
    await db.close();
  });

  ProviderContainer container() {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        supabaseClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('wipeAll vide toutes les tables, file de synchronisation comprise',
      () async {
    expect(await db.select(db.localTasks).get(), isNotEmpty);
    expect(await db.select(db.localNoteBlocks).get(), isNotEmpty);
    expect(await SyncQueue(db).pendingCount(), greaterThan(0));

    await db.wipeAll();

    for (final table in db.allTables) {
      expect(await db.select(table).get(), isEmpty, reason: table.actualTableName);
    }
  });

  test('flushPendingWrites compte les écritures restées hors ligne', () async {
    final remaining =
        await container().read(authControllerProvider.notifier).flushPendingWrites();

    expect(remaining, await SyncQueue(db).pendingCount());
    expect(remaining, greaterThan(0));
  });

  test('signOut efface les données locales une fois la session fermée',
      () async {
    final c = container();

    await c.read(authControllerProvider.notifier).signOut();

    expect(c.read(authControllerProvider).hasError, isFalse);
    expect(await db.select(db.localTasks).get(), isEmpty);
    expect(await db.select(db.localNotes).get(), isEmpty);
    expect(await SyncQueue(db).pendingCount(), 0);
  });
}
