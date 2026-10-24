import 'dart:convert';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/quiz/data/quiz_repository.dart';
import 'package:cognicquest/features/quiz/domain/quiz_generator.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Les réponses aux quiz suivent l'utilisateur d'un appareil à l'autre.
void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test('une réponse envoyée revient sur un autre appareil, une seule fois',
      () async {
    final rows = <String, Map<String, dynamic>>{};
    var tick = 0;
    final server = MockClient((request) async {
      const json = {'content-type': 'application/json'};
      if (request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        rows[body['id'] as String] = {
          ...body,
          'updated_at':
              DateTime.utc(2030, 1, 1, 0, 0, tick++).toIso8601String(),
        };
        return http.Response('', 201, request: request);
      }
      return http.Response(jsonEncode(rows.values.toList()), 200,
          headers: json, request: request);
    });
    final client = SupabaseClient('http://fake.local', 'k',
        httpClient: server,
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    final phone = AppDatabase(NativeDatabase.memory());
    final laptop = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await client.dispose();
      await phone.close();
      await laptop.close();
    });

    final source =
        QuizRepository(database: phone, client: client, userId: 'u1');
    await source.record(
      const QuizQuestion(
        id: 'sec:n:0',
        kind: QuizKind.section,
        prompt: 'Que dit « Chaleur » ?',
        options: ['a', 'b', 'c'],
        answerIndex: 0,
        noteId: '00000000-0000-0000-0000-000000000001',
        heading: 'Chaleur',
      ),
      correct: false,
    );
    await source.sync();
    expect(rows.values.single['heading'], 'Chaleur');

    final target =
        QuizRepository(database: laptop, client: client, userId: 'u1');
    await target.sync();
    await target.sync();
    final attempts = await target.watchAll().first;
    expect(attempts, hasLength(1));
    expect(attempts.single.kind, QuizKind.section);
    expect(attempts.single.correct, isFalse);
  });
}
