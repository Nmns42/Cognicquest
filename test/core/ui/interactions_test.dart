import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/core/ui/ui.dart';
import 'package:cognicquest/features/dashboard/models/dashboard_module.dart';
import 'package:cognicquest/features/dashboard/providers/dashboard_layout_provider.dart';
import 'package:cognicquest/features/dashboard/widgets/module_picker_sheet.dart';
import 'package:cognicquest/features/settings/data/preferences_repository.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Interactions de la Phase 3 : glisser-déposer, poignées au survol,
/// défilement des feuilles.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
      );

  group('CqDraggable', () {
    late List<String> dropped;

    Widget board() => Column(
          children: [
            CqDraggable<String>(
              data: 'tâche',
              feedback: const Text('en vol'),
              child: const SizedBox(
                  width: 200, height: 60, child: Text('Réviser la cardio')),
            ),
            const SizedBox(height: 200),
            DragTarget<String>(
              onAcceptWithDetails: (d) => dropped.add(d.data),
              builder: (_, __, ___) => const SizedBox(
                  width: 200, height: 80, child: Text('Terminé')),
            ),
          ],
        );

    setUp(() => dropped = []);

    testWidgets('à la souris, le glisser démarre aussitôt', (tester) async {
      await pump(tester, board());
      final from = tester.getCenter(find.text('Réviser la cardio'));
      final to = tester.getCenter(find.text('Terminé'));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(from); // survol : passe en mode souris
      await tester.pump();
      await mouse.down(from);
      await mouse.moveTo(to, timeStamp: const Duration(milliseconds: 16));
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();

      expect(dropped, ['tâche']);
    });

    testWidgets('au doigt, un geste rapide fait défiler, pas glisser',
        (tester) async {
      await pump(tester, board());
      await tester.dragFrom(
        tester.getCenter(find.text('Réviser la cardio')),
        tester.getCenter(find.text('Terminé')) -
            tester.getCenter(find.text('Réviser la cardio')),
      );
      await tester.pumpAndSettle();

      expect(dropped, isEmpty);
    });

    testWidgets('au doigt, après un court appui, la tâche se dépose',
        (tester) async {
      await pump(tester, board());
      final finger = await tester
          .startGesture(tester.getCenter(find.text('Réviser la cardio')));
      await tester.pump(CqDraggable.touchDelay + const Duration(milliseconds: 50));
      await finger.moveTo(tester.getCenter(find.text('Terminé')));
      await tester.pump();
      await finger.up();
      await tester.pumpAndSettle();

      expect(dropped, ['tâche']);
    });
  });

  group('CqReorderableItem', () {
    double gripOpacity(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(find.descendant(
            of: find.byType(HoverReveal), matching: find.byType(AnimatedOpacity)))
        .opacity;

    testWidgets('poignée masquée par défaut, visible au survol',
        (tester) async {
      await pump(
        tester,
        ReorderableListView(
          buildDefaultDragHandles: false,
          onReorderItem: (_, __) {},
          children: const [
            CqReorderableItem(
              key: ValueKey('a'),
              index: 0,
              child: SizedBox(height: 56, child: Text('Habitude')),
            ),
          ],
        ),
      );
      expect(gripOpacity(tester), 0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Habitude')));
      await tester.pumpAndSettle();
      expect(gripOpacity(tester), 1);

      await mouse.moveTo(const Offset(5, 590));
      await tester.pumpAndSettle();
      expect(gripOpacity(tester), 0);
    });
  });

  group('CqSegmentedControl', () {
    testWidgets('bascule entre deux vues', (tester) async {
      var view = 'kanban';
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => CqSegmentedControl<String>(
            options: const {'kanban': 'Kanban', 'matrix': 'Matrice'},
            selected: view,
            onChanged: (v) => setState(() => view = v),
          ),
        ),
      );
      await tester.tap(find.text('Matrice'));
      await tester.pumpAndSettle();
      expect(view, 'matrix');
      expect(tester.getSize(find.text('Matrice').hitTestable()).height,
          greaterThan(0));
    });
  });

  testWidgets('feuille « Personnaliser » : défile jusqu\'au bouton du bas '
      'sur un petit écran', (tester) async {
    tester.view.physicalSize = const Size(360, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);
    // Tout visible, pour vérifier que « Rétablir » rétablit bien.
    container.read(dashboardLayoutProvider.notifier).toggle(
        DashboardModule.stats);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => ModulePickerSheet.show(context),
              child: const Text('Personnaliser'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Personnaliser'));
    await tester.pumpAndSettle();

    final reset = find.text('Rétablir la disposition par défaut');
    await tester.scrollUntilVisible(reset, 100,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(reset);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(container.read(dashboardLayoutProvider), DashboardLayout.initial);
    // Laisse partir l'enregistrement différé de la disposition.
    await tester.pump(const Duration(seconds: 1));
  });
}
