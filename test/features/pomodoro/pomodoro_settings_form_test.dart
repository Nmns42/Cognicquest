import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/features/pomodoro/widgets/pomodoro_settings_form.dart';
import 'package:cognicquest/features/settings/domain/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('saisie d\'un nombre entier', () {
    test('entiers et décimales (virgule ou point) arrondis', () {
      expect(parseWholeNumber('42'), 42);
      expect(parseWholeNumber(' 62 '), 62);
      expect(parseWholeNumber('1,2'), 1);
      expect(parseWholeNumber('1.6'), 2);
      expect(parseWholeNumber('2,5'), 3);
    });

    test('saisie vide ou invalide : rien', () {
      expect(parseWholeNumber(''), isNull);
      expect(parseWholeNumber('abc'), isNull);
      expect(parseWholeNumber('1,2,3'), isNull);
    });
  });

  group('formulaire du Pomodoro', () {
    Future<List<PomodoroSettings>> pump(WidgetTester tester) async {
      final changes = <PomodoroSettings>[];
      var config = PomodoroSettings.defaults;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: PomodoroDurationsForm(
                config: config,
                onChanged: (next) {
                  changes.add(next);
                  setState(() => config = next);
                },
              ),
            ),
          ),
        ),
      ));
      return changes;
    }

    Finder field(String label) => find.descendant(
          of: find.bySemanticsLabel(RegExp('^$label, en ')),
          matching: find.byType(TextField),
        );

    testWidgets('sessions, focus et pauses saisis librement', (tester) async {
      final changes = await pump(tester);

      Future<void> type(String label, String text) async {
        await tester.enterText(field(label), text);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
      }

      await type('Nombre de sessions', '3');
      await type('Durée Focus', '62');
      await type('Pause courte', '5');
      await type('Pause longue', '3');

      final last = changes.last;
      expect(last.sessionsBeforeLongBreak, 3);
      expect(last.workMinutes, 62);
      expect(last.shortBreakMinutes, 5);
      expect(last.longBreakMinutes, 3);
    });

    testWidgets('hors bornes : ramené à la limite, avec explication',
        (tester) async {
      final changes = await pump(tester);
      await tester.enterText(field('Nombre de sessions'), '40');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(changes.last.sessionsBeforeLongBreak, 12);
      expect(find.textContaining('Ramené à 12'), findsOneWidget);
    });
  });
}
