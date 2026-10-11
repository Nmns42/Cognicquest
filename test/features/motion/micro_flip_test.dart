import 'package:cognicquest/core/motion/micro_animations.dart';
import 'package:cognicquest/features/review/data/review_repository.dart';
import 'package:cognicquest/features/review/domain/spaced_repetition.dart';
import 'package:cognicquest/features/review/providers/review_provider.dart';
import 'package:cognicquest/features/review/views/review_session_page.dart';
import 'package:cognicquest/shared/models/flashcard_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Micro-animation n° 6 : la carte de révision se retourne quand on affiche
/// la réponse.
void main() {
  Flashcard card(String id) => Flashcard(
        id: id,
        userId: 'u1',
        front: 'Question $id',
        back: 'Réponse $id',
        createdAt: DateTime(2026, 10, 1),
        schedule: SpacedRepetition.initial(now: DateTime(2026, 10, 1)),
      );

  Widget page({required bool reduced}) => ProviderScope(
        overrides: [
          dueCardsProvider.overrideWithValue([card('1'), card('2')]),
          reviewRepositoryProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: const ReviewSessionPage(),
        ),
      );

  /// Rotation affichée par le retournement (0 = de face).
  double rotation(WidgetTester tester) {
    final transform = tester
        .widget<Transform>(find
            .descendant(
                of: find.byType(FlipReveal), matching: find.byType(Transform))
            .first)
        .transform;
    return transform.storage[8].abs(); // sin de l'angle autour de Y
  }

  Duration flipDuration(WidgetTester tester) => tester
      .widget<TweenAnimationBuilder<double>>(find.descendant(
          of: find.byType(FlipReveal),
          matching: find.byType(TweenAnimationBuilder<double>)))
      .duration;

  Future<void> reveal(WidgetTester tester) async {
    await tester.tap(find.text('Afficher la réponse'));
    await tester.pump();
  }

  testWidgets('normal : la carte tourne pendant 320 ms avant la réponse',
      (tester) async {
    await tester.pumpWidget(page(reduced: false));
    expect(flipDuration(tester), FlipReveal.duration);

    await reveal(tester);
    await tester.pump(const Duration(milliseconds: 80));
    // En plein retournement : la carte est de biais, la réponse pas encore là.
    expect(rotation(tester), greaterThan(0.2));
    expect(find.text('Réponse 1'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Réponse 1'), findsOneWidget);
    expect(rotation(tester), lessThan(1e-9));
  });

  testWidgets('réduit : la réponse est affichée de face dès la première frame',
      (tester) async {
    await tester.pumpWidget(page(reduced: true));
    expect(flipDuration(tester), Duration.zero);

    await reveal(tester);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Réponse 1'), findsOneWidget);
    expect(rotation(tester), lessThan(1e-9));
  });

  for (final reduced in [false, true]) {
    testWidgets('${reduced ? 'réduit' : 'normal'} : passer à la carte '
        'suivante ne montre jamais sa réponse', (tester) async {
      await tester.pumpWidget(page(reduced: reduced));
      await reveal(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Correct').first);
      await tester.pump();
      // Aucune frame ne doit montrer la réponse de la carte suivante.
      for (var i = 0; i < 25; i++) {
        expect(find.text('Réponse 2'), findsNothing);
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.text('Question 2'), findsOneWidget);
    });
  }
}
