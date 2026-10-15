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

/// Premier jour de la semaine du mois située [n] semaines avant la
/// semaine courante (semaines 1 à 4 de chaque mois).
DateTime weekAgo(int n) {
  final now = DateTime.now();
  final index =
      (now.year * 12 + now.month - 1) * 4 + Habit.weekOfMonth(now) - 1 - n;
  final monthIndex = index ~/ 4;
  return Habit.startOfWeekOfMonth(
      monthIndex ~/ 12, monthIndex % 12 + 1, index % 4 + 1);
}

/// Un jour (le 10) du mois situé [n] mois avant le mois courant.
DateTime monthAgo(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month - n, 10);
}

Habit habitOn(
  HabitFrequency frequency,
  List<DateTime> days, {
  DateTime? createdAt,
}) =>
    Habit(
      id: 'h1',
      userId: 'u1',
      name: 'Habitude',
      frequency: frequency,
      createdAt: createdAt ?? DateTime(2000),
      completedDates: [for (final d in days) Habit.toDateKey(d)],
    );

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

  group('quotidienne', () {
    test('« cette semaine » compte les jours cochés du lundi au dimanche', () {
      final week = Habit.currentWeekDays();
      expect(week, hasLength(7));
      expect(week.first.weekday, DateTime.monday);
      expect(week.last.weekday, DateTime.sunday);

      final habit = habitOn(HabitFrequency.daily, [week[0], week[2]]);
      expect(habit.doneThisWeek, 2);
    });

    test("la semaine en cours est calculée depuis n'importe quel jour", () {
      // Mercredi 15 octobre 2025 → lundi 13 au dimanche 19.
      final week = Habit.currentWeekDays(DateTime(2025, 10, 15, 18));
      expect(week.first, DateTime(2025, 10, 13));
      expect(week.last, DateTime(2025, 10, 19));
    });
  });

  group('hebdomadaire', () {
    test('semaines du mois : 1–7, 8–14, 15–21, puis 22 à la fin', () {
      expect(Habit.weekOfMonth(DateTime(2025, 1, 1)), 1);
      expect(Habit.weekOfMonth(DateTime(2025, 1, 7)), 1);
      expect(Habit.weekOfMonth(DateTime(2025, 1, 8)), 2);
      expect(Habit.weekOfMonth(DateTime(2025, 1, 21)), 3);
      expect(Habit.weekOfMonth(DateTime(2025, 1, 22)), 4);
      expect(Habit.weekOfMonth(DateTime(2025, 1, 31)), 4);
    });

    test('une semaine est validée par un seul jour coché', () {
      final habit =
          habitOn(HabitFrequency.weekly, [DateTime(2025, 3, 10)]);
      expect(habit.isWeekDone(2025, 3, 2), isTrue);
      expect(habit.isWeekDone(2025, 3, 1), isFalse);
      expect(habit.totalCompletions, 1);
    });

    test('série en semaines consécutives, même à cheval sur deux mois', () {
      // Deux jours dans la même semaine ne comptent qu'une fois.
      final habit = habitOn(HabitFrequency.weekly, [
        weekAgo(0),
        weekAgo(0).add(const Duration(days: 1)),
        weekAgo(1),
        weekAgo(2),
        weekAgo(3),
        weekAgo(4),
        weekAgo(6),
      ]);
      expect(habit.streak, 5);
      expect(habit.bestStreak, 5);
      expect(habit.totalCompletions, 6);
    });

    test('la semaine en cours non cochée ne casse pas la série', () {
      final habit =
          habitOn(HabitFrequency.weekly, [weekAgo(1), weekAgo(2)]);
      expect(habit.streak, 2);
      expect(habit.completedToday, isFalse);
    });

    test('cocher puis décocher une semaine passée', () {
      final day = weekAgo(2);
      final habit = habitOn(HabitFrequency.weekly, const []);

      final checked = habit.withToggleOn(day);
      expect(checked.isDoneInPeriodOf(day), isTrue);
      expect(checked.completedDates, [Habit.toDateKey(day)]);

      final unchecked = checked.withToggleOn(day);
      expect(unchecked.isDoneInPeriodOf(day), isFalse);
      expect(unchecked.completedDates, isEmpty);
    });

    test('décocher une semaine retire tous ses jours cochés', () {
      final start = weekAgo(1);
      final habit = habitOn(HabitFrequency.weekly,
          [start, start.add(const Duration(days: 2)), weekAgo(3)]);
      final unchecked = habit.withToggleOn(start);
      expect(unchecked.completedDates, [Habit.toDateKey(weekAgo(3))]);
    });

    test("cocher la semaine en cours coche aujourd'hui", () {
      final habit = habitOn(HabitFrequency.weekly, const []).withToggleToday();
      expect(habit.completedDates, [Habit.toDateKey(DateTime.now())]);
      expect(habit.completedToday, isTrue);
    });

    test('régularité sur les 8 dernières semaines', () {
      final habit = habitOn(HabitFrequency.weekly,
          [weekAgo(0), weekAgo(2), weekAgo(4), weekAgo(6)]);
      expect(habit.recentSuccessRate, closeTo(0.5, 0.001));
    });
  });

  group('mensuelle', () {
    test('un mois est validé par un seul jour coché', () {
      final habit = habitOn(HabitFrequency.monthly, [DateTime(2025, 1, 20)]);
      expect(habit.isMonthDone(2025, 1), isTrue);
      expect(habit.isMonthDone(2025, 2), isFalse);
    });

    test("série en mois consécutifs, à travers le changement d'année", () {
      final habit = habitOn(HabitFrequency.monthly, [
        for (var n = 1; n <= 14; n++) monthAgo(n),
      ]);
      expect(habit.streak, 14);
      expect(habit.bestStreak, 14);
    });

    test('cocher puis décocher un mois', () {
      final habit = habitOn(HabitFrequency.monthly, const []);
      final january = DateTime(DateTime.now().year - 1, 1);

      final checked = habit.withToggleOn(january);
      expect(checked.isMonthDone(january.year, 1), isTrue);

      final unchecked = checked.withToggleOn(january);
      expect(unchecked.isMonthDone(january.year, 1), isFalse);
      expect(unchecked.completedDates, isEmpty);
    });

    test('régularité sur 12 mois, bornée à la création', () {
      final habit = habitOn(
        HabitFrequency.monthly,
        [monthAgo(0), monthAgo(2)],
        createdAt: monthAgo(3),
      );
      // Fenêtre de 4 mois (création il y a 3 mois), 2 validés.
      expect(habit.recentSuccessRate, closeTo(0.5, 0.001));
      expect(habit.consistency, closeTo(0.5, 0.001));
    });
  });

  group('unités', () {
    test('libellés par fréquence', () {
      expect(HabitFrequency.daily.unit(2), 'jours');
      expect(HabitFrequency.weekly.unit(1), 'semaine');
      expect(HabitFrequency.monthly.unit(3), 'mois');
      expect(HabitFrequency.weekly.shortUnit, 'sem.');
    });
  });
}
