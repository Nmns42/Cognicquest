import 'dart:async';

import 'package:cognicquest/core/config/app_config.dart';
import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/navigation/adaptive_shell.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/dashboard/models/dashboard_module.dart';
import 'package:cognicquest/features/dashboard/providers/dashboard_layout_provider.dart';
import 'package:cognicquest/features/kanban/providers/task_provider.dart';
import 'package:cognicquest/main.dart';
import 'package:cognicquest/shared/models/task_model.dart';
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Recette de bout en bout du MVP : l'application complète (vrai routeur,
/// vrais écrans, base locale, données de démo), pilotée comme un utilisateur.
///
/// Le mode démo (aucun appel serveur) est une constante de compilation :
/// `flutter test --dart-define=DEV_BYPASS_AUTH=true test/e2e`
/// Sans elle (simple `flutter test`), ces tests sont ignorés.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  Future<void> boot(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
      // Fermetures en temps réel : dans l'horloge simulée du test, elles
      // attendraient indéfiniment.
      // Le client hors ligne ne rend jamais la main à sa fermeture : on ne
      // l'attend pas (comme les autres tests du projet).
      unawaited(client.dispose());
      await tester.runAsync(db.close);
    });

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const CognicQuestApp(),
    ));
    // Données de démo écrites en base, puis animations d'entrée.
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await settle(tester);
  }

  Future<void> wait(WidgetTester tester, [int ms = 300]) async {
    await tester.runAsync(() => Future.delayed(Duration(milliseconds: ms)));
    await settle(tester);
  }

  Task task(String title) => container
      .read(taskProvider)
      .value!
      .firstWhere((t) => t.title == title);

  testWidgets(
    'parcours complet sur grand écran',
    skip: !AppConfig.devBypassAuth,
    (tester) async {
      await boot(tester, const Size(1400, 900));

      // ── Accueil : épuré (pas de nom en double, pas de titres) ─────────
      expect(find.text('CognicQuest'), findsOneWidget,
          reason: 'le nom seulement dans la navigation');
      expect(find.byTooltip('Voir tout : Révisions du jour'), findsOneWidget);
      expect(find.byTooltip('Réglages'), findsOneWidget,
          reason: 'une seule entrée vers les réglages');
      await tester.tap(find.byTooltip('Personnaliser le tableau de bord'));
      await settle(tester);
      expect(find.text('Habitudes du jour'), findsNothing,
          reason: 'module retiré');
      await tester.tap(find.text('Progrès du jour'));
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape); // ferme
      await settle(tester);
      expect(container.read(dashboardLayoutProvider).visibleModules,
          contains(DashboardModule.stats));
      // ── Menu latéral rétractable ──────────────────────────────────────
      await tester.tap(find.byTooltip('Réduire le menu'));
      await settle(tester);
      await tester.tap(find.byTooltip('Déployer le menu'));
      await settle(tester);

      // ── Tâches : création, glisser à la souris, corbeille, matrice ────
      await tester.tap(find.text('Organiser'));
      await settle(tester);
      await tester.tap(find.byTooltip('Nouvelle tâche'));
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, 'Tâche de recette');
      await tester.tap(find.text('Ajouter'));
      await wait(tester);
      expect(find.text('Tâche de recette'), findsOneWidget);

      // Septième de sa colonne : on l'amène d'abord à l'écran.
      await tester.ensureVisible(find.text('Tâche de recette'));
      await settle(tester);
      final from = tester.getCenter(find.text('Tâche de recette'));
      final to = tester.getCenter(find.text('Terminé').first);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: from - const Offset(0, 30));
      await mouse.moveTo(from);
      await tester.pump();
      await mouse.down(from);
      for (var i = 1; i <= 12; i++) {
        await mouse.moveTo(Offset.lerp(from, to, i / 12)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await mouse.up();
      await mouse.removePointer();
      await wait(tester);
      expect(task('Tâche de recette').status, TaskStatus.done);

      // Corbeille en un clic, puis « Annuler ».
      final card = find.ancestor(
          of: find.text('Tâche de recette'), matching: find.byType(Card));
      await tester.tap(find.descendant(
          of: card, matching: find.byTooltip('Supprimer la tâche')));
      await wait(tester);
      expect(find.text('Tâche de recette'), findsNothing);
      await tester.tap(find.text('Annuler'));
      await wait(tester);
      expect(find.text('Tâche de recette'), findsOneWidget);

      await tester.tap(find.byTooltip("Matrice d'Eisenhower"));
      await settle(tester);
      expect(find.text('À faire maintenant'), findsWidgets);
      await tester.tap(find.byTooltip('Vue Kanban'));
      await settle(tester);

      // ── Fiches : menu « / » et lien [[…]] ─────────────────────────────
      await tester.tap(find.text('Apprendre'));
      await settle(tester);
      await tester.tap(find.byTooltip('Nouvelle fiche'));
      await wait(tester);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Fiche recette');
      final content = fields.at(1);
      await tester.enterText(content, '/');
      await settle(tester);
      await tester.tap(find.text('Titre').last);
      await settle(tester);
      expect(tester.widget<TextField>(content).controller!.text, '# ');

      await tester.enterText(content, '# Cardio [');
      await tester.enterText(content, '# Cardio [[');
      await settle(tester);
      expect(find.text('Lier une fiche'), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher une fiche'), 'dérivées');
      await settle(tester);
      await tester.tap(find.text('Chapitre 2 – Dérivées'));
      await settle(tester);
      expect(tester.widget<TextField>(content).controller!.text,
          '# Cardio [[Chapitre 2 – Dérivées]]');

      await tester.pageBack();
      await wait(tester, 500);
      final notes = await db.select(db.localNotes).get();
      final source = notes.firstWhere((n) => n.title == 'Fiche recette');
      final target = notes.firstWhere((n) => n.title == 'Chapitre 2 – Dérivées');
      final links = await db.select(db.localNoteLinks).get();
      expect(
        links.any((l) => l.sourceId == source.id && l.targetId == target.id),
        isTrue,
        reason: '[[Chapitre 2 – Dérivées]] relie les deux fiches',
      );

      // ── Explorateur : dossier, rangement, filtre ─────────────────────
      await tester.tap(find.text('Nouveau dossier'));
      await settle(tester);
      await tester.enterText(
          find.widgetWithText(TextField, 'Nom du dossier'), 'Cardiologie');
      await tester.tap(find.text('Valider'));
      await wait(tester);
      final recetteCard = find.ancestor(
          of: find.text('Fiche recette'), matching: find.byType(Card));
      await tester.tap(find.descendant(
          of: recetteCard, matching: find.byTooltip('Ranger dans un dossier')));
      await settle(tester);
      await tester.tap(find.text('Cardiologie').last);
      await wait(tester);
      await tester.tap(find.text('Cardiologie').first);
      await settle(tester);
      expect(find.text('Fiche recette'), findsOneWidget);
      expect(find.text('Chapitre 2 – Dérivées'), findsNothing,
          reason: 'le dossier ne montre que ce qui y est rangé');
      await tester.tap(find.text('Tout'));
      await settle(tester);

      // ── Pomodoro : mode concentration ─────────────────────────────────
      await tester.tap(find.text("Aujourd'hui"));
      await settle(tester);
      await tester.tap(find.text('Concentration'));
      await settle(tester);
      expect(find.byType(NavigationRail), findsOneWidget);
      await tester.tap(find.byTooltip('Démarrer'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(NavigationRail), findsNothing,
          reason: 'la navigation disparaît pendant la session');
      await tester.tap(find.byTooltip('Mettre en pause'));
      await settle(tester);
      expect(find.byType(NavigationRail), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'téléphone : accordéon des tâches et barre à quatre espaces',
    skip: !AppConfig.devBypassAuth,
    (tester) async {
      await boot(tester, const Size(390, 844));

      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.text('Organiser'));
      await settle(tester);
      expect(find.text('À FAIRE'), findsOneWidget);
      expect(find.text('EN COURS'), findsOneWidget);

      await tester.tap(find.text('EN COURS'));
      await settle(tester);
      expect(find.text("Exercices d'intégration par parties"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

/// `pumpAndSettle` borné : certains indicateurs tournent sans fin.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (!tester.binding.hasScheduledFrame) return;
  }
}
