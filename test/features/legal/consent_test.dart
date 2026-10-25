import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/legal/consent.dart';
import 'package:cognicquest/features/legal/legal_info.dart';
import 'package:cognicquest/features/legal/legal_texts.dart';
import 'package:cognicquest/features/legal/views/legal_page.dart';
import 'package:cognicquest/features/metacognition/data/metacognition_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget app(GoRouter router) => ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          metacognitionRepositoryProvider.overrideWithValue(null),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          builder: (context, child) =>
              ConsentGate(router: router, child: child!),
        ),
      );

  GoRouter router() => GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('Accueil')),
          ),
          GoRoute(
            path: LegalRoute.privacy,
            builder: (_, __) => const LegalPage(document: privacyPolicy),
          ),
          GoRoute(
            path: LegalRoute.notice,
            builder: (_, __) => const LegalPage(document: legalNotice),
          ),
        ],
      );

  Future<void> tapContinue(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Continuer');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets(
      "première ouverture : bien-être facultatif, l'app s'ouvre sans lui",
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app(router()));
    await tester.pumpAndSettle();

    expect(find.text('Tes données, tes choix'), findsOneWidget);
    // Case non cochée : continuer reste possible (art. 7.4 RGPD).
    final button = find.widgetWithText(FilledButton, 'Continuer');
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tapContinue(tester);

    expect(find.text('Tes données, tes choix'), findsNothing);
    expect(find.text('Accueil'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('cq_consent_version'), LegalInfo.consentVersion);
    expect(prefs.getBool('cq_consent_wellbeing'), isFalse);
    // Preuve en attente d'envoi, au premier compte connecté.
    final pending = await const ConsentStore().pending();
    expect(pending.single.wellbeing, isFalse);
    expect(pending.single.userId, isNull);
  });

  testWidgets('case cochée : accord explicite au bien-être mémorisé',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app(router()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tapContinue(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('cq_consent_wellbeing'), isTrue);
    expect((await const ConsentStore().pending()).single.wellbeing, isTrue);
  });

  test('ancien accord (avant le choix séparé) : vaut accord au bien-être',
      () async {
    SharedPreferences.setMockInitialValues({'cq_consent_version': 1});
    final choice = await const ConsentStore().read();
    expect(choice.isCurrent, isTrue);
    expect(choice.wellbeing, isTrue);
  });

  testWidgets('déjà accepté : pas de bandeau', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'cq_consent_version': LegalInfo.consentVersion});
    await tester.pumpWidget(app(router()));
    await tester.pumpAndSettle();

    expect(find.text('Tes données, tes choix'), findsNothing);
    expect(find.text('Accueil'), findsOneWidget);
  });

  testWidgets('la politique s\'ouvre depuis le bandeau, sans lui par-dessus',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final r = router();
    await tester.pumpWidget(app(r));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Politique de confidentialité'));
    await tester.pumpAndSettle();

    expect(find.text('Tes données, tes choix'), findsNothing);
    expect(find.text('Durée de conservation'), findsOneWidget);

    // Retour : le bandeau revient tant que rien n'est accepté.
    r.go('/home');
    await tester.pumpAndSettle();
    expect(find.text('Tes données, tes choix'), findsOneWidget);
  });

  test('les champs d\'identité à compléter sont tous recensés', () {
    for (final value in LegalInfo.placeholders) {
      expect(value, startsWith('['));
    }
    // Rappel tant que l'éditeur n'est pas renseigné (cf. legal_info.dart).
    if (LegalInfo.placeholders.isNotEmpty) {
      printOnFailure('À compléter : ${LegalInfo.placeholders.join(', ')}');
    }
  });
}
