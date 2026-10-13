import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/navigation/adaptive_shell.dart';
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
import '../features/metacognition/views/error_logs_page.dart';
import '../features/metacognition/views/journal_entry_page.dart';
import '../features/metacognition/views/journal_hub_page.dart';
import '../features/metacognition/views/profiling_page.dart';
import '../features/metacognition/views/reframe_page.dart';
import '../features/metacognition/views/why_chain_page.dart';
import '../features/notes/views/note_editor_page.dart';
import '../features/notes/views/notes_page.dart';
import '../features/planning/views/gantt_page.dart';
import '../features/planning/views/goals_page.dart';
import '../features/planning/views/planning_hub_page.dart';
import '../features/planning/views/revision_order_page.dart';
import '../features/planning/views/study_speed_page.dart';
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
  static const String whyChain = '/journal/why';
  static const String errorLogs = '/journal/errors';
  static const String profiling = '/journal/profile';
  static const String reviewSession = '/review/session';
  static const String sq3rPicker = '/review/sq3r';
  static const String explainPicker = '/review/explain';

  static String sq3rFor(String noteId) => '$sq3rPicker/$noteId';
  static String explainFor(String noteId) => '$explainPicker/$noteId';

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
  final refreshListenable = _GoRouterRefreshStream(client.auth.onAuthStateChange);
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
      final isOnResetPassword =
          state.matchedLocation == AppRoute.resetPassword;

      // Lien « mot de passe oublié » ouvert : la session existe déjà, mais
      // l'utilisateur doit choisir son nouveau mot de passe avant tout.
      if (ref.read(passwordRecoveryProvider)) {
        return isOnResetPassword ? null : AppRoute.resetPassword;
      }
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
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoute.pomodoro,
            builder: (_, __) => const PomodoroPage(),
          ),
          GoRoute(
            path: AppRoute.kanban,
            builder: (_, __) => const KanbanPage(),
          ),
          GoRoute(
            path: AppRoute.habits,
            builder: (_, __) => const HabitsPage(),
          ),
          GoRoute(
            path: AppRoute.settings,
            builder: (_, __) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoute.planning,
            builder: (_, __) => const PlanningHubPage(),
            routes: [
              GoRoute(path: 'gantt', builder: (_, __) => const GanttPage()),
              GoRoute(
                path: 'order',
                builder: (_, __) => const RevisionOrderPage(),
              ),
              GoRoute(
                path: 'speed',
                builder: (_, __) => const StudySpeedPage(),
              ),
              GoRoute(path: 'goals', builder: (_, __) => const GoalsPage()),
            ],
          ),
          GoRoute(
            path: AppRoute.journal,
            builder: (_, __) => const JournalHubPage(),
            routes: [
              GoRoute(
                path: 'entry',
                builder: (_, __) => const JournalEntryPage(),
              ),
              GoRoute(
                path: 'reframe',
                builder: (_, __) => const ReframePage(),
              ),
              GoRoute(
                path: 'why',
                builder: (_, __) => const WhyChainPage(),
              ),
              GoRoute(
                path: 'errors',
                builder: (_, __) => const ErrorLogsPage(),
              ),
              GoRoute(
                path: 'profile',
                builder: (_, __) => const ProfilingPage(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.review,
            builder: (_, __) => const ReviewHomePage(),
            routes: [
              GoRoute(
                path: 'session',
                builder: (_, __) => const ReviewSessionPage(),
              ),
              GoRoute(
                path: 'sq3r',
                builder: (_, __) => const NotePickerPage(
                  title: 'Lecture guidée SQ3R',
                  subtitle: 'Choisis la fiche à travailler en cinq étapes : '
                      'survol, questions, lecture, récitation, révision.',
                  routeBuilder: AppRoute.sq3rFor,
                ),
                routes: [
                  GoRoute(
                    path: ':noteId',
                    builder: (context, state) =>
                        Sq3rPage(noteId: state.pathParameters['noteId']!),
                  ),
                ],
              ),
              GoRoute(
                path: 'explain',
                builder: (_, __) => const NotePickerPage(
                  title: 'Explique-moi',
                  subtitle: 'Choisis la notion que tu vas reformuler avec '
                      'tes propres mots.',
                  routeBuilder: AppRoute.explainFor,
                ),
                routes: [
                  GoRoute(
                    path: ':noteId',
                    builder: (context, state) =>
                        ExplainPage(noteId: state.pathParameters['noteId']!),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoute.graph,
            builder: (_, __) => const GraphPage(),
          ),
          GoRoute(
            path: AppRoute.notes,
            builder: (_, __) => const NotesPage(),
            routes: [
              // Route enfant : l'éditeur reste sous /notes, donc l'onglet
              // « Fiches » demeure sélectionné quand une fiche est ouverte.
              GoRoute(
                path: ':noteId',
                builder: (context, state) => NoteEditorPage(
                  noteId: state.pathParameters['noteId']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorPage(location: state.uri.toString()),
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
