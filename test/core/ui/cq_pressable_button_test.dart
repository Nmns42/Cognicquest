import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/core/theme/tokens.dart';
import 'package:cognicquest/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Physique et accessibilité du bouton tactile en relief.
void main() {
  Future<void> pump(WidgetTester tester, Widget child,
          {bool reduceMotion = false}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: app!,
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Center(child: child),
            ),
          ),
        ),
      );

  /// Face du bouton : le conteneur animé qui porte la couleur et la lèvre.
  AnimatedContainer face(WidgetTester tester) =>
      tester.widget<AnimatedContainer>(find.descendant(
          of: find.byType(CqPressableButton),
          matching: find.byType(AnimatedContainer)));

  BoxDecoration decoration(WidgetTester tester) =>
      face(tester).decoration! as BoxDecoration;

  EdgeInsets margin(WidgetTester tester) => face(tester).margin! as EdgeInsets;

  testWidgets('au repos : lèvre de Press.depth sous la face', (tester) async {
    await pump(tester, CqPressableButton(label: 'Valider', onPressed: () {}));

    final cq = AppTheme.fallbackColors;
    expect(decoration(tester).color, cq.vert);
    expect(decoration(tester).boxShadow!.single.color, cq.vertLip);
    expect(decoration(tester).boxShadow!.single.offset,
        const Offset(0, Press.depth));
    expect(margin(tester), const EdgeInsets.only(bottom: Press.depth));
  });

  testWidgets("à l'appui la face descend, au relâcher l'action part",
      (tester) async {
    var taps = 0;
    await pump(
        tester, CqPressableButton(label: 'Valider', onPressed: () => taps++));
    final before = tester.getSize(find.byType(CqPressableButton));

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Valider')));
    await tester.pumpAndSettle();
    expect(margin(tester), const EdgeInsets.only(top: Press.depth));
    expect(decoration(tester).boxShadow!.single.offset, Offset.zero);
    expect(taps, 0, reason: "l'action part au relâcher, pas à l'appui");
    expect(tester.getSize(find.byType(CqPressableButton)), before,
        reason: 'la hauteur totale ne change pas');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(margin(tester), const EdgeInsets.only(bottom: Press.depth));
  });

  testWidgets('glisser hors du bouton annule l\'appui', (tester) async {
    var taps = 0;
    await pump(
        tester, CqPressableButton(label: 'Valider', onPressed: () => taps++));

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Valider')));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 300));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(taps, 0);
    expect(margin(tester), const EdgeInsets.only(bottom: Press.depth));
  });

  testWidgets('animations réduites : enfoncement instantané', (tester) async {
    await pump(tester, CqPressableButton(label: 'Valider', onPressed: () {}),
        reduceMotion: true);
    expect(face(tester).duration, Duration.zero);

    await pump(tester, CqPressableButton(label: 'Valider', onPressed: () {}));
    expect(face(tester).duration, CqMotion.press);
  });

  testWidgets('désactivé : plat, sans lèvre, sans action', (tester) async {
    await pump(tester,
        const CqPressableButton(label: 'Valider', onPressed: null));

    expect(decoration(tester).boxShadow, isEmpty);
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(margin(tester), const EdgeInsets.only(bottom: Press.depth));
  });

  testWidgets('en chargement : indicateur, aucune action', (tester) async {
    var taps = 0;
    await pump(
      tester,
      CqPressableButton(
          label: 'Envoyer', onPressed: () => taps++, isLoading: true),
    );

    await tester.tap(find.text('Envoyer'));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('teintes : face, lèvre et texte de chaque rôle', (tester) async {
    final cq = AppTheme.fallbackColors;
    final expected = {
      CqPressableTone.primary: (cq.vert, cq.vertLip),
      CqPressableTone.secondary: (cq.cardColor, cq.beigeDark),
      CqPressableTone.amber: (cq.ambre, cq.ambreLip),
    };
    for (final MapEntry(key: tone, value: (faceColor, lip))
        in expected.entries) {
      await pump(tester,
          CqPressableButton(label: 'Ok', onPressed: () {}, tone: tone));
      expect(decoration(tester).color, faceColor, reason: tone.name);
      expect(decoration(tester).boxShadow!.single.color, lip,
          reason: tone.name);
    }
  });

  testWidgets('cible tactile ≥ 48 dp et annoncé comme bouton',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, CqPressableButton(label: 'Valider', onPressed: () {}));

    expect(tester.getSize(find.byType(CqPressableButton)).height,
        greaterThanOrEqualTo(Sizes.touchTarget));
    expect(
      tester.getSemantics(find.byType(CqPressableButton)),
      matchesSemantics(
        label: 'Valider',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('clavier : Entrée déclenche l\'action', (tester) async {
    var taps = 0;
    await pump(
        tester, CqPressableButton(label: 'Valider', onPressed: () => taps++));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });
}
