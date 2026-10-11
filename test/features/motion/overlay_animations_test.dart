import 'package:cognicquest/core/motion/reduce_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// « Animations réduites », lot feuilles, dialogues, menus et messages :
/// mêmes appels que dans l'app, avec `Motion.style(context)`.
void main() {
  Widget host({required bool reduced, required WidgetBuilder button}) =>
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: Scaffold(body: Center(child: Builder(builder: button))),
          ),
        ),
      );

  /// Position (et opacité cumulée) de [target] une frame après le tap, puis
  /// une fois l'animation terminée.
  Future<((Rect, double), (Rect, double))> afterTap(
    WidgetTester tester,
    Finder target,
  ) async {
    (Rect, double) read() {
      var opacity = 1.0;
      for (final fade in find
          .ancestor(of: target, matching: find.byType(FadeTransition))
          .evaluate()) {
        opacity *= (fade.widget as FadeTransition).opacity.value;
      }
      return (tester.getRect(target), opacity);
    }

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // ouverture
    await tester.pump(const Duration(milliseconds: 16)); // une frame
    final first = read();
    await tester.pumpAndSettle();
    return (first, read());
  }

  final overlays = <String, WidgetBuilder>{
    'feuille du bas': (context) => ElevatedButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            sheetAnimationStyle: Motion.style(context),
            builder: (_) => const SizedBox(height: 200, child: Text('cible')),
          ),
          child: const Text('ouvrir'),
        ),
    'dialogue de confirmation': (context) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: context,
            animationStyle: Motion.style(context),
            builder: (_) => const AlertDialog(title: Text('cible')),
          ),
          child: const Text('ouvrir'),
        ),
    'message (SnackBar)': (context) => ElevatedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('cible')),
            snackBarAnimationStyle: Motion.style(context),
          ),
          child: const Text('ouvrir'),
        ),
  };

  for (final MapEntry(key: name, value: button) in overlays.entries) {
    group(name, () {
      testWidgets('(a) réduite : à sa place et opaque dès la première frame',
          (tester) async {
        await tester.pumpWidget(host(reduced: true, button: button));
        final (first, settled) = await afterTap(tester, find.text('cible'));
        expect(first, settled);
        expect(first.$2, 1.0);
      });

      testWidgets('(b) normale : animation d\'origine', (tester) async {
        await tester.pumpWidget(host(reduced: false, button: button));
        final (first, settled) = await afterTap(tester, find.text('cible'));
        expect(first, isNot(settled));
      });
    });
  }

  group('menu contextuel', () {
    Widget menu({required bool reduced}) => host(
          reduced: reduced,
          button: (context) => PopupMenuButton<int>(
            popUpAnimationStyle: Motion.style(context),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1, child: Text('cible')),
            ],
            child: const ElevatedButton(onPressed: null, child: Text('menu')),
          ),
        );

    Future<(Size, Size)> openMenu(WidgetTester tester) async {
      await tester.tap(find.text('menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final first = tester.getSize(find.byType(Material).last);
      await tester.pumpAndSettle();
      return (first, tester.getSize(find.byType(Material).last));
    }

    testWidgets('(a) réduit : déplié dès la première frame', (tester) async {
      await tester.pumpWidget(menu(reduced: true));
      final (first, settled) = await openMenu(tester);
      expect(first, settled);
    });

    testWidgets('(b) normal : dépliage d\'origine', (tester) async {
      await tester.pumpWidget(menu(reduced: false));
      final (first, settled) = await openMenu(tester);
      expect(first, isNot(settled));
    });
  });
}
