import 'package:cognicquest/core/motion/entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chorégraphie d'entrée : échelonnée, jouée une fois, absente en
/// animations réduites.
void main() {
  Future<void> pump(WidgetTester tester, Widget child, {bool reduced = false}) =>
      tester.pumpWidget(MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Directionality(textDirection: TextDirection.ltr, child: child),
      ));

  double opacityOf(WidgetTester tester, Type type) => tester
      .widget<FadeTransition>(find
          .descendant(of: find.byType(type), matching: find.byType(FadeTransition))
          .first)
      .opacity
      .value;

  testWidgets('panel settle : part de 0 et arrive à 1', (tester) async {
    await pump(tester, const PanelSettle(child: Text('carte')));
    expect(opacityOf(tester, PanelSettle), 0);

    await tester.pumpAndSettle();
    expect(opacityOf(tester, PanelSettle), 1);
  });

  testWidgets('échelonnement : le second élément part plus tard',
      (tester) async {
    await pump(
      tester,
      Column(children: [
        PanelSettle(delay: Entrance.delayFor(0), child: const Text('a')),
        PanelSettle(delay: Entrance.delayFor(3), child: const Text('b')),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 120));

    final first = tester
        .widgetList<FadeTransition>(find.byType(FadeTransition))
        .first
        .opacity
        .value;
    final second = tester
        .widgetList<FadeTransition>(find.byType(FadeTransition))
        .last
        .opacity
        .value;
    expect(first, greaterThan(second));
    await tester.pumpAndSettle();
  });

  testWidgets('animations réduites : état final immédiat, sans transition',
      (tester) async {
    await pump(
      tester,
      const Column(children: [
        PanelSettle(child: Text('carte')),
        TypeUnmask(child: Text('Titre')),
        ContentRise(child: Text('détail')),
      ]),
      reduced: true,
    );
    expect(find.byType(FadeTransition), findsNothing);
    expect(find.byType(SlideTransition), findsNothing);
    expect(find.text('Titre'), findsOneWidget);
  });

  test('au-delà de quelques éléments, le retard plafonne', () {
    expect(Entrance.delayFor(50), Entrance.delayFor(Entrance.maxStaggered));
  });
}
