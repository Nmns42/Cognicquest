import 'dart:typed_data';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/media/media_store.dart';
import 'package:cognicquest/shared/models/flashcard_model.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Faux bucket Storage : dépôt (POST / PUT) et téléchargement (GET).
class FakeStorage {
  final Map<String, Uint8List> objects = {};
  var online = true;

  late final MockClient client = MockClient((request) async {
    if (!online) throw http.ClientException('hors ligne');
    final path = request.url.path;
    final marker = '/user_media/';
    final at = path.indexOf(marker);
    if (!path.contains('/storage/v1/object') || at < 0) {
      return http.Response('non simulé', 500, request: request);
    }
    final key = Uri.decodeComponent(path.substring(at + marker.length));
    switch (request.method) {
      case 'POST':
      case 'PUT':
        objects[key] = _payload(request);
        return http.Response('{"Key":"user_media/$key"}', 200,
            headers: {'content-type': 'application/json'}, request: request);
      case 'GET':
        final bytes = objects[key];
        return bytes == null
            ? http.Response('{"error":"not_found"}', 404, request: request)
            : http.Response.bytes(bytes, 200, request: request);
    }
    return http.Response('non simulé', 500, request: request);
  });
}

/// Contenu d'un envoi : brut, ou la partie fichier d'un corps multipart.
Uint8List _payload(http.Request request) {
  final body = request.bodyBytes;
  if (!(request.headers['content-type'] ?? '').startsWith('multipart/')) {
    return body;
  }
  int find(List<int> needle, int from) {
    for (var i = from; i <= body.length - needle.length; i++) {
      var hit = true;
      for (var j = 0; j < needle.length; j++) {
        if (body[i + j] != needle[j]) {
          hit = false;
          break;
        }
      }
      if (hit) return i;
    }
    return -1;
  }

  // Dernière partie : après ses en-têtes, jusqu'à la frontière finale.
  final crlf2 = '\r\n\r\n'.codeUnits;
  var start = -1;
  for (var at = find(crlf2, 0); at >= 0; at = find(crlf2, at + 1)) {
    start = at + crlf2.length;
  }
  final end = find('\r\n--'.codeUnits, start);
  return Uint8List.sublistView(body, start, end < 0 ? body.length : end);
}

void main() {
  late FakeStorage storage;
  late SupabaseClient client;
  late AppDatabase phone;
  late AppDatabase laptop;

  MediaStore store(AppDatabase db) =>
      MediaStore(database: db, client: client, userId: 'u1');

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    storage = FakeStorage();
    client = SupabaseClient(
      'http://fake.local',
      'anon-key',
      httpClient: storage.client,
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

  final png = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);

  test('une image importée hors ligne s\'affiche, puis part à la reconnexion',
      () async {
    storage.online = false;
    final media = store(phone);
    final ref = await media.put(png, extension: 'png');

    expect(ref, startsWith('media://u1/'));
    expect(ref, endsWith('.png'));
    expect(await media.read(ref), png);
    expect(await phone.select(phone.syncQueueEntries).get(), hasLength(1));

    storage.online = true;
    await media.sync();
    expect(storage.objects.values.single, png);
    expect(await phone.select(phone.syncQueueEntries).get(), isEmpty);
  });

  test('un autre appareil télécharge l\'image puis la garde en cache',
      () async {
    final ref = await store(phone).put(png, extension: 'png');
    await store(phone).sync();

    final other = store(laptop);
    expect(await other.read(ref), png);

    // Hors ligne ensuite : servie par le cache local.
    storage.online = false;
    expect(await other.read(ref), png);
  });

  test('le texte d\'une carte ne garde que la référence', () {
    const side = CardSide('Mitochondrie', 'media://u1/abc.png');
    final encoded = side.encode();
    expect(encoded.length, lessThan(60));
    expect(CardSide.parse(encoded).image, 'media://u1/abc.png');
  });
}
