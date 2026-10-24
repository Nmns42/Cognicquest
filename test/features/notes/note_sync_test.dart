import 'dart:convert';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/notes/data/note_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Faux PostgREST minimal pour les tables `notes` et `note_blocks`.
///
/// Comme le vrai serveur (trigger set_updated_at), il pose lui-même
/// `updated_at` à chaque écriture, à partir de son horloge [now] — volontairement
/// très éloignée de celle de l'appareil.
class FakeNotesServer {
  DateTime now = DateTime.utc(2030, 1, 1, 12);
  final Map<String, Map<String, dynamic>> notes = {};
  final List<Map<String, dynamic>> blocks = [];
  final List<Map<String, dynamic>> upsertBodies = [];

  /// Corps des mises à jour partielles (`PATCH`), ex. un déplacement.
  final List<Map<String, dynamic>> patchBodies = [];

  /// Lignes complètes renvoyées par chaque GET sur `notes` (hors requêtes
  /// d'identifiants) : mesure ce que le client retélécharge.
  final List<int> fullRowsServed = [];

  late final MockClient client = MockClient(_handle);

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    final json = {'content-type': 'application/json'};

    if (path.endsWith('/notes')) {
      switch (request.method) {
        case 'GET':
          final params = request.url.queryParameters;
          var rows = notes.values.toList();
          final updatedFilter = params['updated_at'];
          if (updatedFilter != null && updatedFilter.startsWith('gt.')) {
            final from = DateTime.parse(updatedFilter.substring(3));
            rows = rows
                .where((r) =>
                    DateTime.parse(r['updated_at'] as String).isAfter(from))
                .toList();
          }
          if (params['select'] == 'id') {
            return http.Response(
                jsonEncode([for (final r in rows) {'id': r['id']}]), 200,
                headers: json, request: request);
          }
          fullRowsServed.add(rows.length);
          return http.Response(jsonEncode(rows), 200,
              headers: json, request: request);
        case 'POST':
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          upsertBodies.add(body);
          // Trigger reject_stale_write : refus si la version de base est
          // plus ancienne que la ligne serveur.
          final existing = notes[body['id']];
          final base = body['updated_at'] as String?;
          if (existing != null &&
              base != null &&
              DateTime.parse(base).isBefore(
                  DateTime.parse(existing['updated_at'] as String))) {
            return http.Response(
                '{"code":"40001","message":"Écriture obsolète"}', 400,
                headers: json, request: request);
          }
          final row = {...body, 'updated_at': now.toIso8601String()};
          notes[body['id'] as String] = row;
          return http.Response(
              jsonEncode({'updated_at': row['updated_at']}), 201,
              headers: json, request: request);
        case 'PATCH':
          final id = request.url.queryParameters['id']!.substring(3);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          patchBodies.add(body);
          final row = notes[id];
          if (row != null) {
            notes[id] = {...row, ...body, 'updated_at': now.toIso8601String()};
          }
          return http.Response('', 204, request: request);
        case 'DELETE':
          final id = request.url.queryParameters['id']!.substring(3);
          notes.remove(id);
          return http.Response('', 204, request: request);
      }
    }
    if (path.endsWith('/note_blocks')) {
      switch (request.method) {
        case 'GET':
          return http.Response(jsonEncode(blocks), 200, headers: json, request: request);
        case 'POST':
          blocks.addAll(
              (jsonDecode(request.body) as List).cast<Map<String, dynamic>>());
          return http.Response('', 201, request: request);
        case 'DELETE':
          final noteId = request.url.queryParameters['note_id']!.substring(3);
          blocks.removeWhere((b) => b['note_id'] == noteId);
          return http.Response('', 204, request: request);
      }
    }
    return http.Response('non simulé : ${request.method} $path', 500,
        request: request);
  }
}

