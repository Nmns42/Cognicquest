import 'package:cognicquest/shared/models/habit_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Construit une habitude dont les jours validés sont exprimés en « il y a N
/// jours », pour que les tests restent valables quelle que soit la date.
Habit habitWithOffsets(
  List<int> daysAgo, {
  int createdDaysAgo = 60,
}) {
  final today = DateTime.now();
  return Habit(
    id: 'h1',
    userId: 'u1',
    name: 'Méditation',
    createdAt: today.subtract(Duration(days: createdDaysAgo)),
    completedDates: [
      for (final offset in daysAgo)
        Habit.toDateKey(today.subtract(Duration(days: offset))),
    ],
  );
}

void main() {
  group('Habit.streak', () {
    test('compte la série en cours quand aujourd\'hui est validé', () {
      expect(habitWithOffsets([0, 1, 2]).streak, 3);
    });

    test(
        'ne remet pas la série à zéro quand aujourd\'hui n\'est pas encore '
        'validé', () {
      // Régression : l'ancienne implémentation partait toujours d'aujourd'hui
      // et affichait 0 pour une habitude tenue la veille et les jours d'avant.
      expect(habitWithOffsets([1, 2, 3]).streak, 3);
    });

    test('s\'arrête au premier jour manquant', () {
      expect(habitWithOffsets([0, 1, 3, 4]).streak, 2);
    });

    test('vaut 0 sans aucune validation', () {
      expect(habitWithOffsets(const []).streak, 0);
    });

    test('vaut 0 si le dernier jour validé remonte à plus de deux jours', () {
      expect(habitWithOffsets([2, 3, 4]).streak, 0);
    });
  });

  group('Habit.bestStreak', () {
    test('retient la plus longue série historique', () {
      // Série de 4 (jours 10→13) puis série de 2 (jours 1→2).
      expect(habitWithOffsets([1, 2, 10, 11, 12, 13]).bestStreak, 4);
    });

    test('vaut 0 sans validation', () {
      expect(habitWithOffsets(const []).bestStreak, 0);
    });

    test('vaut 1 pour une validation isolée', () {
      expect(habitWithOffsets([5]).bestStreak, 1);
    });
  });

  group('Habit.successRateLast30Days', () {
    test('rapporte les jours validés à la fenêtre réellement écoulée', () {
      // Créée il y a 9 jours → fenêtre de 10 jours, 5 validés.
      final habit = habitWithOffsets([0, 1, 2, 3, 4], createdDaysAgo: 9);
      expect(habit.successRateLast30Days, closeTo(0.5, 0.001));
    });

    test('vaut 0 sans validation', () {
      expect(habitWithOffsets(const []).successRateLast30Days, 0);
    });
  });

  group('Habit.withToggleOn', () {
    test('ajoute puis retire le jour, sans effet de bord sur l\'original', () {
      final habit = habitWithOffsets(const []);

      final toggledOn = habit.withToggleToday();
      expect(toggledOn.completedToday, isTrue);
      expect(habit.completedToday, isFalse,
          reason: 'le modèle doit rester immuable');

      final toggledOff = toggledOn.withToggleToday();
      expect(toggledOff.completedToday, isFalse);
    });
  });

  group('Habit.lastDays', () {
    test('rend les jours du plus ancien au plus récent', () {
      final habit = habitWithOffsets([0]);
      final week = habit.last7Days;

      expect(week, hasLength(7));
      expect(week.last, isTrue, reason: 'le dernier élément est aujourd\'hui');
      expect(week.take(6), everyElement(isFalse));
    });
  });

  group('HabitFrequency', () {
    test('retombe sur « quotidienne » pour une valeur inconnue ou nulle', () {
      expect(HabitFrequency.fromValue(null), HabitFrequency.daily);
      expect(HabitFrequency.fromValue('yearly'), HabitFrequency.daily);
      expect(HabitFrequency.fromValue('weekly'), HabitFrequency.weekly);
    });
  });
}
