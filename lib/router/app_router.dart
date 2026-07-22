import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/views/login_page.dart';
import '../features/auth/views/register_page.dart';
import '../features/dashboard/views/dashboard_page.dart';
import '../features/pomodoro/views/pomodoro_page.dart';
import '../features/kanban/views/kanban_page.dart';
import '../features/habits/views/habits_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final loggedIn = _isLoggedIn();
      final isAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!loggedIn && !isAuth) return '/login';
      if (loggedIn && isAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(path: '/home',     builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/pomodoro', builder: (_, __) => const PomodoroPage()),
          GoRoute(path: '/kanban',   builder: (_, __) => const KanbanPage()),
          GoRoute(path: '/habits',   builder: (_, __) => const HabitsPage()),
        ],
      ),
    ],
  );
});

bool _isLoggedIn() {
  return Supabase.instance.client.auth.currentUser != null;
}

class _MainShell extends StatelessWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index(loc),
        onTap: (i) => _nav(context, i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            label: 'Pomodoro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_kanban_outlined),
            label: 'Tâches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Habitudes',
          ),
        ],
      ),
    );
  }

  int _index(String loc) {
    if (loc.startsWith('/pomodoro')) return 1;
    if (loc.startsWith('/kanban')) return 2;
    if (loc.startsWith('/habits')) return 3;
    return 0;
  }

  void _nav(BuildContext ctx, int i) {
    switch (i) {
      case 0: ctx.go('/home'); break;
      case 1: ctx.go('/pomodoro'); break;
      case 2: ctx.go('/kanban'); break;
      case 3: ctx.go('/habits'); break;
    }
  }
}
