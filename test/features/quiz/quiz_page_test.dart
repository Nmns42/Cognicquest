import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/features/notes/data/note_repository.dart';
import 'package:cognicquest/features/quiz/data/quiz_repository.dart';
import 'package:cognicquest/features/quiz/domain/quiz_generator.dart';
import 'package:cognicquest/features/quiz/providers/quiz_provider.dart';
import 'package:cognicquest/features/quiz/views/quiz_page.dart';
import 'package:cognicquest/features/review/data/review_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('quiz : erreurs → carte à J0, carte créée, titre flou',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final client = SupabaseClient('http://fake.local', 'k',
        httpClient: MockClient((r) async => http.Response('', 500)),
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    final notes = LocalFirstNoteRepository(
        database: db, client: client, userId: 'u1', syncEnabled: false);
    final reviews = LocalFirstReviewRepository(
        database: db, client: client, userId: 'u1', syncEnabled: false);
    final quiz = QuizRepository(
        database: db, client: client, userId: 'u1', syncEnabled: false);

    late String noteId;
    late String cardId;
    await tester.runAsync(() async {
      final note = await notes.create(title: 'Thermodynamique');
      noteId = note.id;
      final card = await reviews.createCard(
          front: 'Unité de l’entropie', back: 'J/K', noteId: noteId);
      cardId = card.id;
    });

    final questions = [
      QuizQuestion(
          id: 'card:$cardId',
          kind: QuizKind.card,
          prompt: 'Unité de l’entropie',
          options: const ['J/K', 'Watt', 'Pascal'],
          answerIndex: 0,
          noteId: noteId,
          cardId: cardId),
      QuizQuestion(
          id: 'cloze:$noteId:0',
          kind: QuizKind.cloze,
          prompt: "Complète : L'_____ ne peut que croître.",
          options: const ['entropie', 'énergie', 'enthalpie'],
          answerIndex: 0,
          noteId: noteId,
          heading: 'Second principe',
          context: "L'entropie ne peut que croître."),
    ];

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(notes),
        reviewRepositoryProvider.overrideWithValue(reviews),
        quizRepositoryProvider.overrideWithValue(quiz),
        quizQuestionsProvider.overrideWith((ref, request) => questions),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const QuizPage(),
      ),
    ));
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await settle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.text('Watt'));
    await settle();
    expect(find.textContaining('méthode des J'), findsOneWidget);
    await tester.tap(find.text('Question suivante'));
    await settle();
    await tester.tap(find.text('énergie'));
    await settle();
    await tester.tap(find.text('Voir le bilan'));
    await settle();

    expect(find.text('0 / 2'), findsOneWidget);
    expect(find.text('Titres encore flous'), findsOneWidget);
    expect(find.text('Second principe'), findsOneWidget);

    final cards = (await tester.runAsync(() => reviews.watchCards().first))!;
    final relearned = cards.firstWhere((c) => c.id == cardId);
    expect(relearned.schedule.dueAt.isAfter(DateTime.now().add(const Duration(days: 1))),
        isFalse);
    expect(cards.map((c) => c.front),
        contains("L'_____ ne peut que croître."));
    final attempts = (await tester.runAsync(() => quiz.watchAll().first))!;
    expect(attempts.where((a) => !a.correct), hasLength(2));

    await tester.pumpWidget(const SizedBox());
    await settle();
  });
}
