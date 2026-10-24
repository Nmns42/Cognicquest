import 'package:flutter/material.dart';

/// Couleurs de surlignage des fiches (texte et annotations PDF), par nom de
/// marqueur (`=={vert}…==`). En sombre, des teintes plus profondes gardent
/// le texte clair lisible.
abstract final class HighlightPalette {
  static const Map<String, Color> _light = {
    'jaune': Color(0xFFFFE58A),
    'vert': Color(0xFFC8E6C9),
    'bleu': Color(0xFFBBDEFB),
    'rose': Color(0xFFF8BBD0),
    'orange': Color(0xFFFFD3A6),
  };

  static const Map<String, Color> _dark = {
    'jaune': Color(0xFF6B5A16),
    'vert': Color(0xFF2E5A35),
    'bleu': Color(0xFF24486B),
    'rose': Color(0xFF6B2A45),
    'orange': Color(0xFF6E4320),
  };

  /// Couleur d'un surlignage ; jaune pour un nom inconnu.
  static Color of(String name, Brightness brightness) {
    final palette = brightness == Brightness.dark ? _dark : _light;
    return palette[name] ?? palette['jaune']!;
  }

  /// Teinte pleine (soulignés et barrés des annotations PDF), lisible sur
  /// la page blanche du document.
  static const Map<String, Color> _ink = {
    'jaune': Color(0xFFB8860B),
    'vert': Color(0xFF2E7D32),
    'bleu': Color(0xFF1565C0),
    'rose': Color(0xFFC2185B),
    'orange': Color(0xFFE65100),
  };

  static Color ink(String name) => _ink[name] ?? _ink['jaune']!;
}
