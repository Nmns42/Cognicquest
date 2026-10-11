import 'package:cognicquest/features/dashboard/providers/dashboard_stats_provider.dart';
import 'package:cognicquest/features/dashboard/widgets/weekly_focus_chart.dart';
import 'package:cognicquest/features/metacognition/widgets/mood_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// « Animations réduites », lot graphiques et progression
/// (TweenAnimationBuilder) : réduites, les barres sont à leur hauteur finale
/// dès la première frame ; normales, elles poussent comme avant.
void main() {
  Widget host(Widget child, {required bool reduced}) => MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            // Même cadre que les écrans : liste avec marges.
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [child],
              ),
            ),
          ),
        ),
      );

  List<Duration> durations(WidgetTester tester) => [
        for (final element
            in find.byType(TweenAnimationBuilder<double>).evaluate())
          (element.widget as TweenAnimationBuilder<double>).duration,
      ];

  /// Hauteurs de tout ce que dessinent les animations.
  List<double> heights(WidgetTester tester) => [
        for (final element in find
            .descendant(
              of: find.byType(TweenAnimationBuilder<double>),
              matching: find.byType(Container),
            )
            .evaluate())
          tester.getSize(find.byWidget(element.widget)).height,
      ];

  /// Hauteurs à la première frame, puis une fois l'animation terminée.
  Future<(List<double>, List<double>)> firstFrameAndSettled(
    WidgetTester tester,
    Widget widget,
  ) async {
    // Le graphique d'humeur déborde déjà de 1,5 à 3 px avec le code d'origine
    // (constaté, hors périmètre, signalé au backlog). Seules ces erreurs de
    // débordement sont tolérées ici ; toute autre erreur fait échouer le test.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      original?.call(details);
    };
    try {
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(milliseconds: 16));
      final first = heights(tester);
      await tester.pumpAndSettle();
      return (first, heights(tester));
    } finally {
      FlutterError.onError = original;
    }
  }

  final now = DateTime.now();
  final stats = DashboardStats(
    sessionsToday: 2,
    focusToday: const Duration(minutes: 50),
    focusThisWeek: const Duration(hours: 4),
    weeklySeries: [
      for (var i = 6; i >= 0; i--)
        DailyFocus(
          day: DateTime(now.year, now.month, now.day - i),
          focus: Duration(minutes: 10 + 15 * i),
          sessions: 1 + i,
        ),
    ],
  );
  const trend = [2.0, 3.0, null, 4.0, 5.0, 3.0, 4.0];

  final charts = <String, (Widget, Duration)>{
    'graphe hebdomadaire (tableau de bord)':
        (WeeklyFocusChart(stats: stats), const Duration(milliseconds: 450)),
    'tendance de l\'humeur (journal)':
        (const MoodTrendChart(trend: trend), const Duration(milliseconds: 420)),
  };

  for (final MapEntry(key: name, value: (chart, original)) in charts.entries) {
    group(name, () {
      testWidgets('(a) réduite : hauteur finale dès la première frame',
          (tester) async {
        final (first, settled) =
            await firstFrameAndSettled(tester, host(chart, reduced: true));
        expect(durations(tester), everyElement(Duration.zero));
        expect(settled, isNotEmpty);
        expect(first, settled);
      });

      testWidgets('(b) normale : durée et pousse d\'origine', (tester) async {
        final (first, settled) =
            await firstFrameAndSettled(tester, host(chart, reduced: false));
        expect(durations(tester), everyElement(original));
        expect(first, isNot(settled));
      });
    });
  }
}
