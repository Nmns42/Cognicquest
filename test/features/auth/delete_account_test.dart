import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/notes/data/note_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Suppression de compte (RGPD) : la fonction serveur d'abord, la purge
/// locale seulement si elle a réussi.
void main() {
  late AppDatabase db;
  late List<String> rpcCalls;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    rpcCalls = [];
  });

  tearDown(() => db.close());

  Future<ProviderContainer> containerWith(int rpcStatus) async {
    final client = SupabaseClient(
      'http://fake.local',
      'anon-key',
      httpClient: MockClient((request) async {
        if (request.url.path.contains('/rpc/')) {
          rpcCalls.add(request.url.pathSegments.last);
          return http.Response(rpcStatus == 204 ? '' : '{"message":"x"}',
              rpcStatus,
              request: request);
        }
        return http.Response('[]', 200, request: request);
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);

    // Une fiche locale, pour vérifier la purge (ou son absence).
    await LocalFirstNoteRepository(
      database: db,
      client: client,
      userId: 'u1',
      syncEnabled: false,
    ).create(title: 'Insuffisance cardiaque');

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      supabaseClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('succès : appelle delete_own_account puis purge l\'appareil', () async {
    final c = await containerWith(204);

    final deleted = await c.read(authControllerProvider.notifier).deleteAccount();

    expect(deleted, isTrue);
    expect(rpcCalls, ['delete_own_account']);
    expect(c.read(authControllerProvider).hasError, isFalse);
    expect(await db.select(db.localNotes).get(), isEmpty);
  });

  test('échec serveur : rien n\'est effacé et l\'erreur est exposée',
      () async {
    final c = await containerWith(500);

    final deleted = await c.read(authControllerProvider.notifier).deleteAccount();

    expect(deleted, isFalse);
    expect(c.read(authControllerProvider).error, isA<AuthFailure>());
    expect(await db.select(db.localNotes).get(), hasLength(1));
  });
}
