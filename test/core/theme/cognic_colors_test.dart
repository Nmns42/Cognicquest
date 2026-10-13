import 'dart:io';

import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Égalité par valeur de [CognicColors] et, par ricochet, de [ThemeData].
void main() {
  const base = AppTheme.fallbackColors;
  const other = Color(0xFF123456);

  /// Une modification par champ. La garde plus bas vérifie que cette liste
  /// couvre tous les champs déclarés dans la classe.
  final changeOneField = <String, CognicColors Function(CognicColors)>{
    'vert': (c) => c.copyWith(vert: other),
    'vertDark': (c) => c.copyWith(vertDark: other),
    'beige': (c) => c.copyWith(beige: other),
    'beigeDark': (c) => c.copyWith(beigeDark: other),
    'textPrimary': (c) => c.copyWith(textPrimary: other),
    'textMuted': (c) => c.copyWith(textMuted: other),
    'textHint': (c) => c.copyWith(textHint: other),
    'errorColor': (c) => c.copyWith(errorColor: other),
    'onVertMuted': (c) => c.copyWith(onVertMuted: other),
    'warning': (c) => c.copyWith(warning: other),
    'cardColor': (c) => c.copyWith(cardColor: other),
  };

  test('deux CognicColors identiques sont égaux et de même hashCode', () {
    final copy = base.copyWith();
    expect(identical(copy, base), isFalse);
    expect(copy, base);
    expect(copy.hashCode, base.hashCode);
  });

  for (final MapEntry(key: field, value: change) in changeOneField.entries) {
    test('modifier « $field » rend les couleurs différentes', () {
      final changed = change(base);
      expect(changed, isNot(base), reason: field);
      // Le champ modifié est bien différent de la valeur de départ.
      expect(changed.copyWith(), changed);
    });
  }

  test('la liste des champs testés couvre toute la classe', () {
    final source = File('lib/core/theme/app_theme.dart').readAsStringSync();
    final start = source.indexOf('class CognicColors');
    final end = source.indexOf('\n}\n', start);
    final declared = RegExp(r'final Color (\w+);')
        .allMatches(source.substring(start, end))
        .map((m) => m.group(1))
        .toSet();
    expect(declared, hasLength(11));
    expect(changeOneField.keys.toSet(), declared);
  });

  test('lerp à 0 et à 1 rend des couleurs égales aux extrémités', () {
    final target = changeOneField['vert']!(base);
    expect(base.lerp(target, 0), base);
    expect(base.lerp(target, 1), target);
  });

  test('barre de navigation : mêmes styles qu\'avant pour chaque état', () {
    final theme = AppTheme.build(AppThemeVariant.light);
    final cq = theme.extension<CognicColors>()!;
    final nav = theme.navigationBarTheme;

    // Résolution de l'ancien `resolveWith` : sélectionné ou non, quels que
    // soient les autres états.
    for (final states in [
      <WidgetState>{},
      {WidgetState.hovered},
      {WidgetState.pressed, WidgetState.focused},
    ]) {
      final selected = {...states, WidgetState.selected};
      expect(nav.labelTextStyle!.resolve(selected),
          TextStyle(
              fontFamily: appFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cq.vertDark));
      expect(nav.labelTextStyle!.resolve(states),
          TextStyle(
              fontFamily: appFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cq.textMuted));
      expect(nav.iconTheme!.resolve(selected),
          IconThemeData(size: 24, color: cq.vertDark));
      expect(nav.iconTheme!.resolve(states),
          IconThemeData(size: 24, color: cq.textMuted));
    }
  });

  for (final variant in AppThemeVariant.values) {
    test('deux ThemeData construits pour « ${variant.name} » sont égaux', () {
      final first = AppTheme.build(variant);
      final second = AppTheme.build(variant);
      expect(identical(first, second), isFalse);
      expect(first, second);
    });
  }
}
