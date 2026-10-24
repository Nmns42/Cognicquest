import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/sync_queue.dart';
import '../../sync/providers/sync_coordinator.dart';
import '../data/oauth_loopback.dart';

/// Client Supabase exposé via Riverpod plutôt que via le singleton global :
/// les couches métier n'ont ainsi jamais besoin d'importer `Supabase.instance`
/// directement, ce qui les rend testables (override du provider en test).
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Flux des changements d'état d'authentification (connexion, déconnexion,
/// rafraîchissement de token, retour d'OAuth par deep link…).
final authStateChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange,
);

/// Session courante, recalculée à chaque évènement d'authentification.
///
/// `Supabase.initialize()` restaure la session persistée avant de rendre la
/// main, donc cette valeur est déjà correcte au premier build.
final sessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentSession;
});

final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(sessionProvider)?.user,
);

/// `true` quand l'utilisateur a le droit d'accéder aux écrans protégés.
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(sessionProvider) != null || AppConfig.devBypassAuth,
);

/// Identifiant utilisateur, ou `null`. Toute écriture Supabase doit passer par
/// là : c'est ce qui manquait au Lot 0 et qui rendait le module Habitudes muet.
///
/// En mode `DEV_BYPASS_AUTH` sans session, renvoie l'utilisateur fictif local
/// pour que l'app reste testable sans compte.
final currentUserIdProvider = Provider<String?>(
  (ref) =>
      ref.watch(currentUserProvider)?.id ??
      (AppConfig.devBypassAuth ? AppConfig.devUserId : null),
);

/// `true` entre l'ouverture d'un lien « mot de passe oublié » et l'enregistrement
/// du nouveau mot de passe.
///
/// Le lien ouvre une vraie session : sans ce drapeau, le routeur envoyait
/// l'utilisateur sur l'accueil, connecté, sans jamais lui demander de choisir
/// un nouveau mot de passe. `onAuthStateChange` rejoue son dernier évènement
/// aux abonnés tardifs : un `passwordRecovery` reçu au démarrage (deep link)
/// n'est donc pas perdu.
class PasswordRecoveryNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(authStateChangesProvider, (_, next) {
      switch (next.valueOrNull?.event) {
        case AuthChangeEvent.passwordRecovery:
          state = true;
        case AuthChangeEvent.signedOut:
          state = false;
        default:
          break;
      }
    }, fireImmediately: true);
    return false;
  }

  /// Le nouveau mot de passe est enregistré : retour au parcours normal.
  void complete() => state = false;
}

final passwordRecoveryProvider =
    NotifierProvider<PasswordRecoveryNotifier, bool>(
  PasswordRecoveryNotifier.new,
);

/// Résultat d'une inscription : distingue le cas « connecté immédiatement » du
/// cas « il faut confirmer l'email », que l'ancien code confondait.
enum SignUpOutcome { signedIn, emailConfirmationRequired }

