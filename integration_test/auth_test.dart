import 'package:cognicquest/core/config/app_config.dart';
import 'package:cognicquest/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Parcours d'authentification réel, contre le projet Supabase de env.json.
///
/// `flutter test integration_test/auth_test.dart -d ID_APPAREIL
///   --dart-define-from-file=env.json
///   [--dart-define=TEST_EMAIL=… --dart-define=TEST_PASSWORD=…]`
///
/// Sans TEST_EMAIL / TEST_PASSWORD, la connexion réussie est ignorée.
const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester tester, [int seconds = 1]) async {
    await tester.runAsync(() => Future.delayed(Duration(seconds: seconds)));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (!tester.binding.hasScheduledFrame) return;
    }
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  // Sur appareil, la connexion au clavier s'ouvre en asynchrone : on laisse
  // le champ prendre le focus avant de saisir.
  Future<void> type(WidgetTester tester, String label, String text) async {
    await tester.tap(field(label));
    await wait(tester);
    await tester.enterText(field(label), text);
    await wait(tester);
  }

  // Ferme le clavier avant de valider, comme un utilisateur.
  Future<void> submit(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Se connecter'));
  }

  testWidgets('connexion : validation, refus, puis succès',
      skip: AppConfig.devBypassAuth, (tester) async {
    await app.main();
    await wait(tester, 2);
    if (Supabase.instance.client.auth.currentSession != null) {
      await Supabase.instance.client.auth.signOut();
      await wait(tester, 2);
    }
    expect(find.text('Se connecter'), findsWidgets);

    // Champs vides : messages de validation, aucun appel serveur.
    await submit(tester);
    await wait(tester);
    expect(find.text('Entre ton adresse email.'), findsOneWidget);
    expect(find.text('Entre ton mot de passe.'), findsOneWidget);

    await type(tester, 'Email', 'pas-un-email');
    await submit(tester);
    await wait(tester);
    expect(find.text('Cette adresse email n\'est pas valide.'), findsOneWidget);

    // Mauvais mot de passe : refus du serveur, message traduit.
    await type(tester, 'Email', 'inconnu.cognicquest@example.com');
    await type(tester, 'Mot de passe', 'mauvais-mdp');
    await submit(tester);
    await wait(tester, 4);
    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);

    if (_email.isEmpty) {
      debugPrint('TEST_EMAIL absent : connexion réussie non testée.');
      return;
    }
    await type(tester, 'Email', _email);
    await type(tester, 'Mot de passe', _password);
    await submit(tester);
    await wait(tester, 6);
    expect(Supabase.instance.client.auth.currentSession, isNotNull);
    expect(find.byType(NavigationBar), findsOneWidget,
        reason: 'arrivée sur l\'accueil');
    await Supabase.instance.client.auth.signOut();
    await wait(tester, 2);
  });
}
