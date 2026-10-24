import 'dart:async';
import 'dart:io';

import 'package:cognicquest/core/config/app_config.dart';
import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/core/theme/tokens.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/dashboard/views/dashboard_page.dart';
import 'package:cognicquest/features/dev/demo_seed.dart';
import 'package:cognicquest/features/graph/views/graph_page.dart';
import 'package:cognicquest/features/habits/views/habits_page.dart';
import 'package:cognicquest/features/kanban/views/kanban_page.dart';
import 'package:cognicquest/features/metacognition/views/journal_hub_page.dart';
import 'package:cognicquest/features/notes/views/notes_page.dart';
import 'package:cognicquest/features/planning/views/revision_speed_page.dart';
import 'package:cognicquest/features/planning/views/planning_hub_page.dart';
import 'package:cognicquest/features/pomodoro/views/pomodoro_page.dart';
import 'package:cognicquest/features/review/views/review_home_page.dart';
import 'package:cognicquest/features/settings/views/settings_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Aucun écran principal ne déborde, quelle que soit la taille de l'écran ou
/// du texte (bande jaune et noire « OVERFLOWED BY … PIXELS » en debug).
///
/// Chaque écran est monté sur une base en mémoire remplie avec le jeu de
/// démo, hors ligne, puis affiché à 4 tailles d'écran × 3 tailles de texte.
/// Charge les polices de l'application (Plus Jakarta Sans et Fraunces,
/// versionnées dans `assets/`). La police par défaut des tests (« Ahem », un carré plein par
/// caractère) est bien plus large et haute qu'un vrai texte : elle
/// inventerait des débordements et en masquerait d'autres. Un fichier
/// manquant fait donc échouer le test au lieu d'y retomber en silence.
Future<void> _loadAppFont() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) {
        throw StateError('Police introuvable : ${file.path}');
      }
      loader
          .addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }

  await load(appFontFamily, [
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      'assets/fonts/plus_jakarta_sans/PlusJakartaSans-$weight.ttf',
  ]);
  // Titres en serif éditoriale.
  await load(appSerifFamily, [
    for (final weight in ['Regular', 'Medium', 'SemiBold'])
      'assets/fonts/fraunces/Fraunces-$weight.ttf',
  ]);
}

/// Fait défiler la liste principale (verticale) jusqu'en bas, par pas.
Future<void> _scrollToEnd(WidgetTester tester) async {
  final vertical = find.byWidgetPredicate((widget) =>
      widget is Scrollable && widget.axisDirection == AxisDirection.down);
  if (vertical.evaluate().isEmpty) return;
  final scrollable = vertical.first;
  final state = tester.state<ScrollableState>(scrollable);
  for (var i = 0; i < 30; i++) {
    final position = state.position;
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo(
        (position.pixels + position.viewportDimension * 0.8)
            .clamp(0, position.maxScrollExtent));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(_loadAppFont);

  const sizes = [
    Size(320, 640),
    Size(360, 800),
    Size(412, 915),
    Size(1280, 800),
  ];
  const textScales = [1.0, 1.3, 2.0];

  final screens = <String, Widget Function()>{
    'Tableau de bord': () => const DashboardPage(),
    'Pomodoro': () => const PomodoroPage(),
    'Tâches (Kanban)': () => const KanbanPage(),
    'Fiches': () => const NotesPage(),
    'Réviser': () => const ReviewHomePage(),
    'Habitudes': () => const HabitsPage(),
    'Graphe': () => const GraphPage(),
    'Planification': () => const PlanningHubPage(),
    'Ordre & rentabilité': () => const RevisionSpeedPage(),
    'Vitesse de travail': () =>
        const RevisionSpeedPage(initialTab: RevisionSpeedTab.speed),
    'Journal': () => const JournalHubPage(),
    'Réglages': () => const SettingsPage(),
  };

  // Écrans à débordement connu, ignorés en attendant leur correction (nom →
  // description). Vide depuis le 2026-10-14 : tous les écrans sont corrigés.
  const knownOverflows = <String, String>{};

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    final known = knownOverflows[name];
    testWidgets('$name : aucun débordement',
        skip: known != null, // raison : knownOverflows[name]
        (tester) async {
      // Base créée et remplie en temps réel : créée dans le temps simulé de
      // testWidgets, elle attendrait des minuteurs qui n'avancent pas.
      late AppDatabase db;
      late SupabaseClient client;
      late ProviderContainer container;
      await tester.runAsync(() async {
        db = AppDatabase(NativeDatabase.memory());
        client = SupabaseClient('http://offline.invalid', 'anon-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false));
        container = ProviderContainer(overrides: [
          appDatabaseProvider.overrideWithValue(db),
          supabaseClientProvider.overrideWithValue(client),
          currentUserIdProvider.overrideWithValue(AppConfig.devUserId),
        ]);
        final seed = FutureProvider<void>((ref) => runDemoSeed(ref, db));
        await container.read(seed.future);
      });

      final problems = <String>{};
      final original = FlutterError.onError;
      var current = '';
      FlutterError.onError = (details) {
        final first = details.exceptionAsString().split('\n').first;
        problems.add('$current → $first');
      };

      try {
        for (final size in sizes) {
          for (final scale in textScales) {
            current = '${size.width.toInt()}×${size.height.toInt()}, '
                'texte ${(scale * 100).round()} %';
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            await tester.pumpWidget(UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                theme: AppTheme.light.copyWith(
                  textTheme:
                      AppTheme.light.textTheme.apply(fontFamily: appFontFamily),
                ),
                routerConfig: GoRouter(routes: [
                  GoRoute(path: '/', builder: (_, __) => screen()),
                ]),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(fontFamily: appFontFamily),
                    child: child!,
                  ),
                ),
              ),
            ));
            // Laisse arriver les données (flux Drift, calculs asynchrones).
            for (var i = 0; i < 6; i++) {
              await tester.runAsync(
                  () => Future<void>.delayed(const Duration(milliseconds: 20)));
              await tester.pump(const Duration(milliseconds: 100));
            }
            // Une liste ne construit que ce qui est visible : on fait défiler
            // chaque écran jusqu'en bas pour que tout soit mesuré.
            await _scrollToEnd(tester);
          }
        }
      } finally {
        FlutterError.onError = original;
        await tester.pumpWidget(const SizedBox());
        tester.view.reset();
        container.dispose();
        unawaited(client.dispose());
        // Base en mémoire : sa fermeture n'est pas attendue (elle attendrait
        // des flux ouverts dans le temps simulé).
        unawaited(db.close());
        // Laisse partir les minuteurs restants (fermetures, flux Drift,
        // sauvegardes différées) avant la fin du test.
        await tester.pump(const Duration(seconds: 10));
      }

      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }
}
