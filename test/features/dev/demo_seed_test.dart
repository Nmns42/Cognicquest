import 'package:cognicquest/core/config/app_config.dart';
import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/dev/demo_seed.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Le jeu de démo doit se charger entièrement, hors ligne, sans erreur.
void main() {
  test('remplit chaque module', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final client = SupabaseClient(
      'http://offline.invalid',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      supabaseClientProvider.overrideWithValue(client),
      currentUserIdProvider.overrideWithValue(AppConfig.devUserId),
    ]);
    addTearDown(() async {
      container.dispose();
      await client.dispose();
      await db.close();
    });

    final seed = FutureProvider<void>((ref) => runDemoSeed(ref, db));
    await container.read(seed.future);

    expect(await db.select(db.localNotes).get(), hasLength(8));
    expect(await db.select(db.localNoteLinks).get(), hasLength(10));
    expect(await db.select(db.localTasks).get(), hasLength(11));
    expect(await db.select(db.localHabits).get(), hasLength(5));
    expect(await db.select(db.localHabitLogs).get(), isNotEmpty);
    expect(await db.select(db.localPomodoroSessions).get(), hasLength(25));
    expect(await db.select(db.localFlashcards).get(), hasLength(8));
    expect(await db.select(db.localJournalEntries).get(), hasLength(4));
    expect(await db.select(db.localErrorLogs).get(), hasLength(5));
    expect(await db.select(db.localStudyGoals).get(), hasLength(2));
    expect(await db.select(db.localPlanItems).get(), hasLength(5));
  });
}
