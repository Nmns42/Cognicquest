import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:cognicquest/core/navigation/app_destinations.dart';
import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/features/settings/data/ambient_sound_engine.dart';
import 'package:cognicquest/features/settings/domain/user_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDestinations', () {
    test('expose cinq destinations principales et le reste en secondaire', () {
      expect(AppDestinations.primary, hasLength(5));
      expect(AppDestinations.secondary, isNotEmpty);
      expect(
        AppDestinations.primary.length + AppDestinations.secondary.length,
        AppDestinations.all.length,
      );
    });

    test('toutes les sections du projet sont atteignables', () {
      // Avant le Lot 9, graphe, journal et planification n'avaient aucune
      // entrée de navigation : ils empruntaient l'onglet d'une autre section.
      final routes = AppDestinations.all.map((d) => d.route).toSet();
      expect(routes, containsAll(['/graph', '/journal', '/planning', '/settings']));
    });

    test('retient la route la plus longue qui préfixe l\'emplacement', () {
      // `/planning/gantt` doit désigner « Planification », pas une autre
      // destination dont la route serait aussi un préfixe.
      expect(AppDestinations.matching('/planning/gantt')?.route, '/planning');
      expect(AppDestinations.matching('/journal/why')?.route, '/journal');
      expect(AppDestinations.matching('/review/session')?.route, '/review');
      expect(AppDestinations.matching('/notes/abc-123')?.route, '/notes');
    });

    test('rend null pour un emplacement inconnu', () {
      expect(AppDestinations.matching('/login'), isNull);
      expect(AppDestinations.primaryIndexOf('/login'), isNull);
    });

    test('n\'attribue pas d\'onglet principal à une section secondaire', () {
      // La barre du bas ne doit pas prétendre qu'on est dans « Accueil »
      // alors qu'on consulte le graphe.
      expect(AppDestinations.primaryIndexOf('/graph'), isNull);
      expect(AppDestinations.primaryIndexOf('/journal'), isNull);
      expect(AppDestinations.primaryIndexOf('/home'), 0);
    });

    test('indexOf couvre toutes les destinations du rail', () {
      for (final destination in AppDestinations.all) {
        expect(AppDestinations.indexOf(destination.route), isNotNull);
      }
    });
  });

  group('Breakpoints', () {
    test('choisit la mise en page selon la largeur', () {
      expect(Breakpoints.layoutFor(380), NavigationLayout.bottomBar);
      expect(Breakpoints.layoutFor(639), NavigationLayout.bottomBar);
      expect(Breakpoints.layoutFor(640), NavigationLayout.rail);
      expect(Breakpoints.layoutFor(1000), NavigationLayout.rail);
      expect(Breakpoints.layoutFor(1240), NavigationLayout.extendedRail);
      expect(Breakpoints.layoutFor(1920), NavigationLayout.extendedRail);
    });
  });

  group('AppTheme — variantes', () {
    test('deux variantes seulement : clair et sombre', () {
      expect(AppThemeVariant.values,
          [AppThemeVariant.light, AppThemeVariant.dark]);
      expect(AppTheme.colorsFor(AppThemeVariant.light).beige,
          isNot(AppTheme.colorsFor(AppThemeVariant.dark).beige));
    });

    test('le thème sombre inverse réellement le rapport fond / texte', () {
      final light = AppTheme.colorsFor(AppThemeVariant.light);
      final dark = AppTheme.colorsFor(AppThemeVariant.dark);

      double luminance(int argb) => ((argb & 0xFF) +
              ((argb >> 8) & 0xFF) +
              ((argb >> 16) & 0xFF))
          .toDouble();

      // C'est précisément ce que l'ancien `textTheme` en dur empêchait :
      // le texte sombre restait sombre sur un fond sombre.
      expect(luminance(light.beige.toARGB32()),
          greaterThan(luminance(light.textPrimary.toARGB32())));
      expect(luminance(dark.beige.toARGB32()),
          lessThan(luminance(dark.textPrimary.toARGB32())));
    });

    test('le textTheme suit la palette de la variante', () {
      for (final variant in AppThemeVariant.values) {
        final theme = AppTheme.build(variant);
        final palette = AppTheme.colorsFor(variant);
        expect(theme.textTheme.bodyMedium?.color, palette.textPrimary);
        expect(theme.textTheme.bodySmall?.color, palette.textMuted);
      }
    });

    test('l\'extension de couleurs est attachée au thème', () {
      final theme = AppTheme.build(AppThemeVariant.dark);
      final extension = theme.extension<CognicColors>();

      expect(extension, isNotNull);
      expect(extension!.vert, AppTheme.colorsFor(AppThemeVariant.dark).vert);
    });

    test('la luminosité est cohérente avec la variante', () {
      expect(AppTheme.build(AppThemeVariant.dark).brightness, Brightness.dark);
      expect(AppTheme.build(AppThemeVariant.light).brightness, Brightness.light);
    });

    test('retombe sur le clair pour une valeur inconnue ou ancienne', () {
      expect(AppThemeVariant.fromValue(null), AppThemeVariant.light);
      expect(AppThemeVariant.fromValue('néon'), AppThemeVariant.light);
      // Variantes supprimées par la refonte : réglages déjà enregistrés.
      for (final old in ['beige', 'sage', 'brown']) {
        expect(AppThemeVariant.fromValue(old), AppThemeVariant.light);
      }
      expect(AppThemeVariant.fromValue('dark'), AppThemeVariant.dark);
    });
  });

  group('UserSettings — sérialisation', () {
    test('fait l\'aller-retour JSON', () {
      const settings = UserSettings(
        themeVariant: AppThemeVariant.dark,
        textScale: TextScalePreset.large,
        ambientSound: AmbientSound.pinkNoise,
        ambientVolume: 0.3,
        keyboardShortcutsEnabled: false,
        reduceMotion: true,
      );

      final restored = UserSettings.fromJson(settings.toJson());

      expect(restored.themeVariant, AppThemeVariant.dark);
      expect(restored.textScale, TextScalePreset.large);
      expect(restored.ambientSound, AmbientSound.pinkNoise);
      expect(restored.ambientVolume, 0.3);
      expect(restored.keyboardShortcutsEnabled, isFalse);
      expect(restored.reduceMotion, isTrue);
    });

    test('retombe sur les valeurs par défaut pour un JSON vide', () {
      final restored = UserSettings.fromJson(const {});

      expect(restored.themeVariant, AppThemeVariant.light);
      expect(restored.textScale, TextScalePreset.standard);
      expect(restored.ambientSound, AmbientSound.none);
      expect(restored.keyboardShortcutsEnabled, isTrue);
    });

    test('ignore les clés inconnues sans échouer', () {
      final restored = UserSettings.fromJson(const {
        'theme': 'néon',
        'reglage_inexistant': 42,
      });
      expect(restored.themeVariant, AppThemeVariant.light);
    });

    test('borne le volume entre 0 et 1', () {
      expect(UserSettings.fromJson(const {'ambient_volume': 5}).ambientVolume, 1);
      expect(
          UserSettings.fromJson(const {'ambient_volume': -3}).ambientVolume, 0);
    });

    test('conserve les routines personnalisées', () {
      final settings = UserSettings.defaults.copyWith(
        morningRoutine: Routine.morningDefault.copyWith(
          isEnabled: true,
          hour: 6,
          minute: 30,
          steps: ['Boire un verre d\'eau'],
        ),
      );

      final restored = UserSettings.fromJson(settings.toJson());

      expect(restored.morningRoutine.isEnabled, isTrue);
      expect(restored.morningRoutine.timeLabel, '06:30');
      expect(restored.morningRoutine.steps, ['Boire un verre d\'eau']);
    });

    test('une routine mal formée retombe sur son modèle', () {
      final restored = UserSettings.fromJson(const {
        'morning_routine': {'hour': 'midi'},
      });

      expect(restored.morningRoutine.hour, Routine.morningDefault.hour);
      expect(restored.morningRoutine.steps, Routine.morningDefault.steps);
    });
  });

  group('TextScalePreset', () {
    test('les échelles sont croissantes', () {
      final scales =
          TextScalePreset.values.map((p) => p.scale).toList();
      for (var i = 1; i < scales.length; i++) {
        expect(scales[i], greaterThan(scales[i - 1]));
      }
    });

    test('« standard » ne change rien', () {
      expect(TextScalePreset.standard.scale, 1.0);
    });
  });

  group('AmbientSound', () {
    test('sépare les ambiances synthétisables de celles qui exigent un asset',
        () {
      expect(AmbientSound.available, isNotEmpty);
      expect(AmbientSound.available.every((s) => s.isSynthesised), isTrue);
      expect(AmbientSound.needingAssets.every((s) => s.assetPath != null),
          isTrue);
    });

    test('couvre les ambiances listées par le cahier des charges', () {
      final labels = AmbientSound.values.map((s) => s.label).toList();
      expect(labels, containsAll(['Silence', 'Bruit rose', '440 Hz', 'Pluie']));
    });
  });

  group('NoiseGenerator', () {
    test('ne génère rien pour le silence ou un son à asset', () {
      expect(NoiseGenerator.build(AmbientSound.none), isNull);
      expect(NoiseGenerator.build(AmbientSound.rain), isNull);
    });

    test('produit un WAV valide pour chaque ambiance synthétisée', () {
      for (final sound in AmbientSound.available) {
        if (sound.isSilent) continue;
        final data = NoiseGenerator.build(sound)!;

        // En-tête RIFF/WAVE.
        expect(String.fromCharCodes(data.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(data.sublist(8, 12)), 'WAVE');

        const expectedSamples =
            NoiseGenerator.sampleRate * NoiseGenerator.loopSeconds;
        expect(data.length, 44 + expectedSamples * 2);
      }
    });

    test('le signal n\'est pas muet', () {
      final data = NoiseGenerator.build(AmbientSound.pinkNoise)!;
      final view = ByteData.sublistView(data, 44);

      var peak = 0;
      for (var i = 0; i < 2000; i++) {
        final value = view.getInt16(i * 2, Endian.little).abs();
        if (value > peak) peak = value;
      }
      expect(peak, greaterThan(100));
    });

    test('démarre et finit par un fondu, pour éviter le clic de bouclage', () {
      final data = NoiseGenerator.build(AmbientSound.whiteNoise)!;
      final view = ByteData.sublistView(data, 44);
      final sampleCount = (data.length - 44) ~/ 2;

      expect(view.getInt16(0, Endian.little).abs(), lessThan(50));
      expect(view.getInt16((sampleCount - 1) * 2, Endian.little).abs(),
          lessThan(50));
    });
  });
}
