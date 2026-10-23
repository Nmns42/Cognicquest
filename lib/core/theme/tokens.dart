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

/// Rayons d'angle : nets mais pas anguleux (références Craft, ElevenReader,
/// Saturn : 8 sur les champs, 12 sur les cartes et boutons).
abstract final class Radii {
  /// Champs, puces, petits contrôles.
  static const double sm = 8;

  /// Cartes et boutons.
  static const double md = 12;

  /// Feuilles du bas et dialogues.
  static const double lg = 16;

  /// Boutons tactiles en relief ([Press]) : rayon généreux, à la Duolingo.
  static const double button = 16;

  /// Cartes de la direction « Duolingo & végétal ».
  static const double card = 20;

  /// Toutes les valeurs autorisées, pour les garde-fous.
  static const List<double> scale = [sm, md, lg, button, card];
}

/// Relief des boutons tactiles (`CqPressableButton`).
abstract final class Press {
  /// Épaisseur de la lèvre sous la face, et course de l'enfoncement : assez
  /// pour lire le relief, assez peu pour garder la hauteur d'un contrôle.
  static const double depth = 4;
}

/// Échelle typographique : six tailles, pas une de plus.
///
/// Rendu « premium » : Plus Jakarta Sans seule, graisses 400 à 700 (600–700
/// pour les titres), interlettrage négatif proportionnel à la taille (en em).
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
  static const double titleHeight = 1.2;

  /// Interlettrage des titres : −0,02 em, la signature de la maquette.
  static const double titleEm = -0.02;

  /// Texte courant : à peine resserré.
  static const double bodyEm = -0.006;

  /// Libellés de boutons et d'onglets.
  static const double labelEm = -0.01;

  /// Petits textes : neutres, pour rester lisibles à 13 px.
  static const double captionEm = 0;

  /// Interlettrage en pixels pour une taille et un facteur em.
  static double tracking(double size, double em) => size * em;
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

/// « Chrome » des cartes : contour fin d'un pixel et ombre à peine posée,
/// à la manière de Craft, Linear ou Notion. La carte se détache par sa
/// surface et son filet, pas par du relief.
abstract final class Chrome {
  static const double borderWidth = Borders.thin;
  static const double shadowBlur = 3;
  static const double shadowOffsetY = 1;
  static const double shadowOpacity = 0.04;

  /// Élévation des feuilles du bas : assez pour les détacher, sans masse.
  static const double sheetElevation = 4;
}

/// Police unique de l'application, embarquée (cf. `pubspec.yaml`) :
/// Plus Jakarta Sans, graisses 400 à 700.
const String appFontFamily = 'PlusJakartaSans';

/// Durées et courbes des animations.
///
/// Repères (UI UX Pro Max, `motion.csv`) : retour de pression 150–200 ms,
/// changement d'état autour de 200–250 ms, page 200–300 ms. Pas de rebond :
/// le mouvement confirme une action, il ne décore pas. Les animations
/// réduites passent toujours par `Motion.duration`, qui ramène tout à zéro.
abstract final class CqMotion {
  /// Enfoncement d'un bouton en relief : sec, comme une touche physique.
  static const Duration press = Duration(milliseconds: 90);

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
