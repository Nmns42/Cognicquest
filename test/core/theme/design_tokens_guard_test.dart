import 'dart:io';

import 'package:cognicquest/core/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Garde-fou de la refonte « zen » : les écrans n'écrivent plus de valeur
/// brute, ils utilisent les jetons de `lib/core/theme/tokens.dart`.
///
/// Les écrans pas encore repris (Phase 4) en contiennent encore : chaque
/// compteur est un **cliquet**. Il échoue si le nombre augmente ; quand un
/// écran est repris et que le nombre baisse, on abaisse le plafond ici pour
/// ne jamais revenir en arrière. Objectif de fin de refonte : tout à zéro.
void main() {
  final sources = {
    for (final file in Directory('lib').listSync(recursive: true))
      if (file is File &&
          file.path.endsWith('.dart') &&
          !file.path.endsWith('.g.dart') &&
          !file.path.replaceAll(r'\', '/').contains('lib/core/theme/'))
        file.path: file.readAsStringSync(),
  };

  int count(bool Function(String value) offGrid, RegExp pattern) {
    var total = 0;
    for (final source in sources.values) {
      for (final match in pattern.allMatches(source)) {
        if (offGrid(match.group(1)!)) total++;
      }
    }
    return total;
  }

  bool notIn(List<double> allowed, String raw) =>
      !allowed.contains(double.parse(raw));

  final ceilings = <String, (int Function(), int)>{
    // Tailles de texte hors des six de [TypeScale].
    'fontSize hors échelle': (
      () => count((v) => notIn(TypeScale.sizes, v),
          RegExp(r'fontSize:\s*([0-9]+(?:\.[0-9]+)?)\b(?!\s*\*)')),
      0,
    ),
    // Espacements hors de la grille de 4 de [Space].
    'espacement hors grille': (
      () => count(
          (v) => notIn(Space.scale, v),
          RegExp(r'(?:EdgeInsets\.\w+\([^)]*?|SizedBox\((?:height|width):\s*)'
              r'([0-9]+(?:\.[0-9]+)?)\b')),
      419,
    ),
    // Rayons hors de [Radii].
    'rayon hors échelle': (
      () => count((v) => notIn([Radii.sm, Radii.md, Radii.lg], v),
          RegExp(r'Radius\.circular\(([0-9]+(?:\.[0-9]+)?)\)')),
      0,
    ),
    // Couleurs écrites en dur au lieu des jetons du thème. Reste : la
    // couleur des pauses du Pomodoro, reprise avec son écran.
    'couleur en dur': (
      () => count((_) => true, RegExp(r'Color\((0x[0-9A-Fa-f]{8})\)')),
      1,
    ),
    'blanc ou noir en dur': (
      () => count((_) => true, RegExp(r'Colors\.(white|black)\b')),
      0,
    ),
  };

  for (final MapEntry(key: name, value: (measure, ceiling)) in ceilings.entries) {
    test('$name : pas plus de $ceiling', () {
      final current = measure();
      expect(current, lessThanOrEqualTo(ceiling),
          reason: '$name : $current (plafond $ceiling). Utiliser les jetons '
              'de lib/core/theme/tokens.dart.');
    });
  }
}
