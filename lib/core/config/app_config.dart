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
/// Aucune valeur par défaut : un binaire compilé sans `env.json` visait
/// auparavant le projet Supabase de dev en silence. Sans configuration, `main`
/// affiche désormais un écran d'erreur explicite au lieu de démarrer. La clé
/// `anon` / `publishable` est publique par conception : la protection réelle
/// des données vient des politiques RLS (cf. `supabase/schema.sql`).
class AppConfig {
  AppConfig._();

  static const String appName = 'CognicQuest';
  static const String appVersion = '1.0.0';

  // ── Supabase ───────────────────────────────────────────────────────────────

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

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

  /// Inactif par défaut : actif, il masquait au quotidien les bugs du vrai
  /// parcours d'authentification. Pour ouvrir l'app sans compte, remplie des
  /// données de démo : `flutter run --dart-define-from-file=env.json
  /// --dart-define=DEV_BYPASS_AUTH=true`, ou la configuration VS Code
  /// « CognicQuest (démo sans compte) ».
  static const bool _devBypassAuthFlag = bool.fromEnvironment('DEV_BYPASS_AUTH');

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
