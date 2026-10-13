import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/database/sync_queue.dart';
import 'package:cognicquest/features/habits/data/habit_repository.dart';
import 'package:cognicquest/shared/models/habit_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sans vraie session (mode `DEV_BYPASS_AUTH`), les écritures envoyées avec
/// l'utilisateur fictif étaient refusées par la RLS : 426 requêtes en 401
/// relevées par l'audit Supabase du 2026-10-13.
void main() {
  test('sync désactivée : aucune requête, les écritures restent en file',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    var requests = 0;
    final client = SupabaseClient(
      'http://fake.local',
      'anon-key',
      httpClient: MockClient((request) async {
        requests++;
        return http.Response('[]', 200, request: request);
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final repository = LocalFirstHabitRepository(
      database: db,
      client: client,
      userId: '00000000-0000-4000-8000-000000000001',
      syncEnabled: false,
    );

    final habit =
        await repository.create(name: 'Lecture', frequency: HabitFrequency.daily);
    await repository.setCompletion(habit.id, DateTime(2026, 10, 13), done: true);
    await repository.sync();

    expect(requests, 0);
    expect(await SyncQueue(db).pendingCount(), 2);

    await client.dispose();
    await db.close();
  });
}
