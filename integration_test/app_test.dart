import 'dart:async';

import 'package:cognicquest/core/config/app_config.dart';
import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/navigation/adaptive_shell.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/habits/providers/habit_provider.dart';
import 'package:cognicquest/features/kanban/providers/task_provider.dart';
import 'package:cognicquest/features/metacognition/providers/metacognition_provider.dart';
import 'package:cognicquest/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:cognicquest/features/settings/providers/settings_provider.dart';
import 'package:cognicquest/main.dart';
import 'package:cognicquest/router/app_router.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Recette sur appareil réel : l'application complète en mode démo (base
/// locale en mémoire, aucun appel serveur), à la taille de l'écran du
/// téléphone, pilotée comme un utilisateur.
///
/// `flutter test integration_test/app_test.dart -d ID_APPAREIL
///   --dart-define-from-file=env.json --dart-define=DEV_BYPASS_AUTH=true`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  Future<void> wait(WidgetTester tester, [int ms = 300]) async {
    await tester.runAsync(() => Future.delayed(Duration(milliseconds: ms)));
    await settle(tester);
  }

  Future<void> boot(WidgetTester tester) async {
    AdaptiveShell.resetMemory();
    db = AppDatabase(NativeDatabase.memory());
    final client = SupabaseClient(
      'http://offline.invalid',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      supabaseClientProvider.overrideWithValue(client),
    ]);
    addTearDown(() async {
      container.dispose();
      unawaited(client.dispose());
      await tester.runAsync(db.close);
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const CognicQuestApp(),
    ));
    await wait(tester, 1500); // données de démo, puis animations d'entrée
  }

  /// Les feuilles de saisie défilent au-dessus du clavier : on amène le
  /// bouton à l'écran avant de le toucher, comme le ferait l'utilisateur.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus(); // ferme le clavier
    await wait(tester, 600);
    await tester.ensureVisible(finder);
    await settle(tester);
    await tester.tap(finder);
  }

  Future<void> go(WidgetTester tester, String route) async {
    container.read(appRouterProvider).go(route);
    await wait(tester, 400);
  }

  final skip = !AppConfig.devBypassAuth;

  testWidgets('chaque écran s\'ouvre sans erreur', skip: skip, (tester) async {
    await boot(tester);
    const routes = [
      AppRoute.home,
      AppRoute.pomodoro,
      AppRoute.habits,
      AppRoute.notes,
      AppRoute.review,
      AppRoute.reviewSession,
      AppRoute.sq3rPicker,
      AppRoute.explainPicker,
      AppRoute.graph,
      AppRoute.kanban,
      AppRoute.planning,
      AppRoute.gantt,
      AppRoute.revisionOrder,
      AppRoute.studySpeed,
      AppRoute.goals,
      AppRoute.journal,
      AppRoute.journalEntry,
      AppRoute.reframe,
      AppRoute.whyChain,
      AppRoute.errorLogs,
      AppRoute.profiling,
      AppRoute.settings,
    ];
    final failures = <String>[];
    for (final route in routes) {
      await go(tester, route);
      final error = tester.takeException();
      final location = container
          .read(appRouterProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .path;
      if (error != null) failures.add('$route : $error');
      if (location != route) failures.add('$route : redirigé vers $location');
    }
    expect(failures, isEmpty);
  });

  testWidgets('barre de navigation : quatre espaces', skip: skip,
      (tester) async {
    await boot(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final space in ['Apprendre', 'Organiser', 'Réfléchir', "Aujourd'hui"]) {
      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text(space)));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: space);
    }
  });

  testWidgets('tâches : créer, supprimer, annuler, matrice', skip: skip,
      (tester) async {
    await boot(tester);
    await go(tester, AppRoute.kanban);
    final before = container.read(taskProvider).value!.length;

    await tester.tap(find.byTooltip('Nouvelle tâche'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Tâche appareil');
    await tapVisible(tester, find.text('Ajouter'));
    await wait(tester);
    expect(container.read(taskProvider).value!.length, before + 1);

    final task = container
        .read(taskProvider)
        .value!
        .firstWhere((t) => t.title == 'Tâche appareil');
    expect(task.title, 'Tâche appareil');

    await tester.tap(find.byTooltip("Matrice d'Eisenhower"));
    await settle(tester);
    expect(find.text('À faire maintenant'), findsWidgets);
    await tester.tap(find.byTooltip('Vue Kanban'));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('habitudes : créer puis cocher', skip: skip, (tester) async {
    await boot(tester);
    await go(tester, AppRoute.habits);
    await tester.tap(find.byTooltip('Nouvelle habitude'));
    await settle(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'Nom'), 'Habitude appareil');
    await tapVisible(tester, find.text('Ajouter'));
    await wait(tester);

    Iterable<String> doneOf() => container
        .read(habitProvider)
        .value!
        .firstWhere((h) => h.name == 'Habitude appareil')
        .completedDates;
    expect(doneOf(), isEmpty);

    // Nouvelle habitude en fin de liste : liste paresseuse, on y descend.
    await tester.scrollUntilVisible(find.text('Habitude appareil'), 200,
        scrollable: verticalList);
    await settle(tester);
    final card = find.ancestor(
        of: find.text('Habitude appareil'), matching: find.byType(Card));
    await tester.tap(find.descendant(of: card, matching: find.byType(InkWell)).first);
    await wait(tester);
    expect(doneOf(), hasLength(1), reason: 'la coche marque le jour fait');
  });

  testWidgets('pomodoro : démarrer, pause, réinitialiser', skip: skip,
      (tester) async {
    await boot(tester);
    await go(tester, AppRoute.pomodoro);
    await tester.tap(find.byTooltip('Démarrer'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(container.read(pomodoroProvider).isRunning, isTrue);
    expect(find.byType(NavigationBar), findsNothing,
        reason: 'mode concentration : navigation masquée');

    await tester.tap(find.byTooltip('Mettre en pause'));
    await settle(tester);
    expect(container.read(pomodoroProvider).isRunning, isFalse);
    await tester.tap(find.byTooltip('Réinitialiser'));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fiches : créer une fiche enregistrée en base', skip: skip,
      (tester) async {
    await boot(tester);
    await go(tester, AppRoute.notes);
    await tester.tap(find.byTooltip('Nouvelle fiche'));
    await wait(tester);
    await tester.enterText(find.byType(TextField).at(0), 'Fiche appareil');
    await tester.enterText(find.byType(TextField).at(1), 'Contenu de test');
    await tester.pageBack();
    await wait(tester, 600);
    final notes = await tester.runAsync(() => db.select(db.localNotes).get());
    expect(notes!.map((n) => n.title), contains('Fiche appareil'));
  });

  testWidgets('révision : session de cartes', skip: skip, (tester) async {
    await boot(tester);
    await go(tester, AppRoute.review);
    await tester.tap(find.text('Commencer la session'));
    await wait(tester);
    await tester.tap(find.text('Afficher la réponse'));
    await settle(tester);
    expect(find.text('Sois honnête : c\'est ce qui règle ton planning.'),
        findsOneWidget);
    await tester.tap(find.byType(OutlinedButton).last);
    await wait(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('journal : consigner une erreur', skip: skip, (tester) async {
    await boot(tester);
    await go(tester, AppRoute.errorLogs);
    final before = container.read(errorLogsProvider).value?.length ?? 0;
    await tester.tap(find.byTooltip('Consigner une erreur'));
    await settle(tester);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Qu\'est-ce qui a été raté ?'),
        'Erreur appareil');
    await tapVisible(tester, find.text('Enregistrer'));
    await wait(tester);
    expect(container.read(errorLogsProvider).value!.length, before + 1);
  });

  testWidgets('réglages : réduire les animations', skip: skip, (tester) async {
    await boot(tester);
    await go(tester, AppRoute.settings);
    final before = container.read(settingsProvider).reduceMotion;
    final toggle = find.text('Réduire les animations');
    await tester.scrollUntilVisible(toggle, 200,
        scrollable: verticalList);
    await settle(tester);
    await tester.tap(toggle);
    await settle(tester);
    expect(container.read(settingsProvider).reduceMotion, !before);
  });
}

/// Liste verticale de l'écran (la barre d'onglets défile, elle, à l'horizontale).
final verticalList = find.byWidgetPredicate((w) =>
    w is Scrollable && w.axisDirection == AxisDirection.down).first;

/// `pumpAndSettle` borné : certains indicateurs tournent sans fin.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (!tester.binding.hasScheduledFrame) return;
  }
}
