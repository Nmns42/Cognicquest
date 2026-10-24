import 'dart:convert';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/review/data/review_repository.dart';
import 'package:cognicquest/features/review/domain/spaced_repetition.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Faux PostgREST pour `flashcards` et `review_logs`, partagé par deux
/// appareils : ce que l'un envoie, l'autre le rapatrie.
class FakeReviewServer {
  DateTime now = DateTime.utc(2030, 1, 1, 12);
  final Map<String, Map<String, dynamic>> cards = {};
  final Map<String, Map<String, dynamic>> logs = {};

  late final MockClient client = MockClient(_handle);

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    final table = path.endsWith('/flashcards')
        ? cards
        : path.endsWith('/review_logs')
            ? logs
            : null;
    if (table == null) {
      return http.Response('non simulé : ${request.method} $path', 500,
          request: request);
    }
    const json = {'content-type': 'application/json'};
    switch (request.method) {
      case 'GET':
        final params = request.url.queryParameters;
        var rows = table.values.toList();
        final updated = params['updated_at'];
        if (updated != null && updated.startsWith('gt.')) {
          final from = DateTime.parse(updated.substring(3));
          rows = rows
              .where(
                  (r) => DateTime.parse(r['updated_at'] as String).isAfter(from))
              .toList();
        }
        if (params['select'] == 'id') {
          rows = [for (final r in rows) {'id': r['id']}];
        }
        return http.Response(jsonEncode(rows), 200,
            headers: json, request: request);
      case 'POST':
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (table == logs && !cards.containsKey(body['card_id'])) {
          // Clé étrangère distante : la carte doit précéder son journal.
          return http.Response('{"code":"23503"}', 409,
              headers: json, request: request);
        }
        now = now.add(const Duration(seconds: 1));
        table[body['id'] as String] = {
          ...body,
          'updated_at': now.toIso8601String(),
        };
        return http.Response('', 201, request: request);
    }
    return http.Response('non simulé', 500, request: request);
  }
}

void main() {
  late FakeReviewServer server;
  late SupabaseClient client;
  late AppDatabase phone;
  late AppDatabase laptop;

  LocalFirstReviewRepository repo(AppDatabase db) => LocalFirstReviewRepository(
        database: db,
        client: client,
        userId: 'u1',
      );

  // Deux bases distinctes simulent deux appareils : voulu ici.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    server = FakeReviewServer();
    client = SupabaseClient(
      'http://fake.local',
      'anon-key',
      httpClient: server.client,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    phone = AppDatabase(NativeDatabase.memory());
    laptop = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await client.dispose();
    await phone.close();
    await laptop.close();
  });

  test('un jugement part au serveur, après sa carte', () async {
    final repository = repo(phone);
    final card = await repository.createCard(front: 'Q', back: 'R');
    await repository.grade(card, ReviewGrade.good);
    await repository.sync();

    expect(server.logs, hasLength(1));
    final log = server.logs.values.single;
    expect(log['card_id'], card.id);
    expect(log['grade'], 'good');
    expect(await phone.select(phone.syncQueueEntries).get(), isEmpty);
  });

  test('l\'historique et le taux de rétention suivent sur un autre appareil',
      () async {
    final source = repo(phone);
    final card = await source.createCard(front: 'Q', back: 'R');
    await source.grade(card, ReviewGrade.good);
    await source.grade(card, ReviewGrade.again);
    await source.sync();

    final target = repo(laptop);
    await target.sync();

    final grades = await target.gradesSince(DateTime(2000));
    expect(grades, unorderedEquals([ReviewGrade.good, ReviewGrade.again]));

    // Un second pull ne duplique rien.
    await target.sync();
    expect(await laptop.select(laptop.localReviewLogs).get(), hasLength(2));
  });
}
