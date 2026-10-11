import 'package:cognicquest/core/motion/micro_animations.dart';
import 'package:cognicquest/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:cognicquest/features/pomodoro/views/pomodoro_page.dart';
import 'package:cognicquest/shared/models/pomodoro_session_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pomodoro piloté à la main : pas de minuteur, pas d'historique.
class _FakePomodoro extends PomodoroNotifier {
  @override
  PomodoroState build() => PomodoroState.initial();

  void set(PomodoroState next) => state = next;
}

/// Micro-animation n° 7 : la jauge bat une fois à la fin d'une session de
/// travail.
void main() {
  List<Override> overrides() => [
        pomodoroProvider.overrideWith(_FakePomodoro.new),
        pomodoroStatsProvider
            .overrideWith((ref) => Stream.value(const PomodoroStats.empty())),
      ];

  /// Fin naturelle d'une session de travail : pause suivante, une session
  /// de plus.
  PomodoroState finished(PomodoroState s) => s.copyWith(
        phase: PomodoroPhase.shortBreak,
        status: PomodoroStatus.idle,
        completedSessions: s.completedSessions + 1,
      );

  group('signal de fin de session', () {
    late ProviderContainer container;
    late _FakePomodoro pomodoro;

    setUp(() {
      container = ProviderContainer(overrides: overrides());
      container.listen(pomodoroCompletionsProvider, (_, __) {});
      pomodoro = container.read(pomodoroProvider.notifier) as _FakePomodoro;
    });
    tearDown(() => container.dispose());

    test('une session menée à son terme compte', () {
      pomodoro.set(finished(container.read(pomodoroProvider)));
      expect(container.read(pomodoroCompletionsProvider), 1);
    });

    test('« Passer » une session de travail ne compte pas', () {
      final s = container.read(pomodoroProvider);
      pomodoro.set(s.copyWith(phase: PomodoroPhase.shortBreak));
      expect(container.read(pomodoroCompletionsProvider), 0);
    });

    test('le recalage sur l\'historique au chargement ne compte pas', () {
      final s = container.read(pomodoroProvider);
      pomodoro.set(s.copyWith(completedSessions: 5));
      expect(container.read(pomodoroCompletionsProvider), 0);
    });

    test('la fin d\'une pause ne compte pas', () {
      final s = finished(container.read(pomodoroProvider));
      pomodoro.set(s);
      pomodoro.set(s.copyWith(phase: PomodoroPhase.work));
      expect(container.read(pomodoroCompletionsProvider), 1);
    });
  });

  group('pulsation de la jauge', () {
    Future<_FakePomodoro> pumpPage(WidgetTester tester,
        {required bool reduced}) async {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: const PomodoroPage(),
        ),
      ));
      await tester.pumpAndSettle();
      return container.read(pomodoroProvider.notifier) as _FakePomodoro;
    }

    double scale(WidgetTester tester) => tester
        .widget<Transform>(find
            .descendant(
                of: find.byType(PulseOnChange),
                matching: find.byType(Transform))
            .first)
        .transform
        .getMaxScaleOnAxis();

    Duration duration(WidgetTester tester) => tester
        .widget<TweenAnimationBuilder<double>>(find
            .descendant(
                of: find.byType(PulseOnChange),
                matching: find.byType(TweenAnimationBuilder<double>))
            .first)
        .duration;

    testWidgets('normal : la jauge grossit puis revient', (tester) async {
      final pomodoro = await pumpPage(tester, reduced: false);
      expect(duration(tester), const Duration(milliseconds: 420));
      expect(scale(tester), 1.0);

      pomodoro.set(finished(pomodoro.state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 210)); // mi-battement
      expect(scale(tester), greaterThan(1.04));

      await tester.pumpAndSettle();
      expect(scale(tester), closeTo(1.0, 1e-9));
    });

    testWidgets('réduit : aucune frame intermédiaire', (tester) async {
      final pomodoro = await pumpPage(tester, reduced: true);
      expect(duration(tester), Duration.zero);

      pomodoro.set(finished(pomodoro.state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(scale(tester), closeTo(1.0, 1e-9));
    });

    testWidgets('ouvrir la page ne fait pas battre la jauge', (tester) async {
      final pomodoro = await pumpPage(tester, reduced: false);
      // Recalage sur l'historique, comme au chargement réel.
      pomodoro.set(pomodoro.state.copyWith(completedSessions: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 210));
      expect(scale(tester), 1.0);
    });
  });
}
