import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/ui/zen_background.dart';
import 'core/config/app_config.dart';
import 'core/monitoring/crash_reporting.dart';
import 'core/motion/reduce_motion.dart';
import 'core/theme/app_theme.dart';
import 'features/dev/demo_seed.dart';
import 'features/legal/consent.dart';
import 'features/reminders/reminder_service.dart';
import 'features/settings/data/ambient_sound_engine.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/sync/providers/sync_coordinator.dart';
import 'router/app_router.dart';
import 'core/theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sans `--dart-define-from-file=env.json`, l'URL et la clé sont vides :
  // mieux vaut le dire clairement que d'échouer plus loin sur une URL invalide.
  if (!AppConfig.isSupabaseConfigured) {
    runApp(const _StartupErrorApp(
      explanation: 'Configuration Supabase absente. Lance l\'application avec '
          '--dart-define-from-file=env.json (modèle : env.example.json).',
      message: 'SUPABASE_URL / SUPABASE_ANON_KEY non définis',
    ));
    return;
  }

  try {
    // `Supabase.initialize` restaure la session persistée avant de rendre la
    // main : `currentSession` est donc déjà correct au premier build du routeur.
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } catch (error) {
    // Sans ce garde-fou, une URL invalide ou une coupure réseau au démarrage
    // faisait planter l'app sur un écran noir, sans aucun message.
    runApp(_StartupErrorApp(
      explanation: 'La connexion au serveur a échoué. Vérifie ta connexion '
          'internet, puis relance l\'application.',
      message: error.toString(),
    ));
    return;
  }

  // Rapports de plantage (si SENTRY_DSN est fourni) : erreurs Flutter,
  // asynchrones et natives à partir d'ici.
  await CrashReporting.run(
      () => runApp(const ProviderScope(child: CognicQuestApp())));
}

class CognicQuestApp extends ConsumerWidget {
  const CognicQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Seuls les réglages appliqués à la racine sont suivis. Suivre l'objet
    // entier reconstruisait l'app, ses raccourcis, ses actions et l'enveloppe
    // de l'écran courant à chaque réglage — y compris en faisant glisser le
    // curseur du volume d'ambiance.
    final textScale =
        ref.watch(settingsProvider.select((s) => s.textScale.scale));
    final shortcutsEnabled = ref
        .watch(settingsProvider.select((s) => s.keyboardShortcutsEnabled));
    // Animations réduites : réglage de l'app ou réglage système. Désactivé,
    // rien ci-dessous ne change (même thème, styles par défaut).
    final reduceMotion = ref.watch(effectiveReduceMotionProvider);
    final theme = ref.watch(appThemeProvider);

    // Garde le coordinateur de synchronisation en vie pendant toute la vie de
    // l'app, sans reconstruire l'arbre à chaque changement de son état.
    ref.listen(syncCoordinatorProvider, (_, __) {});

    // Rappel quotidien de révision : replanifié à chaque changement de
    // réglage, y compris venu d'un autre appareil.
    ref.listen(dailyReminderSyncProvider, (_, __) {});

    // Mode sans connexion : remplit une base vide avec des données de démo.
    if (AppConfig.devBypassAuth) ref.listen(demoSeedProvider, (_, __) {});

    // L'ambiance suit les préférences : changer de son depuis les réglages
    // agit immédiatement, y compris depuis un autre écran.
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.ambientSound == next.ambientSound) return;
      ref
          .read(ambientSoundEngineProvider)
          .play(next.ambientSound, volume: next.ambientVolume);
    });

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: reduceMotion ? Motion.reducedTheme(theme) : theme,
      themeAnimationStyle: reduceMotion ? AnimationStyle.noAnimation : null,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Interface 100 % française, y compris les composants du framework.
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      shortcuts: shortcutsEnabled ? _appShortcuts : null,
      actions: {
        ...WidgetsApp.defaultActions,
        GoRouteIntent: CallbackAction<GoRouteIntent>(
          onInvoke: (intent) {
            if (shortcutsEnabled) router.go(intent.route);
            return null;
          },
        ),
      },
      builder: (context, child) {
        // L'échelle est appliquée à la racine plutôt que dans le `textTheme` :
        // elle touche ainsi tous les textes, y compris ceux des composants
        // Material qui ne lisent pas notre thème. On compose avec le réglage
        // système au lieu de l'écraser — un utilisateur qui a déjà agrandi le
        // texte de son téléphone ne doit pas le voir rétrécir ici.
        //
        // La valeur effective des animations réduites est réinjectée ici :
        // chaque widget la lit au même endroit, via [Motion].
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(
              textScale * media.textScaler.scale(1),
            ),
            disableAnimations: reduceMotion,
          ),
          // Fond commun (beige et feuilles) sous toutes les pages ; le
          // bandeau de consentement par-dessus, à la première ouverture.
          child: ConsentGate(
            router: router,
            child: ZenBackground(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}

/// Intention de navigation déclenchée au clavier.
class GoRouteIntent extends Intent {
  const GoRouteIntent(this.route);

  final String route;
}

final Map<LogicalKeyboardKey, String> _shortcutRoutes = {
  // Un chiffre par espace, dans l'ordre de la barre de navigation.
  LogicalKeyboardKey.digit1: AppRoute.home,
  LogicalKeyboardKey.digit2: AppRoute.notes,
  LogicalKeyboardKey.digit3: AppRoute.kanban,
  LogicalKeyboardKey.digit4: AppRoute.journal,
  LogicalKeyboardKey.comma: AppRoute.settings,
};

/// Raccourcis clavier — « raccourcis clavier » (CdC).
///
/// `control` et `meta` sont déclarés tous les deux : sur macOS l'utilisateur
/// attend `Cmd`, ailleurs `Ctrl`.
final Map<ShortcutActivator, Intent> _navigationShortcuts = {
  for (final entry in _shortcutRoutes.entries) ...{
    SingleActivator(entry.key, control: true): GoRouteIntent(entry.value),
    SingleActivator(entry.key, meta: true): GoRouteIntent(entry.value),
  },
};

/// Raccourcis de l'app, construits une seule fois : une map neuve à chaque
/// build faisait reconstruire le `Shortcuts` racine.
final Map<ShortcutActivator, Intent> _appShortcuts = {
  ...WidgetsApp.defaultShortcuts,
  ..._navigationShortcuts,
};

/// Écran affiché quand Supabase n'est pas configuré ou que son initialisation
/// échoue au démarrage.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.explanation, required this.message});

  /// Phrase destinée à l'utilisateur : quoi faire.
  final String explanation;

  /// Détail technique, affiché en petit.
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          ZenBackground(child: child ?? const SizedBox.shrink()),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined,
                      size: 48, color: context.cq.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'CognicQuest n\'a pas pu démarrer',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    explanation,
                    style:
                        TextStyle(color: context.cq.textMuted, fontSize: TypeScale.body),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    style:
                        TextStyle(color: context.cq.textHint, fontSize: TypeScale.caption),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
