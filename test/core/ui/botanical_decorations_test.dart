import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Motifs végétaux : rendus sans erreur dans les deux thèmes, muets pour
/// les lecteurs d'écran (sauf l'arbre, qui porte une information).
void main() {
  Future<void> pump(WidgetTester tester, AppThemeVariant variant,
          Widget child) =>
      tester.pumpWidget(MaterialApp(
        theme: AppTheme.build(variant),
        home: BotanicalWatermarkBackground(
          child: Center(child: SizedBox(width: 300, height: 200, child: child)),
        ),
      ));

  for (final variant in AppThemeVariant.values) {
    testWidgets('chaque motif se peint sans erreur — ${variant.label}',
        (tester) async {
      for (final child in [
        const HeroFoliageOverlay(),
        const LaurelStreakBadge(),
        const MindfulTreeIllustration(growth: 0),
        const MindfulTreeIllustration(growth: 1),
      ]) {
        await pump(tester, variant, child);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('les décors ne sont pas lus ; l\'arbre annonce sa croissance',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      AppThemeVariant.light,
      const Column(children: [
        SizedBox(height: 40, child: HeroFoliageOverlay()),
        LaurelStreakBadge(),
        Expanded(child: MindfulTreeIllustration(growth: 0.61)),
      ]),
    );

    expect(find.bySemanticsLabel('Arbre de détente, croissance 61 %'),
        findsOneWidget);
    // Feuillage et laurier sont décoratifs : exclus de l'accessibilité.
    for (final decor in [HeroFoliageOverlay, LaurelStreakBadge]) {
      expect(
        find.descendant(
            of: find.byType(decor), matching: find.byType(ExcludeSemantics)),
        findsWidgets,
        reason: '$decor',
      );
    }
    handle.dispose();
  });
}
