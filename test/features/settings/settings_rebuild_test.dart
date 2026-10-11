import 'dart:async';

import 'package:cognicquest/core/database/app_database.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/settings/domain/user_settings.dart';
import 'package:cognicquest/features/settings/providers/settings_provider.dart';
import 'package:cognicquest/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Chantier 12 (B) : un réglage ne doit reconstruire que ce qui en dépend.
///
/// L'app est montée en entier (routeur, thème, raccourcis), sans session :
/// l'écran affiché est celui de connexion.
void main() {
  late AppDatabase db;
  late SupabaseClient client;
  late ProviderContainer container;

  Future<void> pumpApp(WidgetTester tester) async {
    db = AppDatabase(NativeDatabase.memory());
    client = SupabaseClient(
      'http://offline.invalid',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      supabaseClientProvider.overrideWithValue(client),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CognicQuestApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    // Hors du temps simulé : fermer la base attend de vraies opérations
    // asynchrones. Le client, créé dans le temps simulé, attendrait au
    // contraire des minuteurs qui n'avancent plus : sa fermeture n'est pas
    // attendue (client hors ligne, sans rafraîchissement ni temps réel).
    unawaited(client.dispose());
    await tester.runAsync(db.close);
  }

  /// Types des widgets reconstruits pendant [change].
  Future<List<Type>> rebuiltDuring(
    WidgetTester tester,
    void Function(SettingsNotifier notifier) change,
  ) async {
    final rebuilt = <Type>[];
    debugOnRebuildDirtyWidget =
        (element, _) => rebuilt.add(element.widget.runtimeType);
    try {
      change(container.read(settingsProvider.notifier));
      await tester.pump();
    } finally {
      debugOnRebuildDirtyWidget = null;
    }
    // Le scope Riverpod se marque lui-même à chaque notification de provider :
    // mécanique interne, rien de l'app n'est reconstruit pour autant.
    return rebuilt.where((t) => t != UncontrolledProviderScope).toList();
  }

  /// Monte l'app, exécute [body], et ferme toujours la base et le client :
  /// sinon un test en échec bloque les suivants.
  Future<void> withApp(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    await pumpApp(tester);
    try {
      await body();
    } finally {
      await disposeApp(tester);
    }
  }

  testWidgets('régler le volume d\'ambiance ne reconstruit rien',
      (tester) async {
    await withApp(tester, () async {
      final rebuilt =
          await rebuiltDuring(tester, (n) => n.setAmbientVolume(0.31));

      // Avant : 108 éléments, dont l'app, ses raccourcis, ses actions et
      // l'enveloppe de l'écran courant.
      expect(rebuilt, isEmpty);
    });
  });

  testWidgets('activer les animations réduites ne reconstruit pas l\'app',
      (tester) async {
    await withApp(tester, () async {
      final rebuilt =
          await rebuiltDuring(tester, (n) => n.toggleReduceMotion());

      expect(rebuilt, isNot(contains(CognicQuestApp)));
      expect(rebuilt, isNot(contains(MaterialApp)));
    });
  });

  testWidgets('changer la taille du texte reconstruit bien l\'app',
      (tester) async {
    await withApp(tester, () async {
      final rebuilt = await rebuiltDuring(
        tester,
        (n) => n.setTextScale(
          TextScalePreset.values.firstWhere(
            (preset) => preset != container.read(settingsProvider).textScale,
          ),
        ),
      );

      // Témoin : un réglage appliqué à la racine doit toujours prendre effet.
      expect(rebuilt, contains(CognicQuestApp));
    });
  });
}
