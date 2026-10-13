import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde de l'inventaire « Animations réduites » : chaque animation de lib/
/// doit passer par `Motion`, sinon elle ignorerait le réglage.
///
/// Couvre tous les sites de l'inventaire (les tests de widgets n'en vérifient
/// que des exemples) et fait échouer l'ajout d'une animation non branchée.
void main() {
  final sources = {
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart')))
      file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
  };

  /// Sites où [call] apparaît sans [wiring] dans les [window] lignes
  /// suivantes (l'appel lui-même compris).
  List<String> unwired(RegExp call, String wiring, {int window = 8}) {
    final missing = <String>[];
    for (final MapEntry(key: path, value: source) in sources.entries) {
      final lines = source.split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (!call.hasMatch(lines[i])) continue;
        final scope = lines.skip(i).take(window).join('\n');
        if (!scope.contains(wiring)) missing.add('$path:${i + 1}');
      }
    }
    return missing;
  }

  final rules = <String, (RegExp, String)>{
    'AnimatedContainer': (RegExp(r'AnimatedContainer\('), 'Motion.duration('),
    // Refonte zen, Phase 3 : poignées au survol et bascule Kanban / Matrice.
    'AnimatedOpacity': (RegExp(r'AnimatedOpacity\('), 'Motion.duration('),
    'AnimatedSwitcher': (RegExp(r'AnimatedSwitcher\('), 'Motion.duration('),
    'TweenAnimationBuilder':
        (RegExp(r'TweenAnimationBuilder<'), 'Motion.duration('),
    'feuilles du bas': (RegExp(r'showModalBottomSheet<.*>\('),
        'sheetAnimationStyle: Motion.style('),
    'dialogues': (RegExp(r'showDialog<.*>\('), 'animationStyle: Motion.style('),
    'SnackBars':
        (RegExp(r'\.showSnackBar\('), 'snackBarAnimationStyle: Motion.style('),
    'menus contextuels':
        (RegExp(r'PopupMenuButton<'), 'popUpAnimationStyle: Motion.style('),
  };

  for (final MapEntry(key: name, value: (call, wiring)) in rules.entries) {
    test('$name : tous branchés sur Motion', () {
      // Garde-fou : le motif trouve bien des sites (sinon le test ne
      // vérifierait rien).
      expect(
        sources.values.any(call.hasMatch),
        isTrue,
        reason: 'aucun site trouvé pour $name',
      );
      expect(unwired(call, wiring), isEmpty);
    });
  }

  test('AnimatedSize : retiré en mode réduit', () {
    final files = [
      for (final MapEntry(key: path, value: source) in sources.entries)
        if (source.contains('AnimatedSize(')) path,
    ];
    expect(files, isNotEmpty);
    for (final path in files) {
      expect(sources[path], contains('Motion.reduced(context)'), reason: path);
    }
  });

  test('aucune animation explicite hors inventaire', () {
    // Un AnimationController ou une transition explicite devrait être ajouté
    // à l'inventaire et branché sur Motion avant d'arriver ici.
    final explicit = RegExp(
        r'AnimationController\(|Hero\(|'
        r'FadeTransition\(|SlideTransition\(|ScaleTransition\(');
    final found = [
      for (final MapEntry(key: path, value: source) in sources.entries)
        if (explicit.hasMatch(source)) path,
    ];
    expect(found, isEmpty);
  });
}
