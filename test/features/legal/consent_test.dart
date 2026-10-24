import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/features/legal/consent.dart';
import 'package:cognicquest/features/legal/legal_info.dart';
import 'package:cognicquest/features/legal/legal_texts.dart';
import 'package:cognicquest/features/legal/views/legal_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget app(GoRouter router) => ProviderScope(
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

  testWidgets('première ouverture : accord explicite exigé, puis mémorisé',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app(router()));
    await tester.pumpAndSettle();

    expect(find.text('Tes données, tes choix'), findsOneWidget);
    final accept = find.widgetWithText(FilledButton, 'Accepter et continuer');
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.ensureVisible(accept);
    await tester.pumpAndSettle();
    await tester.tap(accept);
    await tester.pumpAndSettle();

    expect(find.text('Tes données, tes choix'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('cq_consent_version'), LegalInfo.consentVersion);
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
