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

/// Écran statique et proportionné : aucun défilement, tout tient dans la
/// fenêtre, et le cadran grandit avec l'écran au lieu d'être plafonné.
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

  Size dialOf(WidgetTester tester) =>
      tester.getSize(find.byType(CircularProgressIndicator));

  void expectStaticAndInside(WidgetTester tester, Size size) {
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
    // Le dernier élément (statistiques) reste dans la fenêtre.
    final bottom = tester.getBottomRight(find.text('Cette semaine')).dy;
    expect(bottom, lessThanOrEqualTo(size.height));
  }

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets(
        'téléphone ${size.width.toInt()}×${size.height.toInt()} : '
        'tout tient sans défiler', (tester) async {
      await pump(tester, size);
      expectStaticAndInside(tester, size);
      final dial = dialOf(tester);
      expect(dial.width, dial.height);
      expect(dial.width, greaterThanOrEqualTo(size.width * 0.5));
    });
  }

  for (final size in const [Size(1024, 768), Size(2560, 1440)]) {
    testWidgets(
        'grand écran ${size.width.toInt()}×${size.height.toInt()} : '
        'cadran à l\'échelle de l\'écran', (tester) async {
      await pump(tester, size);
      expectStaticAndInside(tester, size);
      final dial = dialOf(tester);
      expect(dial.width, dial.height);
      // Plus de plafond à 260 px : le cadran occupe l'essentiel de la hauteur.
      expect(dial.height, greaterThanOrEqualTo(size.height * 0.55));
      expect(dial.width, lessThanOrEqualTo(size.width * 0.6));
    });
  }
}
