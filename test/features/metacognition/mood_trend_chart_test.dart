import 'package:cognicquest/features/metacognition/widgets/mood_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Graphique d'humeur : aucun débordement, même sur un petit écran avec un
/// texte agrandi. Avant correction, la hauteur fixe du graphique ne laissait
/// pas de place à l'initiale du jour (0,9 px de débordement avec la police
/// réelle à 100 %, jusqu'à 8,9 px à 200 %).
void main() {
  const trend = [2.0, 3.0, null, 4.0, 5.0, 3.0, 4.5];

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('320 px de large, texte à ${(scale * 100).round()} % : '
        'aucun débordement', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: const [MoodTrendChart(trend: trend)],
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Un débordement est signalé comme exception de rendu.
      expect(tester.takeException(), isNull);
      // Chaque jour garde son initiale visible.
      for (final initial in ['L', 'J', 'V', 'S', 'D']) {
        expect(find.text(initial), findsOneWidget);
      }
    });
  }

  testWidgets('les barres gardent leur échelle : humeur 5 = hauteur maximale',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: MoodTrendChart(trend: [5.0, 2.5])),
    ));
    await tester.pumpAndSettle();

    final heights = [
      for (final element in find
          .descendant(
            of: find.byType(TweenAnimationBuilder<double>),
            matching: find.byType(Container),
          )
          .evaluate())
        tester.getSize(find.byWidget(element.widget)).height,
    ];
    // Échelle inchangée : 64 px pour 5/5, la moitié pour 2,5/5.
    expect(heights, [64, 32]);
  });
}
