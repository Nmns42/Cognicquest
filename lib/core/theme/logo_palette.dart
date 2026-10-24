import 'package:flutter/painting.dart';

import 'app_theme.dart';

/// Couleurs du logo « Arbre-Neurone » : houppier (réseau), branches et
/// terminaisons, tronc et racines.
class LogoPalette {
  const LogoPalette({
    required this.canopy,
    required this.branches,
    required this.roots,
  });

  /// D'après le thème courant : vert forêt en clair, vert clair en sombre
  /// (le vert forêt disparaîtrait sur le fond #121A14).
  factory LogoPalette.of(CognicColors cq) =>
      LogoPalette(canopy: cq.vertSauge, branches: cq.vert, roots: cq.terre);

  final Color canopy;
  final Color branches;
  final Color roots;

  /// Sur fond parchemin (#FAF8F5) : icônes, favicon.
  static const LogoPalette onLight = LogoPalette(
    canopy: Color(0xFF3D6A53),
    branches: Color(0xFF083B32),
    roots: Color(0xFF7C4D25),
  );

  /// Variante claire, sur fond vert forêt (#083B32) : icônes maskables,
  /// écran de lancement.
  static const LogoPalette onForest = LogoPalette(
    canopy: Color(0xFF7FB99A),
    branches: Color(0xFFFAF8F5),
    roots: Color(0xFFE0A26B),
  );

  /// Fonds des icônes générées.
  static const Color lightBackground = Color(0xFFFAF8F5);
  static const Color forestBackground = Color(0xFF083B32);
}