void main() {
  late AppDatabase db;
  late FakeNotesServer server;
  late SupabaseClient client;
  late LocalFirstNoteRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    server = FakeNotesServer();
    client = SupabaseClient(
      'http://fake.local',
      'anon-key',
      httpClient: server.client,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    repository = LocalFirstNoteRepository(
      database: db,
      client: client,
      userId: 'u1',
    );
  });

  tearDown(() async {
    await repository.sync().catchError((_) {});
    await client.dispose();
    await db.close();
  });

  Future<LocalNote?> local(String id) =>
      (db.select(db.localNotes)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  test('le push garde l\'heure du serveur, jamais celle de l\'appareil',
      () async {
    final note = await repository.create(title: 'Cardio');
    await repository.sync();

    final row = await local(note.id);
    expect(row!.isSynced, isTrue);
    expect(row.updatedAt.toUtc(), server.now);
    // Le client n'envoie plus son horloge.
    expect(server.upsertBodies.last.containsKey('updated_at'), isFalse);
  });

  test('modifiée ailleurs entre-temps : la version de cet appareil devient '
      'une copie, la version serveur est conservée', () async {
    final note = await repository.create(title: 'Cardio');
    await repository.sync();

    // Un autre appareil modifie la fiche : nouvelle version serveur.
    server.now = server.now.add(const Duration(minutes: 5));
    server.notes[note.id] = {
      ...server.notes[note.id]!,
      'title': 'Cardio (ordinateur)',
      'updated_at': server.now.toIso8601String(),
    };

    // Cet appareil, resté sur l'ancienne version, modifie puis envoie.
    final stored = (await repository.watchAll().first)
        .firstWhere((n) => n.id == note.id);
    await repository.save(stored.copyWith(title: 'Cardio (téléphone)'));
    await repository.sync();
    await repository.sync();

    expect(server.notes[note.id]!['title'], 'Cardio (ordinateur)');
    expect((await local(note.id))!.title, 'Cardio (ordinateur)');
    final titles = (await repository.watchAll().first).map((n) => n.title);
    expect(titles,
        contains('Cardio (téléphone) (version de cet appareil)'));
    expect(server.notes.values.map((r) => r['title']),
        contains('Cardio (téléphone) (version de cet appareil)'));
  });

  test('une fiche supprimée ailleurs disparaît, même si le serveur est vide',
      () async {
    final note = await repository.create(title: 'Cardio');
    await repository.sync();
    expect(await local(note.id), isNotNull);

    // Suppression depuis un autre appareil : le serveur n'a plus aucune fiche.
    server.notes.clear();
    await repository.sync();

    expect(await local(note.id), isNull);
  });

  test('une version distante plus récente remplace la copie synchronisée',
      () async {
    final note = await repository.create(title: 'Cardio');
    await repository.sync();

    server.now = server.now.add(const Duration(minutes: 5));
    server.notes[note.id] = {
      ...server.notes[note.id]!,
      'title': 'Cardio (modifiée ailleurs)',
      'updated_at': server.now.toIso8601String(),
    };
    await repository.sync();

    expect((await local(note.id))!.title, 'Cardio (modifiée ailleurs)');
  });

  test('après le premier pull, seules les fiches récentes reviennent',
      () async {
    final a = await repository.create(title: 'A');
    final b = await repository.create(title: 'B');
    await repository.sync();

    // Une heure plus tard, seule A est modifiée ailleurs.
    server.now = server.now.add(const Duration(hours: 1));
    server.notes[a.id] = {
      ...server.notes[a.id]!,
      'title': 'A (modifiée ailleurs)',
      'updated_at': server.now.toIso8601String(),
    };
    await repository.sync();
    expect((await local(a.id))!.title, 'A (modifiée ailleurs)');

    // Pull suivant, sans changement : B (une heure plus vieille) ne revient
    // plus. Seule A, dans la marge de recouvrement du curseur, est relue —
    // c'est le prix de la protection contre les validations tardives.
    server.fullRowsServed.clear();
    await repository.sync();

    expect(server.fullRowsServed, [1]);
    expect((await local(b.id))!.title, 'B');
  });

  test('le curseur est conservé dans la base locale', () async {
    await repository.create(title: 'A');
    await repository.sync();

    final cursor = await db.select(db.syncCursors).getSingle();
    expect(cursor.userId, 'u1');
    expect(cursor.remoteTable, 'notes');
    expect(DateTime.parse(cursor.pulledUntil), server.now);
  });

  test('une modification locale en attente n\'est jamais écrasée', () async {
    final note = await repository.create(title: 'Cardio');
    await repository.sync();

    // Version distante plus récente…
    server.now = server.now.add(const Duration(minutes: 5));
    server.notes[note.id] = {
      ...server.notes[note.id]!,
      'title': 'Distante',
      'updated_at': server.now.toIso8601String(),
    };
    // … et modification locale pas encore envoyée : on simule une écriture
    // arrivée pendant la requête réseau du pull en plaçant directement
    // l'entrée en file, sans déclencher de push.
    await (db.update(db.localNotes)..where((t) => t.id.equals(note.id)))
        .write(const LocalNotesCompanion(
      title: Value('Locale'),
      isSynced: Value(false),
    ));
    await db.into(db.syncQueueEntries).insert(
          SyncQueueEntriesCompanion.insert(
            entityTable: 'notes',
            entityId: note.id,
            operation: 'upsert',
            queuedAt: DateTime.now(),
          ),
        );

    await repository.sync();

    // Le push part en premier, avec l'ancienne version de base : le serveur
    // le refuse. La modification locale n'est pas perdue pour autant : elle
    // devient une copie, envoyée à son tour.
    await repository.sync();
    expect((await local(note.id))!.title, 'Distante');
    expect(server.notes[note.id]!['title'], 'Distante');
    expect(server.notes.values.map((r) => r['title']),
        contains('Locale (version de cet appareil)'));
  });
}
