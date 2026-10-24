import 'package:cognicquest/features/reminders/reminder_service.dart';
import 'package:cognicquest/features/settings/domain/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prochaine occurrence du rappel', () {
    test('aujourd\'hui si l\'heure n\'est pas passée', () {
      final next =
          ReminderService.nextOccurrence(DateTime(2026, 10, 24, 9), 18 * 60);
      expect(next, DateTime(2026, 10, 24, 18));
    });

    test('demain si l\'heure est passée, ou pile maintenant', () {
      expect(ReminderService.nextOccurrence(DateTime(2026, 10, 24, 19), 18 * 60),
          DateTime(2026, 10, 25, 18));
      expect(ReminderService.nextOccurrence(DateTime(2026, 10, 24, 18), 18 * 60),
          DateTime(2026, 10, 25, 18));
    });

    test('passage au mois suivant', () {
      expect(
          ReminderService.nextOccurrence(DateTime(2026, 10, 31, 23), 7 * 60 + 30),
          DateTime(2026, 11, 1, 7, 30));
    });
  });

  test('libellé de l\'heure', () {
    expect(reminderTimeLabel(18 * 60), '18 h 00');
    expect(reminderTimeLabel(7 * 60 + 5), '7 h 05');
  });

  group('réglages des rappels', () {
    test('valeurs par défaut : rappel coupé à 18 h, Pomodoro notifié', () {
      const settings = UserSettings.defaults;
      expect(settings.dailyReminder, isFalse);
      expect(settings.dailyReminderMinutes, 18 * 60);
      expect(settings.pomodoroNotifications, isTrue);
    });

    test('aller-retour JSON, et valeur aberrante bornée', () {
      final settings = UserSettings.defaults.copyWith(
        dailyReminder: true,
        dailyReminderMinutes: 21 * 60 + 15,
        pomodoroNotifications: false,
      );
      expect(UserSettings.fromJson(settings.toJson()), settings);

      final clamped =
          UserSettings.fromJson({'daily_reminder_minutes': 99999});
      expect(clamped.dailyReminderMinutes, 24 * 60 - 1);
    });

    test('anciens réglages sans ces clés : valeurs par défaut', () {
      expect(UserSettings.fromJson(const {}), UserSettings.defaults);
    });
  });
}
