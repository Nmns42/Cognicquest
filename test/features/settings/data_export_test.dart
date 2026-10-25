import 'dart:convert';
import 'dart:typed_data';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/metacognition/data/metacognition_repository.dart';
import 'package:cognicquest/features/notes/data/note_repository.dart';
import 'package:cognicquest/features/settings/data/data_export.dart';
import 'package:cognicquest/shared/models/metacognition_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('export JSON : toutes les tables utiles, sans les tables techniques',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final client = SupabaseClient('http://fake.local', 'k',
        httpClient: MockClient((_) async => http.Response('', 500)),
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    final notes = LocalFirstNoteRepository(
        database: db, client: client, userId: 'u1', syncEnabled: false);
    final metacognition = LocalFirstMetacognitionRepository(
        database: db, client: client, userId: 'u1', syncEnabled: false);

    await notes.create(title: 'Thermodynamique');
    await metacognition.saveJournalEntry(JournalEntry(
        id: newMetacognitionId(),
        userId: 'u1',
        mood: 4,
        energy: 3,
        rpe: 6,
        whatLearned: 'Le second principe',
        createdAt: DateTime.utc(2026, 10, 25, 8)));
    await db.into(db.localMediaCache).insert(LocalMediaCacheCompanion.insert(
        path: 'u1/a.png',
        userId: 'u1',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/png',
        createdAt: DateTime.utc(2026, 10, 25)));

    final export = await UserDataExport.collect(db,
        userId: 'u1',
        email: 'eleve@example.com',
        consent: {'version': 1, 'wellbeing': true},
        now: DateTime.utc(2026, 10, 25, 12));

    // Aller-retour JSON : le fichier est bien du JSON valide.
    final decoded =
        jsonDecode(utf8.decode(UserDataExport.encode(export))) as Map;
    expect(decoded['account'], {'user_id': 'u1', 'email': 'eleve@example.com'});
    expect(decoded['exported_at'], '2026-10-25T12:00:00.000Z');
    final data = decoded['data'] as Map;
    for (final technical in UserDataExport.technicalTables) {
      expect(data.containsKey(technical), isFalse);
    }
    expect(data.keys, containsAll(['notes', 'journal_entries', 'error_logs']));
    expect((data['notes'] as List).single['title'], 'Thermodynamique');
    final entry = (data['journal_entries'] as List).single as Map;
    expect(entry['whatLearned'], 'Le second principe');
    expect(entry['createdAt'], startsWith('2026-10-25'));
    final media = (data['media_cache'] as List).single as Map;
    expect(base64Decode(media['base64'] as String), [1, 2, 3]);

    expect(UserDataExport.fileName(DateTime(2026, 3, 7)),
        'cognicquest-mes-donnees-2026-03-07.json');
  });
}
