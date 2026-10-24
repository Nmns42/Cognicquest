import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/navigation/adaptive_shell.dart';
import '../core/motion/entrance.dart';
import '../core/navigation/app_destinations.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/views/forgot_password_page.dart';
import '../features/auth/views/login_page.dart';
import '../features/auth/views/register_page.dart';
import '../features/auth/views/reset_password_page.dart';
import '../features/dashboard/views/dashboard_page.dart';
import '../features/graph/views/graph_page.dart';
import '../features/habits/views/habits_page.dart';
import '../features/kanban/views/kanban_page.dart';
import '../features/legal/consent.dart';
import '../features/legal/legal_texts.dart';
import '../features/legal/views/legal_page.dart';
import '../features/metacognition/views/error_logs_page.dart';
import '../features/metacognition/views/journal_entry_page.dart';
import '../features/metacognition/views/journal_hub_page.dart';
import '../features/metacognition/views/profiling_page.dart';
import '../features/metacognition/views/reframe_page.dart';
import '../features/notes/views/note_editor_page.dart';
import '../features/notes/views/notes_page.dart';
import '../features/planning/views/gantt_page.dart';
import '../features/planning/views/goals_page.dart';
import '../features/planning/views/planning_hub_page.dart';
import '../features/planning/views/revision_speed_page.dart';
import '../features/pomodoro/providers/pomodoro_provider.dart';
import '../features/pomodoro/views/pomodoro_page.dart';
import '../features/review/views/explain_page.dart';
import '../features/review/views/review_home_page.dart';
import '../features/review/views/review_session_page.dart';
import '../features/review/views/sq3r_page.dart';
import '../features/settings/views/settings_page.dart';
import '../features/sync/widgets/offline_banner.dart';

/// Chemins de l'application, centralisés pour éviter les chaînes magiques
/// dispersées dans les pages.
abstract final class AppRoute {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  static const String home = '/home';
  static const String pomodoro = '/pomodoro';
  static const String kanban = '/kanban';
  static const String habits = '/habits';
  static const String notes = '/notes';
  static const String graph = '/graph';
  static const String review = '/review';
  static const String planning = '/planning';
  static const String gantt = '/planning/gantt';
  static const String revisionOrder = '/planning/order';
  static const String studySpeed = '/planning/speed';
  static const String goals = '/planning/goals';

  static const String settings = '/settings';

  static const String journal = '/journal';
  static const String journalEntry = '/journal/entry';
  static const String reframe = '/journal/reframe';
  static const String errorLogs = '/journal/errors';
  static const String profiling = '/journal/profile';
  static const String reviewSession = '/review/session';
  static const String sq3rPicker = '/review/sq3r';
  static const String explainPicker = '/review/explain';

  static String sq3rFor(String noteId) => '$sq3rPicker/$noteId';
  static String explainFor(String noteId) => '$explainPicker/$noteId';

  /// Fiche de révision d'une fiche (résultat de l'étude guidée).
  static const String studySheet = '/review/sheet';
  static String studySheetFor(String noteId) => '$studySheet/$noteId';

  /// Révision des seules cartes d'une fiche.
  static String reviewSessionFor(String noteId) =>
      '$reviewSession?note=$noteId';

  static const Set<String> publicRoutes = {login, register, forgotPassword};
}

