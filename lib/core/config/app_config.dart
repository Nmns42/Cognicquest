import 'package:flutter/foundation.dart';

/// Configuration centrale de CognicQuest.
///
/// Les valeurs sensibles sont injectées au build via `--dart-define-from-file` :
///
/// ```
/// flutter run --dart-define-from-file=env.json
/// ```
///
/// `env.json` est ignoré par git ; `env.example.json` sert de modèle.
/// Les valeurs par défaut ci-dessous correspondent au projet Supabase de dev,
/// afin que l'app reste lançable sans configuration. La clé `anon` /
/// `publishable` est publique par conception : la protection réelle des données
/// vient des politiques RLS (cf. `supabase/schema.sql`), pas du secret de la clé.
class AppConfig {
  AppConfig._();

  static const String appName = 'CognicQuest';
  static const String appVersion = '1.0.0';

  // ── Supabase ───────────────────────────────────────────────────────────────

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lnsncmsxpshqokwchxls.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_h6Gn0x_pSZy_LuNMJ8f9Tw_CCYjKhVN',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Schéma de redirection OAuth (Google).
  ///
  /// Doit être déclaré aux trois endroits suivants, sinon le retour de
  /// navigateur renvoie l'utilisateur dans le vide :
  ///  - Android : `android/app/src/main/AndroidManifest.xml` (intent-filter)
  ///  - iOS     : `ios/Runner/Info.plist` (CFBundleURLTypes)
  ///  - Supabase: Authentication > URL Configuration > Redirect URLs
  static const String oauthRedirectUrl = String.fromEnvironment(
    'OAUTH_REDIRECT_URL',
    defaultValue: 'io.cognicquest.app://login-callback/',
  );

  /// Sur Flutter Web, Supabase gère le retour OAuth sur l'origine courante :
  /// on ne passe donc pas de `redirectTo` custom.
  static String? get oauthRedirectUrlOrNull =>
      kIsWeb ? null : oauthRedirectUrl;

  // ── Bypass d'authentification (développement uniquement) ───────────────────

  /// Actif par défaut en debug, le temps de la mise en place des tests : un
  /// simple `flutter run` ouvre l'app sans écran de connexion, remplie des
  /// données de test. Pour retrouver la vraie authentification :
  /// `flutter run --dart-define=DEV_BYPASS_AUTH=false`.
  static const bool _devBypassAuthFlag =
      bool.fromEnvironment('DEV_BYPASS_AUTH', defaultValue: true);

  /// Permet d'entrer dans l'app sans compte Supabase, pour travailler l'UI
  /// hors-ligne.
  ///
  /// Verrouillé par `kDebugMode` : impossible à activer en build release.
  /// Depuis le Lot 10, ce mode utilise l'identifiant fictif [devUserId] : les
  /// modules local-first (tâches, habitudes, Pomodoro, fiches…) fonctionnent
  /// entièrement sur l'appareil, sans aucune synchronisation. Le profil et la
  /// disposition du dashboard, encore 100 % serveur, restent par défaut.
  static bool get devBypassAuth => kDebugMode && _devBypassAuthFlag;

  /// Identifiant de l'utilisateur fictif du mode [devBypassAuth]. Au format
  /// UUID pour rester compatible avec les colonnes `uuid` côté serveur.
  static const String devUserId = '00000000-0000-4000-8000-000000000001';

  // ── Constantes métier ──────────────────────────────────────────────────────

  static const double initialEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;

  static const int defaultWorkDurationMinutes = 25;
  static const int defaultShortBreakDurationMinutes = 5;
  static const int defaultLongBreakDurationMinutes = 15;

  /// Nombre de sessions de travail avant une pause longue (cycle Pomodoro
  /// classique). Le CdC demande des « sessions de travail et pauses
  /// programmables » : ces valeurs sont les défauts, surchargeables par
  /// l'utilisateur au Lot 9 (système de configuration).
  static const int sessionsBeforeLongBreak = 4;

  /// Récompense du CdC : « proposer des récompenses (gagne des pièces) ».
  static const int coinsPerWorkSession = 10;
  static const int coinsPerHabitStreakDay = 2;

  static const int maxFreeFlashcardsPerDay = 100;
  static const int maxFreeLinksPerDay = 100;

  // ── Validation partagée ────────────────────────────────────────────────────

  static const int minPasswordLength = 6;

  static final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
