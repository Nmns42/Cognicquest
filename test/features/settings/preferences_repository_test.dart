import 'dart:convert';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/database/sync_queue.dart';
import 'package:cognicquest/features/settings/data/preferences_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Réglages et disposition du Dashboard en local-first.
void main() {
  late AppDatabase db;
  late SupabaseClient client;
  late List<Map<String, dynamic>> upserts;
  late Map<String, dynamic>? serverRow;
  late bool online;

  LocalFirstPreferencesRepository repository({bool syncEnabled = true}) =>
      LocalFirstPreferencesRepository(
        database: db,
        client: client,
        userId: 'u1',
        syncEnabled: syncEnabled,
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    upserts = [];
    serverRow = null;
    online = true;
    client = SupabaseClient(
      'http://fake.local',
      'anon-key',
      httpClient: MockClient((request) async {
        if (!online) throw http.ClientException('Failed to fetch');
        const json = {'content-type': 'application/json'};
        switch (request.method) {
          case 'POST':
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            upserts.add(body);
            serverRow = {...?serverRow, ...body};
            return http.Response('', 201, request: request);
          case 'GET':
            return http.Response(
                jsonEncode(serverRow == null ? [] : [serverRow]), 200,
                headers: json, request: request);
        }
        return http.Response('', 500, request: request);
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await db.close();
  });

  test('hors ligne : le choix est gardé sur l\'appareil et mis en file',
      () async {
    online = false;
    final repo = repository();

    await repo.save(PreferenceKey.settings, {'theme': 'dark'});
    await repo.sync().catchError((_) {});

    expect(await repo.watch(PreferenceKey.settings).first, {'theme': 'dark'});
    expect(await repo.watch(PreferenceKey.dashboardLayout).first, isNull);
    expect(await SyncQueue(db).pendingIds(LocalFirstPreferencesRepository.table),
        {'settings'});
  });

  test('en ligne : seule la colonne modifiée part au serveur', () async {
    final repo = repository();

    await repo.save(PreferenceKey.dashboardLayout, {'order': ['a', 'b']});
    await repo.sync();

    expect(upserts.last, {
      'user_id': 'u1',
      'dashboard_layout': {'order': ['a', 'b']},
    });
    expect(await SyncQueue(db).pendingCount(), 0);
  });

  test('le pull rapatrie les choix faits sur un autre appareil', () async {
    serverRow = {
      'user_id': 'u1',
      'settings': {'theme': 'forest'},
      'dashboard_layout': {'order': ['x']},
    };
    final repo = repository();

    await repo.sync();

    expect(await repo.watch(PreferenceKey.settings).first, {'theme': 'forest'});
    expect(await repo.watch(PreferenceKey.dashboardLayout).first,
        {'order': ['x']});
  });

  test('le pull n\'écrase pas un choix encore en attente d\'envoi', () async {
    online = false;
    final repo = repository();
    await repo.save(PreferenceKey.settings, {'theme': 'local'});
    await repo.sync().catchError((_) {});

    // Le serveur a une valeur plus ancienne ; le réseau revient.
    serverRow = {'user_id': 'u1', 'settings': {'theme': 'ancien'}};
    online = true;
    await repo.sync();

    expect(await repo.watch(PreferenceKey.settings).first, {'theme': 'local'});
    expect(serverRow!['settings'], {'theme': 'local'});
  });

  test('sync désactivée (mode démo) : aucun appel réseau', () async {
    final repo = repository(syncEnabled: false);

    await repo.save(PreferenceKey.settings, {'theme': 'dark'});
    await repo.sync();

    expect(upserts, isEmpty);
    expect(await repo.watch(PreferenceKey.settings).first, {'theme': 'dark'});
  });
}
