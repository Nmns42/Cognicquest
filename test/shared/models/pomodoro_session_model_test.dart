import 'package:cognicquest/shared/models/pomodoro_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

PomodoroSession sessionAt(DateTime startedAt, {int minutes = 25}) {
  return PomodoroSession(
    id: startedAt.toIso8601String(),
    userId: 'u1',
    startedAt: startedAt,
    durationSeconds: minutes * 60,
  );
}

void main() {
  group('PomodoroStats.fromSessions', () {
    test('sépare aujourd\'hui, la semaine et le total', () {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      // Un instant du jour garanti passé, pour ne pas dépendre de l'heure
      // à laquelle le test s'exécute.
      final today = startOfToday.add(const Duration(minutes: 1));
      // La semaine ISO démarre le lundi : on recule jusqu'au lundi courant.
      final monday = startOfToday.subtract(Duration(days: now.weekday - 1));

      final stats = PomodoroStats.fromSessions([
        sessionAt(today),
        sessionAt(today),
        sessionAt(monday.add(const Duration(hours: 9))),
        // Bien avant la semaine courante : compte seulement dans le total.
        sessionAt(startOfToday.subtract(const Duration(days: 40))),
      ]);

      expect(stats.sessionsToday, 2);
      expect(stats.sessionsAllTime, 4);
      expect(stats.focusToday, const Duration(minutes: 50));
      expect(stats.focusAllTime, const Duration(minutes: 100));
      expect(stats.sessionsThisWeek, greaterThanOrEqualTo(2));
      expect(stats.sessionsThisWeek, lessThanOrEqualTo(3));
    });

    test('rend des agrégats nuls pour une liste vide', () {
      final stats = PomodoroStats.fromSessions(const []);

      expect(stats.sessionsToday, 0);
      expect(stats.sessionsAllTime, 0);
      expect(stats.focusAllTime, Duration.zero);
    });
  });

  group('PomodoroStats.coins', () {
    test('dérive les pièces des sessions archivées', () {
      final stats = PomodoroStats.fromSessions([
        sessionAt(DateTime.now()),
        sessionAt(DateTime.now()),
        sessionAt(DateTime.now()),
      ]);

      expect(stats.coins(10), 30);
    });

    test('vaut 0 sans session', () {
      expect(const PomodoroStats.empty().coins(10), 0);
    });
  });

  group('formatFocusDuration', () {
    test('formate les durées courtes en minutes', () {
      expect(formatFocusDuration(const Duration(minutes: 25)), '25 min');
      expect(formatFocusDuration(Duration.zero), '0 min');
    });

    test('formate les heures pleines sans minutes', () {
      expect(formatFocusDuration(const Duration(hours: 2)), '2 h');
    });

    test('formate les heures et minutes', () {
      expect(formatFocusDuration(const Duration(hours: 1, minutes: 25)), '1 h 25');
    });
  });

  group('PomodoroSession', () {
    test('fait l\'aller-retour JSON en conservant la durée', () {
      final session = PomodoroSession.fromJson({
        'id': 's1',
        'user_id': 'u1',
        'started_at': '2026-02-03T08:30:00Z',
        'duration_seconds': 1500,
        'task_id': null,
      });

      expect(session.duration, const Duration(minutes: 25));
      expect(session.taskId, isNull);
      expect(session.toJson()['duration_seconds'], 1500);
    });
  });
}
