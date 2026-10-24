import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/features/planning/data/planning_repository.dart';
import 'package:cognicquest/features/planning/widgets/smart_goal_sheet.dart';
import 'package:cognicquest/shared/models/planning_model.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('SMART : sous-questions, indicateur et chapitre reliés',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final client = SupabaseClient('http://fake.local', 'k',
        httpClient: MockClient((r) async => http.Response('', 500)),
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    final repo = LocalFirstPlanningRepository(
        database: db, client: client, userId: 'u1', syncEnabled: false);
    final exam = DateTime.now().add(const Duration(days: 20));
    await tester.runAsync(() => repo.saveExamTarget(ExamTarget(
          id: 't',
          userId: 'u1',
          title: 'Thermodynamique',
          createdAt: DateTime.now(),
          examWeight: 4,
          currentGrade: 8,
          reachableGrade: 15,
          examDate: exam,
        )));

    StudyGoal? result;
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [planningRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await SmartGoalSheet.show(context),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    // Une question guide chaque lettre.
    for (final criterion in SmartCriterion.values) {
      expect(find.text(smartQuestions[criterion]!.first), findsOneWidget);
    }

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Objectif précis'),
        'Maîtriser les cycles de Carnot');
    await tester.tap(find.text('cartes maîtrisées'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Cible'), '200');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Ton plan concret'), '20 par jour');
    await tester.ensureVisible(find.text('Thermodynamique').first);
    await tester.tap(find.text('Thermodynamique').first);
    await tester.pumpAndSettle();

    final save = find.text('Créer');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.metricLabel, 'cartes maîtrisées');
    expect(result!.targetValue, 200);
    expect(result!.relevance, contains('Thermodynamique'));
    expect(result!.relevance, contains('coeff. 4'));
    // Échéance proposée : la veille de l'examen.
    expect(result!.deadline!.day, exam.subtract(const Duration(days: 1)).day);
    expect(result!.isFullySmart, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    // Pas de db.close() attendu ici : il bloque sous testWidgets.
  });
}
