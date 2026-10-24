import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/planning/data/planning_repository.dart';
import 'package:cognicquest/features/planning/domain/study_speed.dart';
import 'package:cognicquest/shared/models/planning_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Module Ordre & vitesse : la longueur en pages et l'unité des mesures
/// sont conservées, et les estimations ne mélangent pas les unités.
void main() {
  late AppDatabase db;
  late SupabaseClient client;
  late LocalFirstPlanningRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    client = SupabaseClient('http://fake.local', 'k',
        httpClient: MockClient((r) async => http.Response('', 500)),
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    repository = LocalFirstPlanningRepository(
        database: db, client: client, userId: 'u1', syncEnabled: false);
  });

  tearDown(() async {
    await client.dispose();
    await db.close();
  });

  test('chapitre : longueur en pages et coefficient libre conservés',
      () async {
    await repository.saveExamTarget(ExamTarget(
      id: 't1',
      userId: 'u1',
      title: 'Optique',
      createdAt: DateTime(2026, 10, 1),
      examWeight: 12.5,
      currentGrade: 6,
      reachableGrade: 12,
      lengthHours: 3,
      lengthPages: 40,
    ));
    final target = (await repository.watchExamTargets().first).single;
    expect(target.lengthPages, 40);
    expect(target.coefficient, 12.5);
    expect(target.coefficientLabel, '12,5');
  });

  test('mesures : unité conservée, estimation par unité', () async {
    final now = DateTime.now();
    Future<void> save(String id, String unit, double units, int seconds) =>
        repository.saveSpeedSample(SpeedSample(
          id: id,
          userId: 'u1',
          activity: StudyActivity.writing,
          unit: unit,
          units: units,
          durationSeconds: seconds,
          createdAt: now,
        ));
    await save('a', 'mots', 600, 3600);
    await save('b', 'paragraphes', 6, 3600);

    final samples = await repository.watchSpeedSamples().first;
    expect(samples.map((s) => s.unit), containsAll(['mots', 'paragraphes']));

    final estimates = StudySpeed.allEstimates(samples);
    expect(estimates.map((e) => (e.unit, e.unitsPerHour)),
        containsAll([('mots', 600.0), ('paragraphes', 6.0)]));
  });

  test('vitesse de lecture en pages par heure', () {
    final now = DateTime.now();
    final samples = [
      SpeedSample(
          id: 'r',
          userId: 'u1',
          activity: StudyActivity.reading,
          units: 15,
          durationSeconds: 3600,
          createdAt: now),
    ];
    // Ancienne mesure sans unité : l'unité par défaut de la lecture (pages).
    expect(StudySpeed.readingPagesPerHour(samples), 15);
  });
}
