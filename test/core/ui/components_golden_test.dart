// Étiquette `golden` : la CI (Linux) exclut ce fichier, cf. dart_test.yaml.
@Tags(['golden'])
library;

import 'dart:io';

import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/core/theme/tokens.dart';
import 'package:cognicquest/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rendu visuel des composants (golden tests), en clair et en sombre.
///
/// Les vraies polices sont chargées (Plus Jakarta Sans, icônes
/// Material) : sans elles, le moteur de test dessine des rectangles et
/// l'image ne montrerait rien de la typographie.
///
/// Mettre à jour les images après un changement voulu :
/// `flutter test --update-goldens test/core/ui/components_golden_test.dart`
/// Le rendu du texte varie selon le système : les images de référence sont
/// générées sous Windows, où ce test doit être lancé.
void main() {
  setUpAll(() async {
    Future<void> load(String family, List<String> paths) async {
      final loader = FontLoader(family);
      for (final path in paths) {
        final file = File(path);
        if (!file.existsSync()) return;
        loader.addFont(
            Future.value(ByteData.sublistView(file.readAsBytesSync())));
      }
      await loader.load();
    }

    const dir = 'assets/fonts/plus_jakarta_sans';
    await load(appFontFamily, [
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        '$dir/PlusJakartaSans-$weight.ttf',
    ]);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      await load('MaterialIcons', [
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
            'MaterialIcons-Regular.otf',
      ]);
    }
  });

  for (final variant in AppThemeVariant.values) {
    testWidgets('galerie des composants — ${variant.label}', (tester) async {
      tester.view.physicalSize = const Size(420, 1320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(variant),
        // Fond réel de l'app : beige et feuilles au trait.
        builder: (context, child) => ZenBackground(child: child!),
        home: const Scaffold(body: _Gallery()),
      ));
      // Pas de pumpAndSettle : l'indicateur de chargement tourne sans fin.
      // On fige l'image à un instant fixe, identique à chaque exécution.
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(ZenBackground),
        matchesGoldenFile('goldens/components_${variant.value}.png'),
      );
    });
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Space.xl),
      children: [
        CqSection(
          title: 'Fiches récentes',
          actionLabel: 'Tout voir',
          onAction: () {},
          child: CqCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                CqListRow(
                  title: 'Insuffisance cardiaque',
                  subtitle: 'Cardiologie · modifiée hier',
                  leadingIcon: Icons.auto_stories_outlined,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                CqListRow(
                  title: 'Cycle de Krebs',
                  subtitle: 'Biochimie',
                  leadingIcon: Icons.auto_stories_outlined,
                  selected: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.xl),
        CqButton.primary(
            label: 'Commencer la session',
            icon: Icons.play_arrow,
            onPressed: () {}),
        const SizedBox(height: Space.sm),
        CqButton.secondary(label: 'Plus tard', onPressed: () {}),
        const SizedBox(height: Space.sm),
        const CqButton.primary(
            label: 'Envoi', onPressed: null, isLoading: true),
        const SizedBox(height: Space.sm),
        CqSegmentedControl<int>(
          options: const {0: 'Kanban', 1: 'Matrice'},
          selected: 0,
          onChanged: (_) {},
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            CqButton.text(label: 'Annuler', onPressed: () {}),
            const CqButton.text(label: 'Désactivé', onPressed: null),
          ],
        ),
        const SizedBox(height: Space.xl),
        const CqTextField(
          label: 'Titre de la fiche',
          hint: 'Ex. : insuffisance cardiaque',
          helper: 'Un titre court se retrouve plus vite.',
        ),
        const SizedBox(height: Space.lg),
        const CqTextField(
          label: 'Adresse e-mail',
          hint: 'prenom@exemple.fr',
          error: 'Cette adresse ne semble pas valide.',
        ),
        const SizedBox(height: Space.lg),
        Wrap(
          spacing: Space.sm,
          children: [
            CqChip(label: 'Urgent', selected: true, onSelected: (_) {}),
            CqChip(label: 'Cette semaine', selected: false, onSelected: (_) {}),
          ],
        ),
        CqCard(
          tone: CqCardTone.muted,
          child: CqEmptyState(
            icon: Icons.style_outlined,
            message: 'Rien à revoir aujourd\'hui.',
            actionLabel: 'Créer une carte',
            onAction: () {},
          ),
        ),
      ],
    );
  }
}
