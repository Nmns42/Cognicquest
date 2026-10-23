import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Teintes des illustrations végétales (`lib/core/ui/botanical_decorations.dart`).
///
/// Purement décoratives : aucun texte n'est posé dessus, elles ne relèvent
/// donc pas des seuils de contraste. Rangées ici pour que les peintres ne
/// contiennent aucune couleur en dur.
@immutable
class BotanicalPalette {
  const BotanicalPalette({
    required this.leafDark,
    required this.leafMid,
    required this.leafLight,
    required this.bark,
    required this.bloom,
    required this.watermark,
  });

  /// Feuilles d'ombre (sous-bois).
  final Color leafDark;

  /// Feuilles principales (sauge).
  final Color leafMid;

  /// Feuilles éclairées, jeunes pousses.
  final Color leafLight;

  /// Tronc, tiges brunes, bourgeons.
  final Color bark;

  /// Petites fleurs.
  final Color bloom;

  /// Filigranes du fond : sable doré, à faible opacité.
  final Color watermark;

  static const BotanicalPalette _light = BotanicalPalette(
    leafDark: Color(0xFF2A523E),
    leafMid: Color(0xFF3D6A53),
    leafLight: Color(0xFF528265),
    bark: Color(0xFF7C4D25),
    bloom: Color(0xFFFFFDF9),
    watermark: Color(0xFFE2D3B3),
  );

  static const BotanicalPalette _dark = BotanicalPalette(
    leafDark: Color(0xFF2A523E),
    leafMid: Color(0xFF3D6A53),
    leafLight: Color(0xFF6E9E80),
    bark: Color(0xFFA9774A),
    bloom: Color(0xFFFFFDF9),
    watermark: Color(0xFF2E3D32),
  );

  static BotanicalPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  /// Variante explicite, pour les tests.
  static BotanicalPalette forVariant(AppThemeVariant variant) =>
      variant.isDark ? _dark : _light;
}
