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

  late final MockClient client = MockClient(_handle);

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    final json = {'content-type': 'application/json'};

    if (path.endsWith('/notes')) {
      switch (request.method) {
        case 'GET':
          return http.Response(jsonEncode(notes.values.toList()), 200,
              headers: json, request: request);
        case 'POST':
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          upsertBodies.add(body);
          final row = {...body, 'updated_at': now.toIso8601String()};
          notes[body['id'] as String] = row;
          return http.Response(
              jsonEncode({'updated_at': row['updated_at']}), 201,
              headers: json, request: request);
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

  test('une version distante pas plus récente ne remplace rien', () async {
    final note = await repository.create(title: 'Cardio');
    await repository.sync();

    // Même updated_at : rien n'a changé côté serveur depuis notre envoi.
    server.notes[note.id] = {...server.notes[note.id]!, 'title': 'Autre'};
    await repository.sync();

    expect((await local(note.id))!.title, 'Cardio');
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

    // Le push part en premier : la version locale gagne, côté serveur aussi.
    expect((await local(note.id))!.title, 'Locale');
    expect(server.notes[note.id]!['title'], 'Locale');
  });
}
