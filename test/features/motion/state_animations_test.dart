import 'package:cognicquest/features/kanban/widgets/task_card.dart';
import 'package:cognicquest/features/metacognition/widgets/scale_picker.dart';
import 'package:cognicquest/features/sync/providers/sync_coordinator.dart';
import 'package:cognicquest/features/sync/widgets/offline_banner.dart';
import 'package:cognicquest/shared/models/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// « Animations réduites », lot sélections et états (AnimatedContainer,
/// AnimatedSize) : réduites, elles atteignent leur état final dès la première
/// frame ; normales, elles gardent leur durée et leurs frames intermédiaires.
void main() {
  Widget host(Widget child, {required bool reduced}) => MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: Scaffold(body: child),
          ),
        ),
      );

  /// Décorations de tous les AnimatedContainer, telles que peintes.
  List<Decoration?> decorations(WidgetTester tester) => [
        for (final element in find
            .descendant(
              of: find.byType(AnimatedContainer),
              matching: find.byType(DecoratedBox),
            )
            .evaluate())
          (element.widget as DecoratedBox).decoration,
      ];

  List<Duration> durations(WidgetTester tester) => [
        for (final element in find.byType(AnimatedContainer).evaluate())
          (element.widget as AnimatedContainer).duration,
      ];

  /// État une frame après [change], puis une fois tout stabilisé.
  Future<(T, T)> framesAfter<T>(
    WidgetTester tester,
    Future<void> Function() change,
    T Function() read,
  ) async {
    await change();
    await tester.pump(); // reconstruction
    await tester.pump(const Duration(milliseconds: 16)); // une frame
    final firstFrame = read();
    await tester.pumpAndSettle();
    return (firstFrame, read());
  }

  group('échelle de sélection (journal, profil)', () {
    Widget picker(int value, {required bool reduced}) => host(
          ScalePicker(
            label: 'Énergie',
            hint: '',
            value: value,
            max: 5,
            onChanged: (_) {},
          ),
          reduced: reduced,
        );

    for (final reduced in [true, false]) {
      testWidgets(reduced ? '(a) réduite : état final dès la première frame'
          : '(b) normale : durée et transition d\'origine', (tester) async {
        await tester.pumpWidget(picker(2, reduced: reduced));
        final (first, settled) = await framesAfter(
          tester,
          () => tester.pumpWidget(picker(4, reduced: reduced)),
          () => decorations(tester),
        );

        if (reduced) {
          expect(durations(tester), everyElement(Duration.zero));
          expect(first, settled);
        } else {
          expect(durations(tester),
              everyElement(const Duration(milliseconds: 150)));
          expect(first, isNot(settled));
        }
      });
    }
  });

  group('carte de tâche (Kanban)', () {
    Task task({required bool done}) => Task(
          id: 't1',
          userId: 'u1',
          title: 'Réviser',
          description: '',
          status: done ? TaskStatus.done : TaskStatus.todo,
          priority: TaskPriority.medium,
          createdAt: DateTime(2026, 10, 1),
        );

    Widget card({required bool done, required bool reduced}) => host(
          TaskCard(task: task(done: done), onTap: () {}, onToggleDone: () {}),
          reduced: reduced,
        );

    for (final reduced in [true, false]) {
      testWidgets(reduced ? '(a) réduite : case cochée instantanément'
          : '(b) normale : durée et transition d\'origine', (tester) async {
        await tester.pumpWidget(card(done: false, reduced: reduced));
        final (first, settled) = await framesAfter(
          tester,
          () => tester.pumpWidget(card(done: true, reduced: reduced)),
          () => decorations(tester),
        );

        if (reduced) {
          expect(durations(tester), everyElement(Duration.zero));
          expect(first, settled);
        } else {
          expect(durations(tester),
              everyElement(const Duration(milliseconds: 180)));
          expect(first, isNot(settled));
        }
      });
    }
  });

  group('bannière hors ligne (AnimatedSize)', () {
    for (final reduced in [true, false]) {
      testWidgets(reduced ? '(a) réduite : apparaît d\'un coup'
          : '(b) normale : déroulé d\'origine', (tester) async {
        final container = ProviderContainer(overrides: [
          syncCoordinatorProvider.overrideWith(_FakeSync.new),
        ]);
        addTearDown(container.dispose);
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: host(const OfflineBanner(), reduced: reduced),
        ));

        final (first, settled) = await framesAfter(
          tester,
          () async => (container.read(syncCoordinatorProvider.notifier)
                  as _FakeSync)
              .goOffline(),
          () => tester.getSize(find.byType(OfflineBanner)),
        );

        if (reduced) {
          // Pas d'AnimatedSize à durée nulle (assertion de layout Flutter) :
          // il est retiré.
          expect(find.byType(AnimatedSize), findsNothing);
          expect(first, settled);
        } else {
          final animated =
              tester.widget<AnimatedSize>(find.byType(AnimatedSize));
          expect(animated.duration, const Duration(milliseconds: 250));
          expect(first, isNot(settled));
        }
      });
    }
  });
}

/// Coordinateur de synchronisation factice : en ligne, puis hors ligne.
class _FakeSync extends SyncCoordinator {
  @override
  SyncStatus build() => const SyncStatus();

  void goOffline() => state = const SyncStatus(isOffline: true);
}
