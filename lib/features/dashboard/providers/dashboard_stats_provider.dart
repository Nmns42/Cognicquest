import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/pomodoro_session_model.dart';
import '../../pomodoro/data/pomodoro_repository.dart';

/// Une journée de la série hebdomadaire.
class DailyFocus {
  const DailyFocus({
    required this.day,
    required this.focus,
    required this.sessions,
  });

  final DateTime day;
  final Duration focus;
  final int sessions;

  bool get isToday {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  /// Initiale du jour (L, M, M, J, V, S, D).
  String get initial =>
      const ['L', 'M', 'M', 'J', 'V', 'S', 'D'][day.weekday - 1];

  String get fullLabel => const [
        'lundi',
        'mardi',
        'mercredi',
        'jeudi',
        'vendredi',
        'samedi',
        'dimanche'
      ][day.weekday - 1];
}

/// Agrégats du Dashboard, calculés en **un seul appel réseau**.
///
/// Le Dashboard affiche à la fois la rangée de statistiques et le graphe
/// hebdomadaire : les faire dépendre de deux providers distincts déclencherait
/// deux requêtes identiques au même instant.
class DashboardStats {
  const DashboardStats({
    required this.sessionsToday,
    required this.focusToday,
    required this.focusThisWeek,
    required this.weeklySeries,
  });

  const DashboardStats.empty()
      : sessionsToday = 0,
        focusToday = Duration.zero,
        focusThisWeek = Duration.zero,
        weeklySeries = const [];

  final int sessionsToday;
  final Duration focusToday;
  final Duration focusThisWeek;

  /// Les 7 derniers jours, du plus ancien au plus récent.
  final List<DailyFocus> weeklySeries;

  Duration get bestDay => weeklySeries.isEmpty
      ? Duration.zero
      : weeklySeries.map((d) => d.focus).reduce((a, b) => a > b ? a : b);

  bool get hasAnyFocus => weeklySeries.any((d) => d.focus > Duration.zero);

  factory DashboardStats.fromSessions(List<PomodoroSession> sessions) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    // Fenêtre glissante de 7 jours terminant aujourd'hui : plus lisible qu'une
    // semaine calendaire, où le lundi matin le graphe serait presque vide.
    final days = [
      for (var i = 6; i >= 0; i--) startOfToday.subtract(Duration(days: i)),
    ];

    final secondsByDay = <DateTime, int>{for (final day in days) day: 0};
    final countByDay = <DateTime, int>{for (final day in days) day: 0};

    for (final session in sessions) {
      final day = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );
      if (!secondsByDay.containsKey(day)) continue;
      secondsByDay[day] = secondsByDay[day]! + session.durationSeconds;
      countByDay[day] = countByDay[day]! + 1;
    }

    final series = [
      for (final day in days)
        DailyFocus(
          day: day,
          focus: Duration(seconds: secondsByDay[day]!),
          sessions: countByDay[day]!,
        ),
    ];

    return DashboardStats(
      sessionsToday: countByDay[startOfToday] ?? 0,
      focusToday: Duration(seconds: secondsByDay[startOfToday] ?? 0),
      focusThisWeek: Duration(
        seconds: secondsByDay.values.fold(0, (sum, value) => sum + value),
      ),
      weeklySeries: series,
    );
  }
}

final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  final repository = ref.watch(pomodoroRepositoryProvider);
  if (repository == null) return Stream.value(const DashboardStats.empty());
  // 8 jours suffisent à la fenêtre glissante : on ne lit pas 90 jours
  // d'historique pour afficher 7 barres.
  return repository.watchRecent(limitDays: 8).map(DashboardStats.fromSessions);
});
