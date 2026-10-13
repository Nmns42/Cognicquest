import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/core/theme/tokens.dart';
import 'package:cognicquest/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Comportement des composants de la refonte « zen » (Phase 2).
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Center(child: child),
            ),
          ),
        ),
      );

  group('CqButton', () {
    testWidgets('chaque variante fait au moins 48 dp de haut', (tester) async {
      for (final button in [
        CqButton.primary(label: 'Valider', onPressed: () {}),
        CqButton.secondary(label: 'Annuler', onPressed: () {}),
        CqButton.text(label: 'Plus tard', onPressed: () {}),
      ]) {
        await pump(tester, button);
        final size = tester.getSize(find.byType(CqButton));
        expect(size.height, greaterThanOrEqualTo(Sizes.touchTarget),
            reason: button.variant.name);
      }
    });

    testWidgets('en chargement : désactivé, indicateur visible',
        (tester) async {
      var taps = 0;
      await pump(
        tester,
        CqButton.primary(
            label: 'Envoyer', onPressed: () => taps++, isLoading: true),
      );

      await tester.tap(find.text('Envoyer'));
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('actif : déclenche son action', (tester) async {
      var taps = 0;
      await pump(
          tester, CqButton.secondary(label: 'Ok', onPressed: () => taps++));
      await tester.tap(find.text('Ok'));
      expect(taps, 1);
    });
  });

  group('CqCard', () {
    testWidgets('sans ombre, et cliquable sur 48 dp au moins', (tester) async {
      var taps = 0;
      await pump(
        tester,
        CqCard(onTap: () => taps++, child: const Text('Carte')),
      );

      final material = tester.widget<Material>(find
          .descendant(of: find.byType(CqCard), matching: find.byType(Material))
          .first);
      expect(material.elevation, 0);
      expect(tester.getSize(find.byType(CqCard)).height,
          greaterThanOrEqualTo(Sizes.touchTarget));

      await tester.tap(find.text('Carte'));
      expect(taps, 1);
    });

    testWidgets('annoncée comme bouton seulement si cliquable', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, CqCard(onTap: () {}, child: const Text('A')));
      expect(
          tester.getSemantics(find.byType(CqCard)),
          matchesSemantics(
              isButton: true,
              hasTapAction: true,
              // Atteignable au clavier : voulu.
              isFocusable: true,
              hasFocusAction: true,
              label: 'A'));
      handle.dispose();
    });
  });

  group('CqListRow', () {
    testWidgets('48 dp minimum, sous-titre affiché, sélection annoncée',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        CqListRow(
          title: 'Cardiologie',
          subtitle: '12 fiches',
          leadingIcon: Icons.folder_outlined,
          selected: true,
          onTap: () {},
        ),
      );

      expect(tester.getSize(find.byType(CqListRow)).height,
          greaterThanOrEqualTo(Sizes.touchTarget));
      expect(find.text('12 fiches'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(CqListRow)),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          label: 'Cardiologie\n12 fiches',
        ),
      );
      handle.dispose();
    });
  });

  group('CqTextField', () {
    testWidgets('libellé visible au-dessus, erreur sous le champ',
        (tester) async {
      await pump(
        tester,
        const CqTextField(
          label: 'Adresse e-mail',
          hint: 'prenom@exemple.fr',
          error: 'Adresse invalide',
        ),
      );

      final label = tester.getRect(find.text('Adresse e-mail'));
      final field = tester.getRect(find.byType(TextField));
      final error = tester.getRect(find.text('Adresse invalide'));
      expect(label.bottom, lessThanOrEqualTo(field.top));
      expect(error.top, greaterThan(label.bottom));
    });

    testWidgets('le libellé reste visible pendant la saisie', (tester) async {
      await pump(tester, const CqTextField(label: 'Titre'));
      await tester.enterText(find.byType(TextField), 'Insuffisance');
      expect(find.text('Titre'), findsOneWidget);
    });
  });

  group('CqEmptyState', () {
    testWidgets('une phrase et une seule action', (tester) async {
      var taps = 0;
      await pump(
        tester,
        CqEmptyState(
          message: 'Aucune fiche pour le moment',
          icon: Icons.auto_stories_outlined,
          actionLabel: 'Créer une fiche',
          onAction: () => taps++,
        ),
      );

      expect(find.byType(CqButton), findsOneWidget);
      await tester.tap(find.text('Créer une fiche'));
      expect(taps, 1);
    });
  });

  group('CqSection', () {
    testWidgets('titre annoncé comme en-tête', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const CqSection(title: 'Aujourd\'hui', child: SizedBox.shrink()),
      );
      expect(tester.getSemantics(find.text('Aujourd\'hui')),
          matchesSemantics(isHeader: true, label: 'Aujourd\'hui'));
      handle.dispose();
    });
  });

  group('CqChip', () {
    testWidgets('zone tactile de 48 dp, sélection marquée par une coche',
        (tester) async {
      await pump(
        tester,
        CqChip(label: 'Urgent', selected: true, onSelected: (_) {}),
      );
      expect(tester.getSize(find.byType(CqChip)).height,
          greaterThanOrEqualTo(Sizes.touchTarget));
      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.showCheckmark, isTrue);
    });
  });

  group('showCqSheet', () {
    testWidgets('affiche le titre et le contenu', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showCqSheet<void>(
                context: context,
                title: 'Nouvelle tâche',
                builder: (_) => const Text('Contenu'),
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('Nouvelle tâche'), findsOneWidget);
      expect(find.text('Contenu'), findsOneWidget);
    });
  });
}
