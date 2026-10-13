import 'package:cognicquest/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:cognicquest/features/pomodoro/views/pomodoro_page.dart';
import 'package:cognicquest/shared/models/pomodoro_session_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pomodoro figé : pas de minuteur, pas d'historique.
class _IdlePomodoro extends PomodoroNotifier {
  @override
  PomodoroState build() => PomodoroState.initial();
}

/// Le cadran reste proportionné : jamais plus de 260 px, quel que soit
/// l'écran, et la page tient dans une colonne de 520 px au plus.
void main() {
  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        pomodoroProvider.overrideWith(_IdlePomodoro.new),
        pomodoroStatsProvider
            .overrideWith((ref) => Stream.value(const PomodoroStats.empty())),
      ],
      child: const MaterialApp(home: PomodoroPage()),
    ));
    await tester.pumpAndSettle();
  }

  for (final size in const [
    Size(390, 844),
    Size(1024, 768),
    Size(2560, 1440)
  ]) {
    testWidgets('cadran borné sur ${size.width.toInt()}×${size.height.toInt()}',
        (tester) async {
      await pump(tester, size);
      final dial = tester.getSize(find.byType(CircularProgressIndicator));
      expect(dial.width, inInclusiveRange(180, 260));
      expect(dial.width, dial.height);
      expect(tester.getSize(find.byType(Column).first).width,
          lessThanOrEqualTo(520));
      expect(tester.takeException(), isNull);
    });
  }
}