/// Adapte un `Stream` en `Listenable` pour `GoRouter.refreshListenable`.
///
/// C'est ce qui manquait : l'ancien `redirect` lisait un `bool` statique, donc
/// la navigation ne réagissait jamais à une connexion ou une déconnexion.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  /// Réévalue les redirections sur un changement d'état hors du flux.
  void refresh() => notifyListeners();

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);

  // Le routeur est construit une seule fois : on ne `watch` pas la session ici
  // (cela recréerait le GoRouter et réinitialiserait la pile de navigation).
  // On se contente de le notifier via refreshListenable.
  final refreshListenable =
      _GoRouterRefreshStream(client.auth.onAuthStateChange);
  ref.onDispose(refreshListenable.dispose);

  // Le drapeau de récupération est mis à jour par le même flux que
  // `refreshListenable` : on réévalue après lui pour ne pas lire une valeur
  // périmée. Le `listen` garde aussi le provider en vie.
  ref.listen(passwordRecoveryProvider, (_, __) => refreshListenable.refresh());

  return GoRouter(
    initialLocation: AppRoute.home,
    refreshListenable: refreshListenable,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn =
          client.auth.currentSession != null || AppConfig.devBypassAuth;
      final isOnPublicRoute =
          AppRoute.publicRoutes.contains(state.matchedLocation);
      final isOnResetPassword = state.matchedLocation == AppRoute.resetPassword;

      // Lien « mot de passe oublié » ouvert : la session existe déjà, mais
      // l'utilisateur doit choisir son nouveau mot de passe avant tout.
      if (ref.read(passwordRecoveryProvider)) {
        return isOnResetPassword ? null : AppRoute.resetPassword;
      }
      // Textes légaux : lisibles avant comme après la connexion.
      if (LegalRoute.contains(state.matchedLocation)) return null;
      if (isOnResetPassword) {
        return isLoggedIn ? AppRoute.home : AppRoute.login;
      }

      if (!isLoggedIn && !isOnPublicRoute) {
        // On mémorise la destination voulue pour y revenir après connexion.
        final from = state.matchedLocation;
        return from == AppRoute.home
            ? AppRoute.login
            : '${AppRoute.login}?from=${Uri.encodeComponent(from)}';
      }

      if (isLoggedIn && isOnPublicRoute) {
        return AppRoute.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.login,
        builder: (context, state) =>
            LoginPage(redirectTo: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: AppRoute.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoute.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoute.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: LegalRoute.privacy,
        builder: (context, state) => const LegalPage(document: privacyPolicy),
      ),
      GoRoute(
        path: LegalRoute.notice,
        builder: (context, state) => const LegalPage(document: legalNotice),
      ),
      ShellRoute(
        builder: (context, state, child) => Consumer(
          builder: (context, ref, _) => AdaptiveShell(
            currentLocation: state.matchedLocation,
            // Mode concentration : seulement sur l'écran du Pomodoro, pour
            // qu'une session en cours n'emprisonne pas le reste de l'app.
            focusMode: ref.watch(focusModeProvider) &&
                state.matchedLocation == focusRoute,
            // Le bandeau hors ligne vit au-dessus de toutes les sections : la
            // synchronisation concerne l'app entière, pas un écran.
            child: Column(
              children: [
                Expanded(child: child),
                const OfflineBanner(),
              ],
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: AppRoute.home,
            builder: (_, __) => const PanelSettle(child: DashboardPage()),
          ),
          GoRoute(
            path: AppRoute.pomodoro,
            builder: (_, __) => const PanelSettle(child: PomodoroPage()),
          ),
          GoRoute(
            path: AppRoute.kanban,
            builder: (_, __) => const PanelSettle(child: KanbanPage()),
          ),
          GoRoute(
            path: AppRoute.habits,
            builder: (_, __) => const PanelSettle(child: HabitsPage()),
          ),
          GoRoute(
            path: AppRoute.settings,
            builder: (_, __) => const PanelSettle(child: SettingsPage()),
          ),
          GoRoute(
            path: AppRoute.planning,
            builder: (_, __) => const PanelSettle(child: PlanningHubPage()),
            routes: [
              GoRoute(
                  path: 'gantt',
                  builder: (_, __) => const PanelSettle(child: GanttPage())),
              GoRoute(
                path: 'order',
                builder: (_, __) =>
                    const PanelSettle(child: RevisionSpeedPage()),
              ),
              GoRoute(
                path: 'speed',
                builder: (_, __) => const PanelSettle(
                    child: RevisionSpeedPage(
                        initialTab: RevisionSpeedTab.speed)),
              ),
              GoRoute(
                  path: 'goals',
                  builder: (_, __) => const PanelSettle(child: GoalsPage())),
            ],
          ),
          GoRoute(
            path: AppRoute.journal,
            builder: (_, __) => const PanelSettle(child: JournalHubPage()),
            routes: [
              GoRoute(
                path: 'entry',
                builder: (_, __) =>
                    const PanelSettle(child: JournalEntryPage()),
              ),
              GoRoute(
                path: 'reframe',
                builder: (_, __) => const PanelSettle(child: ReframePage()),
              ),
              GoRoute(
                path: 'errors',
                builder: (_, __) => const PanelSettle(child: ErrorLogsPage()),
              ),
              GoRoute(
                path: 'profile',
                builder: (_, __) => const PanelSettle(child: ProfilingPage()),
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.review,
            builder: (_, __) => const PanelSettle(child: ReviewHomePage()),
            routes: [
              GoRoute(
                path: 'session',
                builder: (_, state) => PanelSettle(
                    child: ReviewSessionPage(
                        noteId: state.uri.queryParameters['note'])),
              ),
              GoRoute(
                path: 'sheet/:noteId',
                builder: (context, state) => PanelSettle(
                    child: StudySheetPage(
                        noteId: state.pathParameters['noteId']!)),
              ),
              GoRoute(
                path: 'sq3r',
                builder: (_, __) => const NotePickerPage(
                  title: 'Étude guidée',
                  subtitle: 'Choisis la fiche à travailler en trois temps : '
                      'survol et questions, lecture ciblée, explication.',
                  routeBuilder: AppRoute.sq3rFor,
                ),
                routes: [
                  GoRoute(
                    path: ':noteId',
                    builder: (context, state) => PanelSettle(
                        child:
                            Sq3rPage(noteId: state.pathParameters['noteId']!)),
                  ),
                ],
              ),
              GoRoute(
                path: 'explain',
                builder: (_, __) => const NotePickerPage(
                  title: 'Explique-moi',
                  subtitle: 'Choisis la notion que tu vas reformuler avec '
                      'tes propres mots (dernière étape de l’étude guidée).',
                  routeBuilder: AppRoute.explainFor,
                ),
                routes: [
                  GoRoute(
                    path: ':noteId',
                    builder: (context, state) => PanelSettle(
                        child: Sq3rPage(
                            noteId: state.pathParameters['noteId']!,
                            initialStage: StudyStage.explain)),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.graph,
            builder: (_, __) => const PanelSettle(child: GraphPage()),
          ),
          GoRoute(
            path: AppRoute.notes,
            builder: (_, __) => const PanelSettle(child: NotesPage()),
            routes: [
              // Route enfant : l'éditeur reste sous /notes, donc l'onglet
              // « Fiches » demeure sélectionné quand une fiche est ouverte.
              GoRoute(
                path: ':noteId',
                builder: (context, state) => PanelSettle(
                    child: NoteEditorPage(
                  noteId: state.pathParameters['noteId']!,
                )),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        _RouteErrorPage(location: state.uri.toString()),
  );
});

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore_off_outlined,
                  size: 48, color: context.cq.textHint),
              const SizedBox(height: 16),
              Text(
                'Cette page n\'existe pas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                location,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoute.home),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
