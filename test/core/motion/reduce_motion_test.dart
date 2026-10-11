import 'dart:async';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/core/motion/reduce_motion.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/auth/views/login_page.dart';
import 'package:cognicquest/features/settings/providers/settings_provider.dart';
import 'package:cognicquest/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// « Animations réduites » : point central (réglage de l'app OU réglage
/// système), appliqué à la racine de l'app réelle.
void main() {
  late AppDatabase db;
  late SupabaseClient client;
  late ProviderContainer container;

  Future<void> withApp(WidgetTester tester, Future<void> Function() body) async {
    db = AppDatabase(NativeDatabase.memory());
    client = SupabaseClient('http://offline.invalid', 'anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      supabaseClientProvider.overrideWithValue(client),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const CognicQuestApp()));
    await tester.pumpAndSettle();
    try {
      await body();
    } finally {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      // Client créé dans le temps simulé : sa fermeture n'est pas attendue.
      unawaited(client.dispose());
      await tester.runAsync(db.close);
    }
  }

  MaterialApp materialApp(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp));

  /// Valeur que lisent les écrans (via [Motion]).
  bool screenSeesReduced(WidgetTester tester) =>
      Motion.reduced(tester.element(find.byType(LoginPage)));

  void setSystemFlags(WidgetTester tester, FakeAccessibilityFeatures flags) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = flags;
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  testWidgets('(b) réglage et système désactivés : rien ne change',
      (tester) async {
    await withApp(tester, () async {
      expect(screenSeesReduced(tester), isFalse);
      // Thème strictement identique à celui du provider, styles par défaut.
      expect(identical(materialApp(tester).theme,
          container.read(appThemeProvider)), isTrue);
      expect(materialApp(tester).themeAnimationStyle, isNull);
    });
  });

  testWidgets('(c) drapeau système (Android, web) et réglage de l\'app '
      'désactivé : animations réduites', (tester) async {
    setSystemFlags(tester,
        const FakeAccessibilityFeatures(disableAnimations: true));
    await withApp(tester, () async {
      expect(container.read(reduceMotionProvider), isFalse);
      expect(screenSeesReduced(tester), isTrue);
      expect(materialApp(tester).themeAnimationStyle,
          AnimationStyle.noAnimation);
    });
  });

  testWidgets('(c) drapeau reduceMotion d\'iOS : animations réduites',
      (tester) async {
    setSystemFlags(tester, const FakeAccessibilityFeatures(reduceMotion: true));
    await withApp(tester, () async {
      expect(screenSeesReduced(tester), isTrue);
    });
  });

  testWidgets('(c) un changement du réglage système s\'applique en direct',
      (tester) async {
    await withApp(tester, () async {
      expect(screenSeesReduced(tester), isFalse);
      setSystemFlags(tester,
          const FakeAccessibilityFeatures(disableAnimations: true));
      await tester.pump();
      expect(screenSeesReduced(tester), isTrue);
    });
  });

  testWidgets('(d) le réglage de l\'app s\'applique immédiatement, dans les '
      'deux sens', (tester) async {
    await withApp(tester, () async {
      final notifier = container.read(settingsProvider.notifier);

      notifier.toggleReduceMotion();
      await tester.pump();
      expect(screenSeesReduced(tester), isTrue);
      expect(materialApp(tester).themeAnimationStyle,
          AnimationStyle.noAnimation);

      notifier.toggleReduceMotion();
      await tester.pump();
      expect(screenSeesReduced(tester), isFalse);
      expect(identical(materialApp(tester).theme,
          container.read(appThemeProvider)), isTrue);
    });
  });

  group('(a) transition de page', () {
    /// Position de la nouvelle page une frame après la navigation, puis une
    /// fois toutes les animations terminées.
    Future<(Rect, Rect)> navigate(WidgetTester tester) async {
      final link = find.text('Créer un compte');
      await tester.ensureVisible(link.last);
      await tester.tap(link.last);
      await tester.pump(); // la navigation est traitée
      await tester.pump(const Duration(milliseconds: 16)); // une frame
      final target = find.text('Rejoins CognicQuest');
      final firstFrame = tester.getRect(target);
      await tester.pumpAndSettle();
      return (firstFrame, tester.getRect(target));
    }

    testWidgets('réduite : la page est à sa place dès la première frame',
        (tester) async {
      await withApp(tester, () async {
        container.read(settingsProvider.notifier).toggleReduceMotion();
        await tester.pump();

        final (firstFrame, settled) = await navigate(tester);
        expect(firstFrame, settled);
      });
    });

    testWidgets('normale : la transition d\'origine est conservée',
        (tester) async {
      await withApp(tester, () async {
        final (firstFrame, settled) = await navigate(tester);
        // Une frame après la navigation, la page est encore en mouvement.
        expect(firstFrame, isNot(settled));
      });
    });
  });
}
