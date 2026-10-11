import 'dart:async';

import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:cognicquest/features/auth/views/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('PasswordRecoveryNotifier', () {
    late StreamController<AuthState> events;
    late ProviderContainer container;

    setUp(() {
      events = StreamController<AuthState>();
      container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => events.stream),
        ],
      );
      // Garde le provider en vie, comme le fait le routeur.
      container.listen(passwordRecoveryProvider, (_, __) {});
    });

    tearDown(() {
      container.dispose();
      events.close();
    });

    Future<void> emit(AuthChangeEvent event) async {
      events.add(AuthState(event, null));
      await Future<void>.delayed(Duration.zero);
    }

    test('est faux au démarrage', () {
      expect(container.read(passwordRecoveryProvider), isFalse);
    });

    test('passe à vrai sur un évènement passwordRecovery', () async {
      await emit(AuthChangeEvent.passwordRecovery);

      expect(container.read(passwordRecoveryProvider), isTrue);
    });

    test('reste vrai malgré un rafraîchissement de jeton', () async {
      await emit(AuthChangeEvent.passwordRecovery);
      await emit(AuthChangeEvent.tokenRefreshed);

      expect(container.read(passwordRecoveryProvider), isTrue);
    });

    test('repasse à faux une fois le mot de passe enregistré', () async {
      await emit(AuthChangeEvent.passwordRecovery);
      container.read(passwordRecoveryProvider.notifier).complete();

      expect(container.read(passwordRecoveryProvider), isFalse);
    });

    test('repasse à faux à la déconnexion (bouton Annuler)', () async {
      await emit(AuthChangeEvent.passwordRecovery);
      await emit(AuthChangeEvent.signedOut);

      expect(container.read(passwordRecoveryProvider), isFalse);
    });
  });

  test('AuthFailure traduit un mot de passe identique à l\'ancien', () {
    final failure = AuthFailure.from(
      const AuthException(
        'New password should be different from the old password.',
        code: 'same_password',
      ),
    );

    expect(failure.message, contains('différent de l\'ancien'));
  });

  group('ResetPasswordPage', () {
    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ResetPasswordPage())),
      );
      // `AuthController.build` est asynchrone : au premier frame l'état est
      // `loading` et le bouton affiche un indicateur au lieu de son libellé.
      await tester.pump();
    }

    // Le bouton peut sortir de la surface de test (800×600) : on le fait
    // défiler avant de le toucher.
    Future<void> tapSave(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();
    }

    testWidgets('refuse un mot de passe vide', (tester) async {
      await pumpPage(tester);

      await tapSave(tester);

      expect(find.text('Choisis un nouveau mot de passe.'), findsOneWidget);
    });

    testWidgets('refuse une confirmation différente', (tester) async {
      await pumpPage(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'motdepasse1');
      await tester.enterText(fields.at(1), 'motdepasse2');
      await tapSave(tester);

      expect(
        find.text('Les mots de passe ne correspondent pas.'),
        findsOneWidget,
      );
    });
  });
}
