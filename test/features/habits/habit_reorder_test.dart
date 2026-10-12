import 'dart:convert';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/ordering/manual_order.dart';
import 'package:cognicquest/features/habits/data/habit_repository.dart';
import 'package:cognicquest/shared/models/habit_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Faux PostgREST pour `habits` et `habit_logs` (updated_at posé par le
/// serveur, comme le trigger).
class FakeHabitsServer {
  DateTime now = DateTime.utc(2030, 1, 1, 12);
  final Map<String, Map<String, dynamic>> habits = {};
  final List<Map<String, dynamic>> upsertBodies = [];
  final List<Map<String, dynamic>> patchBodies = [];

  late final MockClient client = MockClient((request) async {
    final json = {'content-type': 'application/json'};
    final params = request.url.queryParameters;
    if (request.url.path.endsWith('/habit_logs')) {
      return request.method == 'GET'
          ? http.Response('[]', 200, headers: json, request: request)
          : http.Response('', 201, request: request);
    }
    switch (request.method) {
      case 'GET':
        var rows = habits.values.toList();
        final filter = params['updated_at'];
        if (filter != null && filter.startsWith('gt.')) {
          final from = DateTime.parse(filter.substring(3));
          rows = rows
              .where((r) =>
                  DateTime.parse(r['updated_at'] as String).isAfter(from))
              .toList();
        }
        if (params['select'] == 'id') {
          rows = [for (final r in rows) {'id': r['id']}];
        }
        return http.Response(jsonEncode(rows), 200,
            headers: json, request: request);
      case 'POST':
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        upsertBodies.add(body);
        habits[body['id'] as String] = {
          ...body,
          'updated_at': now.toIso8601String(),
        };
        return http.Response('', 201, request: request);
      case 'PATCH':
        final id = params['id']!.substring(3);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        patchBodies.add(body);
        final row = habits[id];
        if (row != null) {
          habits[id] = {...row, ...body, 'updated_at': now.toIso8601String()};
        }
        return http.Response('', 204, request: request);
      case 'DELETE':
        habits.remove(params['id']!.substring(3));
        return http.Response('', 204, request: request);
    }
    return http.Response('non simulé', 500, request: request);
  });
}

/// Ordre manuel des habitudes (R2) : même mécanisme que les fiches.
void main() {
  ({AppDatabase db, LocalFirstHabitRepository repo, SupabaseClient client})
      device(FakeHabitsServer server) {
    final db = AppDatabase(NativeDatabase.memory());
    final client = SupabaseClient('http://fake.local', 'anon-key',
        httpClient: server.client,
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    return (
      db: db,
      repo: LocalFirstHabitRepository(database: db, client: client, userId: 'u1'),
      client: client,
    );
  }

  Future<void> close(
      ({AppDatabase db, LocalFirstHabitRepository repo, SupabaseClient client})
          d) async {
    await d.repo.sync().catchError((_) {});
    await d.client.dispose();
    await d.db.close();
  }

  Future<List<String>> names(LocalFirstHabitRepository repo) async =>
      [for (final h in await repo.watchAll().first) h.name];

  Future<void> move(
      LocalFirstHabitRepository repo, String name, int newIndex) async {
    final visible = await repo.watchAll().first;
    await repo.applyPositions(ManualOrder.planMove(
      [for (final h in visible) OrderedItem(h.id, h.position)],
      visible.firstWhere((h) => h.name == name).id,
      newIndex,
    ));
  }

  Future<void> seed(LocalFirstHabitRepository repo, int count) async {
    for (var i = 0; i < count; i++) {
      await repo.create(name: 'H$i', frequency: HabitFrequency.daily);
      // Dates de création distinctes : l'ordre de départ est déterministe.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
    }
    await repo.sync();
  }

  test('(e) sans position, l\'ordre est l\'ordre de création', () async {
    final server = FakeHabitsServer();
    final a = device(server);
    addTearDown(() => close(a));
    await seed(a.repo, 3);
    expect(await names(a.repo), ['H0', 'H1', 'H2']);
  });

  test('(a) une fois les clés posées, un déplacement réécrit une seule '
      'ligne, et seulement sa position', () async {
    final server = FakeHabitsServer();
    final a = device(server);
    addTearDown(() => close(a));
    await seed(a.repo, 4);
    await move(a.repo, 'H0', 0); // premier déplacement : initialisation
    await a.repo.sync();
    server.patchBodies.clear();
    server.upsertBodies.clear();

    await move(a.repo, 'H3', 0);
    await a.repo.sync();

    expect(server.patchBodies, hasLength(1));
    expect(server.patchBodies.single.keys, ['position']);
    expect(server.upsertBodies, isEmpty);
    expect(await names(a.repo), ['H3', 'H0', 'H1', 'H2']);
  });

  test('(b) l\'ordre survit à un aller-retour push / pull, et (c) deux '
      'appareils qui déplacent des habitudes différentes ne s\'écrasent pas',
      () async {
    final server = FakeHabitsServer();
    final a = device(server);
    final b = device(server);
    addTearDown(() => close(a));
    addTearDown(() => close(b));
    await seed(a.repo, 5);
    await move(a.repo, 'H4', 0);
    await a.repo.sync();
    server.now = server.now.add(const Duration(hours: 1));
    await b.repo.sync();
    expect(await names(b.repo), await names(a.repo)); // (b)

    await move(a.repo, 'H3', 0);
    await move(b.repo, 'H0', 4);
    await a.repo.sync();
    await b.repo.sync();
    server.now = server.now.add(const Duration(hours: 1));
    await a.repo.sync();
    await b.repo.sync();

    final onA = await names(a.repo);
    expect(await names(b.repo), onA);
    expect(onA.first, 'H3', reason: 'déplacement de A conservé');
    expect(onA.last, 'H0', reason: 'déplacement de B conservé');
  });

  test('une nouvelle habitude arrive en fin de liste', () async {
    final server = FakeHabitsServer();
    final a = device(server);
    addTearDown(() => close(a));
    await seed(a.repo, 3);
    await move(a.repo, 'H2', 0);
    await a.repo.create(name: 'Nouvelle', frequency: HabitFrequency.daily);

    expect(await names(a.repo), ['H2', 'H0', 'H1', 'Nouvelle']);
  });
}
