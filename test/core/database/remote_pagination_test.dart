import 'dart:convert';

import 'package:cognicquest/core/database/incremental_pull.dart';
import 'package:cognicquest/core/database/remote_pagination.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Faux PostgREST : [total] lignes `{id, updated_at}`, servies selon
/// `offset` / `limit` comme le vrai serveur.
class _FakeServer {
  _FakeServer(this.total);

  final int total;
  final List<Uri> requests = [];

  late final MockClient client = MockClient((request) async {
    requests.add(request.url);
    final params = request.url.queryParameters;
    final offset = int.parse(params['offset'] ?? '0');
    final limit = int.parse(params['limit'] ?? '$total');
    final ids = params['id'];
    final from = params['updated_at'];
    var rows = [
      for (var i = 0; i < total; i++)
        {
          'id': 'r${i.toString().padLeft(5, '0')}',
          'updated_at':
              DateTime.utc(2030, 1, 1).add(Duration(minutes: i)).toIso8601String(),
        },
    ];
    if (ids != null && ids.startsWith('in.(')) {
      final wanted = ids
          .substring(4, ids.length - 1)
          .split(',')
          .map((id) => id.replaceAll('"', ''))
          .toSet();
      rows = rows.where((r) => wanted.contains(r['id'])).toList();
    }
    if (from != null && from.startsWith('gt.')) {
      final since = DateTime.parse(from.substring(3));
      rows = rows
          .where((r) => DateTime.parse(r['updated_at']!).isAfter(since))
          .toList();
    }
    final page = rows.skip(offset).take(limit).toList();
    return http.Response(jsonEncode(page), 200,
        headers: {'content-type': 'application/json'}, request: request);
  });
}

void main() {
  SupabaseClient clientFor(_FakeServer server) => SupabaseClient(
        'http://fake.local',
        'anon-key',
        httpClient: server.client,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

  group('fetchAllPages', () {
    test('rapatrie tout au-delà du plafond de 1000 lignes', () async {
      final server = _FakeServer(2500);
      final client = clientFor(server);
      final rows = await fetchAllPages(() => client.from('t').select());
      expect(rows, hasLength(2500));
      expect(rows.map((r) => r['id']).toSet(), hasLength(2500),
          reason: 'ni trou ni doublon entre les pages');
      expect(server.requests, hasLength(3));
    });

    test('une seule requête pour une table courte', () async {
      final server = _FakeServer(10);
      final rows =
          await fetchAllPages(() => clientFor(server).from('t').select());
      expect(rows, hasLength(10));
      expect(server.requests, hasLength(1));
    });

    test('page pile pleine : une requête de plus, vide', () async {
      final server = _FakeServer(remotePageSize);
      final rows =
          await fetchAllPages(() => clientFor(server).from('t').select());
      expect(rows, hasLength(remotePageSize));
      expect(server.requests, hasLength(2));
    });

    test('trie sur la colonne demandée', () async {
      final server = _FakeServer(3);
      await fetchAllPages(() => clientFor(server).from('t').select(),
          orderBy: 'updated_at');
      expect(server.requests.single.queryParameters['order'],
          startsWith('updated_at.asc'));
    });
  });

  test('fetchAllPagesIn découpe les identifiants en lots', () async {
    final server = _FakeServer(450);
    final ids = [for (var i = 0; i < 450; i++) 'r${i.toString().padLeft(5, '0')}'];
    final rows = await fetchAllPagesIn(
      () => clientFor(server).from('t').select(),
      column: 'id',
      ids: ids,
    );
    expect(rows, hasLength(450));
    expect(server.requests, hasLength(3), reason: '200 + 200 + 50');
  });

  group('fetchDelta', () {
    test('premier pull : tout, identifiants déduits, curseur au max', () async {
      final server = _FakeServer(5);
      final client = clientFor(server);
      final delta = await fetchDelta(
        rows: () => client.from('t').select(),
        ids: () => client.from('t').select('id'),
        since: null,
      );
      expect(delta.changed, hasLength(5));
      expect(delta.remoteIds, hasLength(5));
      expect(server.requests, hasLength(1),
          reason: 'pas de requête d\'identifiants au premier pull');
      expect(delta.cursor,
          DateTime.utc(2030, 1, 1, 0, 4).toIso8601String());
    });

    test('pull suivant : recouvrement de deux minutes', () async {
      final server = _FakeServer(10);
      final client = clientFor(server);
      final since = DateTime.utc(2030, 1, 1, 0, 8).toIso8601String();
      final delta = await fetchDelta(
        rows: () => client.from('t').select(),
        ids: () => client.from('t').select('id'),
        since: since,
      );
      // > 00:06 : lignes 7, 8, 9.
      expect(delta.changed.map((r) => r['id']),
          ['r00007', 'r00008', 'r00009']);
      expect(delta.remoteIds, hasLength(10));
      expect(delta.cursor, DateTime.utc(2030, 1, 1, 0, 9).toIso8601String());
    });

    test('rien de neuf : le curseur ne recule pas', () async {
      final server = _FakeServer(2);
      final since = DateTime.utc(2031).toIso8601String();
      final delta = await fetchDelta(
        rows: () => clientFor(server).from('t').select(),
        since: since,
      );
      expect(delta.changed, isEmpty);
      expect(delta.remoteIds, isNull);
      expect(delta.cursor, since);
    });
  });
}
