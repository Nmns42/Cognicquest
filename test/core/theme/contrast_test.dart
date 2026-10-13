import 'dart:math';

import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contraste WCAG 2.x des deux palettes (refonte « zen », Phase 0).
///
/// Texte : 4,5:1 minimum (AA, texte normal). Éléments non textuels qu'il
/// faut percevoir (icônes inactives, poignées) : 3:1.
void main() {
  double luminance(Color c) {
    double channel(double v) =>
        v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  }

  double ratio(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
  }

  for (final variant in AppThemeVariant.values) {
    group('thème ${variant.label}', () {
      final cq = AppTheme.colorsFor(variant);
      final onAccent = AppTheme.onAccentFor(variant);
      final backgrounds = {'fond': cq.beige, 'carte': cq.cardColor};

      final text = {
        'texte': cq.textPrimary,
        'texte secondaire': cq.textMuted,
        'accent en texte': cq.vertDark,
        'erreur': cq.errorColor,
        'avertissement': cq.warning,
      };

      for (final MapEntry(key: name, value: color) in text.entries) {
        for (final MapEntry(key: bgName, value: bg) in backgrounds.entries) {
          test('$name sur $bgName ≥ 4,5:1', () {
            expect(ratio(color, bg), greaterThanOrEqualTo(4.5));
          });
        }
      }

      test('texte sur l\'accent plein ≥ 4,5:1', () {
        expect(ratio(onAccent, cq.vert), greaterThanOrEqualTo(4.5));
      });

      test('sur une teinte de sélection : texte ≥ 4,5:1, icône ≥ 3:1', () {
        final tint = Color.alphaBlend(
            cq.vert.withValues(alpha: Tints.selected), cq.beige);
        expect(ratio(cq.textPrimary, tint), greaterThanOrEqualTo(4.5));
        expect(ratio(cq.vertDark, tint), greaterThanOrEqualTo(3));
      });

      for (final MapEntry(key: bgName, value: bg) in backgrounds.entries) {
        test('indications (non textuelles) sur $bgName ≥ 3:1', () {
          expect(ratio(cq.textHint, bg), greaterThanOrEqualTo(3));
        });
      }

      test("boutons, puces et navigation utilisent la police de l'app", () {
        // Leurs styles ne fusionnent pas avec le texte par défaut : sans
        // police explicite, ils retombaient sur celle du système.
        final theme = AppTheme.build(variant);
        final styles = [
          theme.filledButtonTheme.style!.textStyle!.resolve({}),
          theme.outlinedButtonTheme.style!.textStyle!.resolve({}),
          theme.textButtonTheme.style!.textStyle!.resolve({}),
          theme.navigationBarTheme.labelTextStyle!.resolve({}),
          theme.chipTheme.labelStyle,
          theme.inputDecorationTheme.hintStyle,
          theme.snackBarTheme.contentTextStyle,
        ];
        for (final style in styles) {
          expect(style?.fontFamily, appFontFamily);
        }
      });

      test('le thème Material utilise bien ces couleurs', () {
        final theme = AppTheme.build(variant);
        expect(theme.colorScheme.onPrimary, onAccent);
        expect(theme.colorScheme.primary, cq.vert);
        expect(theme.textButtonTheme.style!.foregroundColor!.resolve({}),
            cq.vertDark);
      });
    });
  }
}
