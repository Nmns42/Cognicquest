import 'dart:convert';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/coach/domain/tree_coach.dart';
import 'package:cognicquest/features/legal/consent.dart';
import 'package:cognicquest/features/legal/consent_sync.dart';
import 'package:cognicquest/features/legal/views/wellbeing_gate.dart';
import 'package:cognicquest/features/metacognition/data/metacognition_repository.dart';
import 'package:cognicquest/shared/models/metacognition_model.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User user(String id) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-10-25T00:00:00Z',
    );

SupabaseClient client(Future<http.Response> Function(http.Request) handler) =>
    SupabaseClient('http://fake.local', 'k',
        httpClient: MockClient(handler),
        authOptions: const AuthClientOptions(autoRefreshToken: false));

Future<void> fillWellbeing(LocalFirstMetacognitionRepository repo) async {
  final now = DateTime(2026, 10, 25);
  await repo.saveJournalEntry(JournalEntry(
      id: newMetacognitionId(),
      userId: 'u1',
      mood: 2,
      energy: 2,
      rpe: 8,
      createdAt: now,
      isSynced: false));
  await repo.saveReframe(Reframe(
      id: newMetacognitionId(),
      userId: 'u1',
      limitingThought: 'Je n’y arriverai jamais',
      createdAt: now,
      isSynced: false));
  await repo.saveError(ErrorLog(
      id: newMetacognitionId(),
      userId: 'u1',
      description: 'Signe oublié',
      errorType: ErrorType.inattention,
      createdAt: now,
      isSynced: false));
}

void main() {
  test('retrait : bien-être effacé de l\'appareil, cahier d\'erreurs gardé, '
      'purge serveur et preuve en attente', () async {
    SharedPreferences.setMockInitialValues({
      'cq_consent_version': 1,
      'cq_consent_wellbeing': true,
    });
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LocalFirstMetacognitionRepository(
        database: db,
        client: client((_) async => http.Response('', 500)),
        userId: 'u1',
        syncEnabled: false);
    await fillWellbeing(repo);

    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(user('u1')),
      metacognitionRepositoryProvider.overrideWithValue(repo),
      consentSyncProvider.overrideWithValue(null),
    ]);
    addTearDown(container.dispose);
    await container.read(consentProvider.future);
    expect(container.read(wellbeingConsentProvider), isTrue);

    await container.read(consentProvider.notifier).setWellbeing(false);

    expect(container.read(wellbeingConsentProvider), isFalse);
    expect(await repo.watchJournal().first, isEmpty);
    expect(await repo.watchReframes().first, isEmpty);
    expect(await repo.watchErrors().first, hasLength(1));
    final queued = await db.select(db.syncQueueEntries).get();
    expect(queued.map((e) => e.entityTable), ['error_logs']);

    const store = ConsentStore();
    expect(await store.purgeUser(), 'u1');
    final pending = await store.pending();
    expect(pending.single.wellbeing, isFalse);
    expect(pending.single.userId, 'u1');
  });

  test('ConsentSync : purge serveur puis preuve envoyée, file vidée', () async {
    SharedPreferences.setMockInitialValues({});
    const store = ConsentStore();
    await store.setPurgeUser('u1');
    final at = DateTime.utc(2026, 10, 25, 9);
    await store.addPending(
        ConsentRecord(version: 1, wellbeing: true, decidedAt: at));
    await store.addPending(ConsentRecord(
        version: 1, wellbeing: false, decidedAt: at, userId: 'u1'));
    // Décision d'un autre compte de l'appareil : jamais envoyée pour u1.
    await store.addPending(ConsentRecord(
        version: 1, wellbeing: true, decidedAt: at, userId: 'u2'));

    final requests = <http.Request>[];
    final supabase = client((request) async {
      requests.add(request);
      return http.Response(request.method == 'POST' ? '' : '[]',
          request.method == 'POST' ? 201 : 200,
          request: request);
    });
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LocalFirstMetacognitionRepository(
        database: db, client: supabase, userId: 'u1');

    await ConsentSync(
            client: supabase, userId: 'u1', store: store, metacognition: repo)
        .sync();

    final deletes = requests.where((r) => r.method == 'DELETE').toList();
    expect(deletes.map((r) => r.url.pathSegments.last),
        ['journal_entries', 'reframes', 'why_chains']);
    expect(deletes.every((r) => r.url.query.contains('user_id=eq.u1')), isTrue);

    final insert = requests.singleWhere((r) => r.method == 'POST');
    expect(insert.url.pathSegments.last, 'consents');
    final rows = (jsonDecode(insert.body) as List).cast<Map>();
    expect(rows, hasLength(2));
    expect(rows.every((r) => r['user_id'] == 'u1'), isTrue);
    expect(rows.map((r) => r['wellbeing']), [true, false]);

    expect(await store.purgeUser(), isNull);
    expect((await store.pending()).single.userId, 'u2');
  });

  test('ConsentSync hors ligne : purge et preuves restent en attente',
      () async {
    SharedPreferences.setMockInitialValues({});
    const store = ConsentStore();
    await store.setPurgeUser('u1');
    await store.addPending(ConsentRecord(
        version: 1, wellbeing: false, decidedAt: DateTime.utc(2026)));
    final supabase =
        client((_) async => throw http.ClientException('hors ligne'));
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await expectLater(
        ConsentSync(
                client: supabase,
                userId: 'u1',
                store: store,
                metacognition: LocalFirstMetacognitionRepository(
                    database: db, client: supabase, userId: 'u1'))
            .sync(),
        throwsA(anything));
    expect(await store.purgeUser(), 'u1');
    expect(await store.pending(), hasLength(1));
  });

  testWidgets('écran bien-être : bloqué sans accord, ouvert après activation',
      (tester) async {
    SharedPreferences.setMockInitialValues({'cq_consent_version': 1,
        'cq_consent_wellbeing': false});
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        metacognitionRepositoryProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const WellbeingGate(
            title: 'Bilan de session', child: Text('Journal ouvert')),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Module bien-être désactivé'), findsOneWidget);
    expect(find.text('Journal ouvert'), findsNothing);

    await tester.tap(find.text('Activer l’analyse de mon bien-être'));
    await tester.pumpAndSettle();
    expect(find.text('Journal ouvert'), findsOneWidget);
  });

  test('coach sans consentement : aucun conseil vers le journal', () {
    final topics = TreeCoach(const CoachSignals(wellbeingEnabled: false))
        .advice(limit: 10)
        .map((a) => a.topic);
    expect(topics, isNot(contains(CoachTopic.journal)));
    expect(
        TreeCoach(const CoachSignals()).advice(limit: 10).map((a) => a.topic),
        contains(CoachTopic.journal));
  });
}