/// Contrôleur des actions d'authentification.
///
/// L'état `AsyncValue<void>` porte uniquement le chargement et l'erreur ; la
/// session elle-même est lue via [sessionProvider], qui suit le flux Supabase.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(AuthFailure.from(error), stackTrace);
      return false;
    }
  }

  Future<SignUpOutcome?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
        emailRedirectTo: AppConfig.authRedirectUrl,
      );
      state = const AsyncValue.data(null);
      return response.session != null
          ? SignUpOutcome.signedIn
          : SignUpOutcome.emailConfirmationRequired;
    } catch (error, stackTrace) {
      state = AsyncValue.error(AuthFailure.from(error), stackTrace);
      return null;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    if (LoopbackOAuthReceiver.isNeeded) return _signInWithGoogleLoopback();
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.authRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // Le retour se fait par deep link : la session arrivera via
      // `onAuthStateChange`, et le routeur redirigera tout seul.
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(AuthFailure.from(error), stackTrace);
      return false;
    }
  }

  /// Windows / Linux : pas de schéma d'URL pour revenir dans l'app. Le
  /// navigateur renvoie le code PKCE à un serveur local éphémère
  /// (`127.0.0.1`), échangé ici contre la session.
  Future<bool> _signInWithGoogleLoopback() async {
    final receiver = LoopbackOAuthReceiver();
    try {
      final redirect = await receiver.start();
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirect,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      final code = await receiver.waitForCode();
      await _client.auth.exchangeCodeForSession(code);
      state = const AsyncValue.data(null);
      return true;
    } on OAuthLoopbackException catch (error, stackTrace) {
      state = AsyncValue.error(AuthFailure(error.message), stackTrace);
      return false;
    } catch (error, stackTrace) {
      state = AsyncValue.error(AuthFailure.from(error), stackTrace);
      return false;
    } finally {
      await receiver.close();
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppConfig.authRedirectUrl,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(AuthFailure.from(error), stackTrace);
      return false;
    }
  }

  /// Enregistre le nouveau mot de passe choisi après un lien de réinitialisation.
  Future<bool> updatePassword(String password) async {
    state = const AsyncValue.loading();
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
      ref.read(passwordRecoveryProvider.notifier).complete();
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(AuthFailure.from(error), stackTrace);
      return false;
    }
  }

  /// Tente d'envoyer les écritures locales en attente, puis renvoie le nombre
  /// de celles qui restent (hors ligne, refus serveur…). À appeler avant
  /// [signOut] : ces écritures-là seront perdues par la purge locale.
  Future<int> flushPendingWrites() async {
    await ref.read(syncCoordinatorProvider.notifier).syncNow();
    return SyncQueue(ref.read(appDatabaseProvider)).pendingCount();
  }

  /// Ferme la session puis efface toutes les données locales de l'appareil.
  ///
  /// La purge n'a lieu qu'une fois la session locale fermée : si elle est
  /// toujours là, l'utilisateur reste connecté et ne perd rien.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    Object? signOutError;
    StackTrace? signOutStack;
    try {
      await _client.auth.signOut();
    } catch (error, stackTrace) {
      // gotrue retire la session locale *avant* de prévenir le serveur : hors
      // ligne, cet appel échoue alors que l'utilisateur est bien déconnecté.
      signOutError = error;
      signOutStack = stackTrace;
    }

    if (_client.auth.currentSession != null) {
      state = AsyncValue.error(
        AuthFailure.from(signOutError ?? 'session toujours ouverte'),
        signOutStack ?? StackTrace.current,
      );
      return;
    }

    try {
      await ref.read(appDatabaseProvider).wipeAll();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Supprime définitivement le compte (RGPD) puis purge l'appareil.
  ///
  /// La fonction serveur `delete_own_account` efface l'utilisateur de
  /// auth.users ; toutes ses données suivent en cascade. Elle exige le réseau :
  /// en cas d'échec, rien n'est supprimé, ni sur le serveur ni en local.
  Future<bool> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      await _client.rpc('delete_own_account');
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        const AuthFailure(
          'Suppression impossible. Vérifie ta connexion internet et réessaie.',
        ),
        stackTrace,
      );
      return false;
    }

    // Le compte n'existe plus : seule la session locale reste à fermer.
    // gotrue la retire avant d'appeler le serveur, qui peut refuser un jeton
    // dont l'utilisateur a disparu.
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}

    try {
      await ref.read(appDatabaseProvider).wipeAll();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
    return true;
  }

  /// Efface l'erreur affichée (ex. quand l'utilisateur recommence à taper).
  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

/// Erreur d'authentification traduite en message lisible par l'utilisateur.
///
/// Les messages bruts de Supabase sont en anglais et parfois techniques ; on
/// les mappe ici une fois pour toutes plutôt que dans chaque page.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  factory AuthFailure.from(Object error) {
    if (error is AuthFailure) return error;

    if (error is AuthException) {
      return AuthFailure(_messageFor(error), code: error.code);
    }

    return const AuthFailure(
      'Connexion impossible. Vérifie ta connexion internet et réessaie.',
    );
  }

  static String _messageFor(AuthException error) {
    final code = error.code;
    final raw = error.message.toLowerCase();

    if (code == 'invalid_credentials' ||
        raw.contains('invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (code == 'email_not_confirmed' || raw.contains('email not confirmed')) {
      return 'Ton email n\'est pas encore confirmé. Vérifie ta boîte de réception.';
    }
    if (code == 'user_already_exists' ||
        raw.contains('already registered') ||
        raw.contains('user already')) {
      return 'Un compte existe déjà avec cet email.';
    }
    if (code == 'weak_password' || raw.contains('password should be at least')) {
      return 'Mot de passe trop court '
          '(${AppConfig.minPasswordLength} caractères minimum).';
    }
    if (code == 'same_password') {
      return 'Choisis un mot de passe différent de l\'ancien.';
    }
    if (code == 'over_email_send_rate_limit' ||
        raw.contains('rate limit') ||
        raw.contains('too many requests')) {
      return 'Trop de tentatives. Patiente quelques minutes avant de réessayer.';
    }
    if (code == 'validation_failed' || raw.contains('unable to validate email')) {
      return 'Adresse email invalide.';
    }
    if (raw.contains('failed host lookup') || raw.contains('socketexception')) {
      return 'Pas de connexion internet.';
    }

    return error.message;
  }

  @override
  String toString() => message;
}
