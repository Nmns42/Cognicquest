import 'dart:math';

import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contraste WCAG 2.x des deux palettes (direction « Duolingo & végétal »).
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
      final backgrounds = {
        'fond': cq.beige,
        'carte': cq.cardColor,
        'sauge': cq.sauge,
      };

      final text = {
        'texte': cq.textPrimary,
        'texte secondaire': cq.textMuted,
        'accent en texte': cq.vertDark,
        'erreur': cq.errorColor,
        'avertissement': cq.warning,
        'terre': cq.terre,
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

      test("texte secondaire sur l'accent ≥ 4,5:1", () {
        expect(ratio(cq.onVertMuted, cq.vert), greaterThanOrEqualTo(4.5));
      });

      test("texte sur l'olive (navigation active) ≥ 4,5:1", () {
        expect(ratio(onAccent, cq.olive), greaterThanOrEqualTo(4.5));
      });

      // L'olive (navigation, bouton d'ajout) se pose sur le fond ou la carte,
      // jamais sur la sauge.
      for (final MapEntry(key: bgName, value: bg) in {
        'fond': cq.beige,
        'carte': cq.cardColor,
      }.entries) {
        test('olive sur $bgName ≥ 3:1 (indicateur visible)', () {
          expect(ratio(cq.olive, bg), greaterThanOrEqualTo(3));
        });
      }

      test('cases des habitudes : texte sur la face « faite » et sur le sable '
          '≥ 4,5:1', () {
        expect(ratio(onAccent, cq.vertLip), greaterThanOrEqualTo(4.5));
        expect(ratio(cq.textMuted, cq.beigeDark), greaterThanOrEqualTo(4.5));
      });

      test("pastilles de série et coches : fond de l'app sur la sauge et "
          "l'écorce ≥ 4,5:1", () {
        expect(ratio(cq.beige, cq.vertSauge), greaterThanOrEqualTo(4.5));
        expect(ratio(cq.beige, cq.terre), greaterThanOrEqualTo(4.5));
      });

      test('bande sombre de la bannière : chiffres et légendes ≥ 4,5:1', () {
        expect(ratio(onAccent, cq.vertLip), greaterThanOrEqualTo(4.5));
        expect(ratio(cq.onVertMuted, cq.vertLip), greaterThanOrEqualTo(4.5));
      });

      test("texte sur l'ambre ≥ 4,5:1", () {
        expect(ratio(cq.onAmbre, cq.ambre), greaterThanOrEqualTo(4.5));
      });

      // Un bouton en relief se délimite par sa face ou par sa lèvre : la plus
      // contrastée des deux doit tenir 3:1 sur le fond (WCAG 1.4.11).
      for (final MapEntry(key: bgName, value: bg) in {
        'fond': cq.beige,
        'carte': cq.cardColor,
      }.entries) {
        test('contour des boutons en relief sur $bgName ≥ 3:1', () {
          expect(max(ratio(cq.vert, bg), ratio(cq.vertLip, bg)),
              greaterThanOrEqualTo(3));
        });
      }

      test("sur l'accent et chaque teinte du dégradé : texte ≥ 4,5:1", () {
        final gradient = AppTheme.accentGradientFor(variant);
        for (final stop in [cq.vert, ...gradient.colors]) {
          expect(ratio(onAccent, stop), greaterThanOrEqualTo(4.5));
        }
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
