import 'package:cognicquest/core/motion/micro_animations.dart';
import 'package:cognicquest/features/dashboard/widgets/dashboard_cards.dart';
import 'package:cognicquest/shared/models/habit_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Micro-animation n° 1 : valider une habitude fait rebondir la coche et
/// monter la série d'un cran.
void main() {
  final today = DateTime.now();

  Habit habit({required bool doneToday}) => Habit(
        id: 'h1',
        userId: 'u1',
        name: 'Lecture',
        createdAt: today.subtract(const Duration(days: 10)),
        completedDates: [
          // Hier fait : la série passe de 1 à 2 quand on coche aujourd'hui.
          Habit.toDateKey(today.subtract(const Duration(days: 1))),
          if (doneToday) Habit.toDateKey(today),
        ],
      );

  Widget row({required bool doneToday, required bool reduced}) => MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: Scaffold(
              body: HabitPreviewRow(
                habit: habit(doneToday: doneToday),
                onToggle: () {},
              ),
            ),
          ),
        ),
      );

  double checkScale(WidgetTester tester) => tester
      .widget<Transform>(find
          .descendant(
              of: find.byType(PulseOnChange), matching: find.byType(Transform))
          .first)
      .transform
      .getMaxScaleOnAxis();

  double streakOpacity(WidgetTester tester) => tester
      .widget<Opacity>(find
          .descendant(
              of: find.byType(RollingNumber), matching: find.byType(Opacity))
          .first)
      .opacity;

  List<Duration> durations(WidgetTester tester) => [
        for (final finder in [
          find.descendant(
              of: find.byType(PulseOnChange),
              matching: find.byType(TweenAnimationBuilder<double>)),
          find.descendant(
              of: find.byType(RollingNumber),
              matching: find.byType(TweenAnimationBuilder<double>)),
        ])
          tester.widget<TweenAnimationBuilder<double>>(finder.first).duration,
      ];

  testWidgets('normal : la coche rebondit et la série monte', (tester) async {
    await tester.pumpWidget(row(doneToday: false, reduced: false));
    expect(durations(tester), const [
      Duration(milliseconds: 320),
      Duration(milliseconds: 280),
    ]);
    expect(find.text('1'), findsOneWidget);

    await tester.pumpWidget(row(doneToday: true, reduced: false));
    await tester.pump(const Duration(milliseconds: 140));
    expect(checkScale(tester), greaterThan(1.1));
    expect(streakOpacity(tester), lessThan(1.0));
    expect(find.text('2'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(checkScale(tester), closeTo(1.0, 1e-9));
    expect(streakOpacity(tester), 1.0);
  });

  testWidgets('réduit : état final dès la première frame', (tester) async {
    await tester.pumpWidget(row(doneToday: false, reduced: true));
    expect(durations(tester), const [Duration.zero, Duration.zero]);

    await tester.pumpWidget(row(doneToday: true, reduced: true));
    await tester.pump(const Duration(milliseconds: 16));
    expect(checkScale(tester), closeTo(1.0, 1e-9));
    expect(streakOpacity(tester), 1.0);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('décocher ne fait pas rebondir et la série baisse sans '
      'animation', (tester) async {
    await tester.pumpWidget(row(doneToday: true, reduced: false));
    await tester.pumpWidget(row(doneToday: false, reduced: false));
    await tester.pump(const Duration(milliseconds: 140));
    expect(checkScale(tester), 1.0);
    expect(streakOpacity(tester), 1.0);
    expect(find.text('1'), findsOneWidget);
  });
}
