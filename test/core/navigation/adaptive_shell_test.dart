import 'package:cognicquest/core/navigation/adaptive_shell.dart';
import 'package:cognicquest/core/navigation/app_destinations.dart';
import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Coquille à quatre espaces et mode concentration (refonte zen, Phase 1).
void main() {
  setUp(AdaptiveShell.resetMemory);

  Future<GoRouter> pumpShell(
    WidgetTester tester, {
    required String location,
    bool focusMode = false,
    Size size = const Size(400, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final routes = [
      for (final space in AppSpace.values)
        for (final section in space.sections) section.route,
      settingsRoute,
    ];
    final router = GoRouter(
      initialLocation: location,
      routes: [
        ShellRoute(
          builder: (context, state, child) => AdaptiveShell(
            currentLocation: state.matchedLocation,
            focusMode: focusMode && state.matchedLocation == focusRoute,
            child: child,
          ),
          routes: [
            for (final route in routes)
              GoRoute(
                path: route,
                builder: (_, __) => Scaffold(body: Text('page $route')),
                routes: [
                  GoRoute(
                    path: 'sub',
                    builder: (_, __) => Text('sous-page $route'),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('téléphone : barre du bas à quatre espaces', (tester) async {
    await pumpShell(tester, location: '/home');

    expect(find.byType(NavigationBar), findsOneWidget);
    // Quatre espaces, puis les réglages (leur seule entrée sur téléphone).
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (final space in AppSpace.values) {
      expect(find.text(space.label), findsOneWidget);
    }
  });

  testWidgets('onglets de l\'espace à la racine d\'une section',
      (tester) async {
    await pumpShell(tester, location: '/notes');

    expect(find.text('Fiches'), findsOneWidget);
    expect(find.text('Réviser'), findsOneWidget);
    expect(find.text('Graphe'), findsOneWidget);

    await tester.tap(find.text('Réviser'));
    await tester.pumpAndSettle();
    expect(find.text('page /review'), findsOneWidget);
  });

  testWidgets(
      'pas d\'onglets dans une sous-page ni pour un espace à une '
      'section', (tester) async {
    await pumpShell(tester, location: '/notes/sub');
    expect(find.text('Réviser'), findsNothing);

    await pumpShell(tester, location: '/journal');
    expect(find.text('Journal'), findsNothing);
  });

  testWidgets('mode concentration : plus aucune navigation', (tester) async {
    await pumpShell(tester, location: '/pomodoro', focusMode: true);

    expect(find.byType(NavigationDestination), findsNothing);
    expect(find.text('Concentration'), findsNothing);
    expect(find.text('page /pomodoro'), findsOneWidget);
  });

  testWidgets('mode concentration : aussi sans rail sur grand écran',
      (tester) async {
    await pumpShell(tester,
        location: '/pomodoro', focusMode: true, size: const Size(1400, 900));

    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('hors session, l\'écran du Pomodoro garde la navigation',
      (tester) async {
    await pumpShell(tester, location: '/pomodoro');

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.text('Concentration'), findsOneWidget);
  });

  testWidgets('grand écran : rail à quatre espaces et réglages en bas',
      (tester) async {
    await pumpShell(tester, location: '/home', size: const Size(1400, 900));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byTooltip('Réglages'));
    await tester.pumpAndSettle();
    expect(find.text('page $settingsRoute'), findsOneWidget);
  });

  testWidgets('revenir à un espace ramène au dernier écran visité',
      (tester) async {
    await pumpShell(tester, location: '/notes');

    await tester.tap(find.text('Réviser'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Organiser'));
    await tester.pumpAndSettle();
    expect(find.text('page /kanban'), findsOneWidget);

    await tester.tap(find.text('Apprendre'));
    await tester.pumpAndSettle();
    expect(find.text('page /review'), findsOneWidget);

    // Toucher l'espace courant ramène à sa racine.
    await tester.tap(find.text('Apprendre'));
    await tester.pumpAndSettle();
    expect(find.text('page /notes'), findsOneWidget);
  });

  testWidgets("grand écran : l'en-tête réduit puis redéploie le menu",
      (tester) async {
    await pumpShell(tester, location: '/home', size: const Size(1400, 900));
    bool extended() =>
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended;
    expect(extended(), isTrue);

    await tester.tap(find.byTooltip('Réduire le menu'));
    await tester.pumpAndSettle();
    expect(extended(), isFalse);
    expect(find.text('CognicQuest'), findsNothing);

    await tester.tap(find.byTooltip('Déployer le menu'));
    await tester.pumpAndSettle();
    expect(extended(), isTrue);
  });

  testWidgets('grand écran : raccourcis Habitudes et Graphe sous leur espace',
      (tester) async {
    await pumpShell(tester, location: '/home', size: const Size(1400, 900));

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    // Aujourd'hui, Habitudes, Apprendre, Graphe, Organiser, Réfléchir.
    expect(rail.destinations, hasLength(6));

    await tester.tap(find.descendant(
        of: find.byType(NavigationRail), matching: find.text('Habitudes')));
    await tester.pumpAndSettle();
    expect(find.text('page /habits'), findsOneWidget);
    expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        1);

    await tester.tap(find.descendant(
        of: find.byType(NavigationRail), matching: find.text('Graphe')));
    await tester.pumpAndSettle();
    expect(find.text('page /graph'), findsOneWidget);
  });
}
