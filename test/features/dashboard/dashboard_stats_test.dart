import 'package:cognicquest/features/dashboard/providers/dashboard_stats_provider.dart';
import 'package:cognicquest/shared/models/pomodoro_session_model.dart';
import 'package:cognicquest/shared/models/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

PomodoroSession sessionDaysAgo(int daysAgo, {int minutes = 25}) {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: daysAgo))
      // Midi : à l'abri des bascules de jour, quelle que soit l'heure du test.
      .add(const Duration(hours: 12));
  return PomodoroSession(
    id: 's$daysAgo-$minutes',
    userId: 'u1',
    startedAt: day,
    durationSeconds: minutes * 60,
  );
}

void main() {
  group('DashboardStats.fromSessions', () {
    test('produit toujours exactement 7 jours, du plus ancien au plus récent', () {
      final stats = DashboardStats.fromSessions([sessionDaysAgo(0)]);

      expect(stats.weeklySeries, hasLength(7));
      expect(stats.weeklySeries.last.isToday, isTrue);
      expect(
        stats.weeklySeries.first.day
            .isBefore(stats.weeklySeries.last.day),
        isTrue,
      );
    });

    test('ventile le focus sur le bon jour', () {
      final stats = DashboardStats.fromSessions([
        sessionDaysAgo(0),
        sessionDaysAgo(0),
        sessionDaysAgo(2, minutes: 50),
      ]);

      expect(stats.focusToday, const Duration(minutes: 50));
      expect(stats.sessionsToday, 2);
      expect(stats.weeklySeries.last.focus, const Duration(minutes: 50));
      expect(stats.weeklySeries[4].focus, const Duration(minutes: 50));
      expect(stats.weeklySeries[4].sessions, 1);
    });

    test('exclut les sessions hors de la fenêtre de 7 jours', () {
      final stats = DashboardStats.fromSessions([
        sessionDaysAgo(0),
        sessionDaysAgo(30, minutes: 100),
      ]);

      expect(stats.focusThisWeek, const Duration(minutes: 25));
      expect(
        stats.weeklySeries.fold<int>(0, (sum, d) => sum + d.sessions),
        1,
      );
    });

    test('rend une série de zéros sans aucune session', () {
      final stats = DashboardStats.fromSessions(const []);

      expect(stats.weeklySeries, hasLength(7));
      expect(stats.hasAnyFocus, isFalse);
      expect(stats.bestDay, Duration.zero);
      expect(stats.focusToday, Duration.zero);
    });

    test('bestDay retient le plus gros jour', () {
      final stats = DashboardStats.fromSessions([
        sessionDaysAgo(1, minutes: 25),
        sessionDaysAgo(3, minutes: 75),
        sessionDaysAgo(5, minutes: 50),
      ]);

      expect(stats.bestDay, const Duration(minutes: 75));
      expect(stats.hasAnyFocus, isTrue);
    });
  });

  group('DailyFocus', () {
    test('donne l\'initiale française du jour', () {
      final monday = DateTime(2026, 9, 14); // un lundi
      const expected = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

      for (var i = 0; i < 7; i++) {
        final day = DailyFocus(
          day: monday.add(Duration(days: i)),
          focus: Duration.zero,
          sessions: 0,
        );
        expect(day.initial, expected[i]);
      }
    });
  });

  group('Profile', () {
    test('extrait le prénom du nom complet', () {
      const profile = Profile(id: 'u1', fullName: 'Mehdi Nafaa');
      expect(profile.firstName, 'Mehdi');
      expect(profile.initials, 'MN');
    });

    test('rend une chaîne vide plutôt qu\'un nom inventé', () {
      const profile = Profile(id: 'u1');
      expect(profile.firstName, '');
      expect(profile.initials, '?');
    });

    test('gère un nom en un seul mot', () {
      const profile = Profile(id: 'u1', fullName: 'Nura');
      expect(profile.firstName, 'Nura');
      expect(profile.initials, 'N');
    });

    test('retombe sur l\'offre gratuite pour un plan inconnu', () {
      expect(UserPlan.fromValue(null), UserPlan.free);
      expect(UserPlan.fromValue('entreprise'), UserPlan.free);
      expect(UserPlan.fromValue('pro'), UserPlan.pro);
    });
  });
}
