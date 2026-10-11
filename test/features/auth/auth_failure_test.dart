import 'package:cognicquest/core/config/app_config.dart';
import 'package:cognicquest/features/auth/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AuthFailure.from', () {
    test('traduit des identifiants invalides', () {
      final failure = AuthFailure.from(
        const AuthException('Invalid login credentials',
            code: 'invalid_credentials'),
      );

      expect(failure.message, 'Email ou mot de passe incorrect.');
      expect(failure.code, 'invalid_credentials');
    });

    test('traduit un email non confirmé', () {
      final failure = AuthFailure.from(
        const AuthException('Email not confirmed'),
      );

      expect(failure.message, contains('pas encore confirmé'));
    });

    test('traduit un compte déjà existant', () {
      final failure = AuthFailure.from(
        const AuthException('User already registered'),
      );

      expect(failure.message, 'Un compte existe déjà avec cet email.');
    });

    test('traduit un mot de passe trop court en citant la longueur minimale', () {
      final failure = AuthFailure.from(
        const AuthException('Password should be at least 6 characters'),
      );

      expect(failure.message, contains('${AppConfig.minPasswordLength}'));
    });

    test('retombe sur un message générique pour une erreur inconnue', () {
      final failure = AuthFailure.from(Exception('boom'));

      expect(failure.message, contains('Connexion impossible'));
      expect(failure.code, isNull);
    });

    test('est idempotent sur un AuthFailure déjà construit', () {
      const original = AuthFailure('déjà traduit', code: 'x');

      expect(identical(AuthFailure.from(original), original), isTrue);
    });
  });

  group('AppConfig.emailPattern', () {
    test('accepte les adresses valides', () {
      for (final email in [
        'a@b.co',
        'mehdi.nafaa@exemple.fr',
        'prenom+tag@sous.domaine.org',
      ]) {
        expect(AppConfig.emailPattern.hasMatch(email), isTrue, reason: email);
      }
    });

    test('refuse les adresses invalides', () {
      for (final email in [
        'admin',
        'a@b',
        'a b@c.fr',
        '@exemple.fr',
        'deux@@exemple.fr',
      ]) {
        expect(AppConfig.emailPattern.hasMatch(email), isFalse, reason: email);
      }
    });
  });

  group('AppConfig.devBypassAuth', () {
    // Opt-in explicite par `--dart-define=DEV_BYPASS_AUTH=true` ; le verrou
    // `kDebugMode` garantit qu'il reste éteint en release.
    test('est inactif par défaut, même en debug', () {
      expect(AppConfig.devBypassAuth, isFalse);
    });
  });
}
