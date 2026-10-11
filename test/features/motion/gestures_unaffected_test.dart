import 'package:cognicquest/core/motion/reduce_motion.dart';
import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Décisions D1 à D3 : en mode réduit, glisser-déposer, balayage, inertie
/// et vol Hero fonctionnent comme en mode normal.
///
/// L'hôte reproduit exactement ce que `CognicQuestApp` applique à la racine
/// en mode réduit : thème réduit, pas d'animation de thème, et
/// `MediaQuery.disableAnimations`.
void main() {
  Widget host(Widget home, {required bool reduced}) => MaterialApp(
        theme: reduced ? Motion.reducedTheme(AppTheme.light) : AppTheme.light,
        themeAnimationStyle: reduced ? AnimationStyle.noAnimation : null,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: child!,
        ),
        home: home,
      );

  /// Rejoue [gesture] et relève [read] à chaque frame jusqu'à la fin.
  Future<List<Object?>> trace(
    WidgetTester tester,
    Widget home, {
    required bool reduced,
    required Future<void> Function() gesture,
    required Object? Function() read,
  }) async {
    await tester.pumpWidget(host(home, reduced: reduced));
    await tester.pumpAndSettle();
    await gesture();
    final frames = <Object?>[];
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      frames.add(read());
    }
    await tester.pumpAndSettle();
    return frames;
  }

  /// Vérifie que le mouvement est animé (plusieurs états intermédiaires) et
  /// identique dans les deux modes.
  void expectSameAnimatedMotion(List<Object?> normal, List<Object?> reduced) {
    expect(normal.toSet().length, greaterThan(3),
        reason: 'le geste devrait être animé en mode normal');
    expect(reduced, normal);
  }

  testWidgets('D1/D3 glisser-déposer (liste réordonnable) : identique',
      (tester) async {
    final orders = <bool, List<String>>{};
    Future<List<Object?>> run(bool reduced) {
      final items = ['A', 'B', 'C', 'D', 'E'];
      return trace(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: ReorderableListView(
              onReorderItem: (from, to) => setState(() {
                items.insert(to, items.removeAt(from));
                orders[reduced] = [...items];
              }),
              children: [
                for (final item in items)
                  ListTile(key: ValueKey(item), title: Text(item)),
              ],
            ),
          ),
        ),
        reduced: reduced,
        gesture: () async {
          final drag = await tester.startGesture(tester.getCenter(find.text('A')));
          await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
          for (var i = 0; i < 6; i++) {
            await drag.moveBy(const Offset(0, 25));
            await tester.pump(const Duration(milliseconds: 16));
          }
          await drag.up();
        },
        read: () => tester.getRect(find.text('B')),
      );
    }

    final normal = await run(false);
    final reduced = await run(true);
    expectSameAnimatedMotion(normal, reduced);
    expect(orders[true], isNotNull, reason: 'le dépôt doit réordonner');
    expect(orders[true], orders[false]);
  });

  testWidgets('D3 balayage pour supprimer (Kanban) : identique',
      (tester) async {
    final dismissed = <bool, bool>{};
    Future<List<Object?>> run(bool reduced) {
      var visible = true;
      return trace(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: ListView(children: [
              if (visible)
                Dismissible(
                  key: const ValueKey('carte'),
                  onDismissed: (_) => setState(() {
                    visible = false;
                    dismissed[reduced] = true;
                  }),
                  child: const ListTile(title: Text('carte')),
                ),
            ]),
          ),
        ),
        reduced: reduced,
        gesture: () =>
            tester.fling(find.text('carte'), const Offset(-300, 0), 1000),
        read: () => find.text('carte').evaluate().isEmpty
            ? null
            : tester.getRect(find.text('carte')),
      );
    }

    final normal = await run(false);
    final reduced = await run(true);
    expectSameAnimatedMotion(normal, reduced);
    expect(dismissed, {false: true, true: true});
  });

  testWidgets('D3 inertie après un glissé (carte du graphe) : identique',
      (tester) async {
    Future<List<Object?>> run(bool reduced) {
      final controller = TransformationController();
      addTearDown(controller.dispose);
      return trace(
        tester,
        Scaffold(
          body: InteractiveViewer(
            transformationController: controller,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(2000),
            child: const SizedBox(width: 2000, height: 2000),
          ),
        ),
        reduced: reduced,
        gesture: () => tester.fling(
            find.byType(InteractiveViewer), const Offset(-200, 0), 1500),
        read: () => controller.value.getTranslation().x,
      );
    }

    final normal = await run(false);
    final reduced = await run(true);
    // Inertie : la carte continue de glisser après le lâcher.
    expectSameAnimatedMotion(normal, reduced);
  });

  for (final reduced in [false, true]) {
    testWidgets('D3 vol Hero des boutons flottants '
        '(${reduced ? 'mode réduit' : 'mode normal'})', (tester) async {
      await tester.pumpWidget(host(
        Builder(
          builder: (context) => Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  body: const SizedBox.expand(),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  ),
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.startTop,
                ),
              )),
              child: const Icon(Icons.add),
            ),
          ),
        ),
        reduced: reduced,
      ));
      // Le Hero est construit *dans* le bouton : c'est son contenu (l'icône)
      // qui vole, pas le FloatingActionButton lui-même.
      final start = tester.getCenter(find.byIcon(Icons.add)).dx;

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      final path = <double>[];
      for (var i = 0; i < 9; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        path.add(tester.getCenter(find.byIcon(Icons.add).last).dx);
      }
      await tester.pumpAndSettle();
      final end = tester.getCenter(find.byIcon(Icons.add)).dx;

      // Vol : l'icône traverse l'écran par plusieurs positions intermédiaires
      // au lieu de sauter d'un coin à l'autre.
      final between = path.where((x) => x < start - 50 && x > end + 50);
      expect(between.length, greaterThanOrEqualTo(3), reason: '$path');
    });
  }
}
