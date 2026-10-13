import 'package:flutter/animation.dart';

/// Jetons de design de la refonte « zen » (Phase 0).
///
/// Une interface calme naît de peu de valeurs, appliquées partout : avant
/// cette phase, l'app comptait 21 tailles de texte, 31 espacements et 15
/// rayons différents. Les écrans ne doivent plus écrire de valeur brute ;
/// `test/core/theme/design_tokens_guard_test.dart` empêche d'en ajouter.

/// Espacements, sur une grille de 4.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Toutes les valeurs autorisées (0 compris), pour les garde-fous.
  static const List<double> scale = [0, xs, sm, md, lg, xl, xxl, xxxl];
}

/// Rayons d'angle : quasi droits.
///
/// Les grands arrondis sont la signature des interfaces génériques ; des
/// angles presque vifs donnent un dessin plus net, plus « sur mesure ».
abstract final class Radii {
  /// Champs, puces, petits contrôles.
  static const double sm = 2;

  /// Cartes et boutons.
  static const double md = 4;

  /// Feuilles du bas et dialogues : pas plus ronds que le reste.
  static const double lg = 4;
}

/// Échelle typographique : six tailles, pas une de plus.
///
/// Base relevée (15 au lieu de 14) pour que l'interface respire ; l'élégance
/// vient de l'interlettrage ([tracking…]) et de l'interligne, pas de la
/// graisse.
abstract final class TypeScale {
  /// Mentions, légendes, étiquettes de navigation. Jamais en dessous.
  static const double caption = 13;
  static const double body = 15;
  static const double bodyLarge = 17;
  static const double title = 21;
  static const double headline = 26;
  static const double display = 34;

  static const List<double> sizes = [
    caption,
    body,
    bodyLarge,
    title,
    headline,
    display,
  ];

  /// Interligne du texte courant : confortable à la lecture longue.
  static const double bodyHeight = 1.55;

  /// Interligne des titres : plus serré, ils tiennent sur peu de lignes.
  static const double titleHeight = 1.25;

  /// Titres : Atkinson est large, un interlettrage légèrement resserré
  /// donne des titres plus denses et plus nets.
  static const double trackingTitle = -0.3;

  /// Texte courant : à peine ouvert, il gagne en clarté.
  static const double trackingBody = 0.15;

  /// Petits textes (légendes, étiquettes) : plus ouverts pour rester
  /// lisibles à 13 px.
  static const double trackingCaption = 0.3;

  /// Libellés de boutons et d'onglets : ouverts, ils se lisent d'un coup
  /// d'œil sans être mis en gras.
  static const double trackingLabel = 0.4;
}

/// Dimensions des contrôles.
abstract final class Sizes {
  /// Cible tactile minimale (Android 48 dp ; iOS 44 pt, couvert).
  static const double touchTarget = 48;

  /// Hauteur des boutons et des champs principaux.
  static const double control = 52;

  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;

  /// Icône d'illustration d'un état vide : présente, jamais décorative à
  /// l'excès.
  static const double iconXl = 32;

  /// Épaisseur d'un indicateur de chargement dans un bouton.
  static const double spinnerStroke = 2;
}

/// Épaisseurs de trait.
abstract final class Borders {
  static const double thin = 1;

  /// Champ actif : plus marqué, pour un focus visible sans couleur seule.
  static const double focus = 2;
}

/// Opacités des teintes d'accent.
abstract final class Tints {
  /// Fond d'un élément sélectionné (onglet, ligne, puce, indicateur de
  /// navigation). Le texte posé dessus est en `textPrimary` : l'accent en
  /// texte n'y tiendrait pas 4,5:1 (cf. contrast_test).
  static const double selected = 0.35;
}

/// Police unique de l'application, embarquée (cf. `pubspec.yaml`).
const String appFontFamily = 'AtkinsonHyperlegibleNext';

/// Durées et courbes des animations.
///
/// Repères (UI UX Pro Max, `motion.csv`) : retour de pression 150–200 ms,
/// changement d'état autour de 200–250 ms, page 200–300 ms. Pas de rebond :
/// le mouvement confirme une action, il ne décore pas. Les animations
/// réduites passent toujours par `Motion.duration`, qui ramène tout à zéro.
abstract final class CqMotion {
  /// Pression, survol, bascule.
  static const Duration fast = Duration(milliseconds: 150);

  /// Changement d'état d'un composant (sélection, ouverture d'un panneau).
  static const Duration base = Duration(milliseconds: 220);

  /// Changement de page, apparition d'un bloc.
  static const Duration slow = Duration(milliseconds: 300);

  /// Ce qui entre à l'écran : démarre vite, se pose en douceur.
  static const Curve enter = Curves.easeOutCubic;

  /// Ce qui change sur place.
  static const Curve standard = Curves.easeInOutCubic;

  /// Ce qui sort : plus bref que l'entrée.
  static const Curve exit = Curves.easeInCubic;
}
