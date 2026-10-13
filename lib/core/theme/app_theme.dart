import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Variantes de thème : clair et sombre uniquement (refonte « zen »).
///
/// Les anciennes variantes beige, vert sauge et brun sont fondues dans le
/// thème clair : un choix de moins, et deux palettes seulement à tenir au
/// contraste WCAG (4,5:1), vérifié par `test/core/theme/contrast_test.dart`.
enum AppThemeVariant {
  light('light', 'Clair', 'Beige et vert, pour la journée'),
  dark('dark', 'Sombre', 'Pour travailler le soir');

  const AppThemeVariant(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  bool get isDark => this == AppThemeVariant.dark;

  /// `beige`, `sage` et `brown`, enregistrés avant la refonte, deviennent
  /// le thème clair ; toute valeur inconnue aussi.
  static AppThemeVariant fromValue(String? value) =>
      value == dark.value ? dark : light;
}

/// Jetons de marque qui n'ont pas d'équivalent dans [ColorScheme].
///
/// C'est ce qui remplace les anciennes constantes statiques de `AppTheme` :
/// elles étaient figées sur la palette claire, ce qui rendait tout thème
/// sombre impossible. Ici, chaque variante fournit ses propres valeurs et
/// l'accès se fait par le contexte.
@immutable
class CognicColors extends ThemeExtension<CognicColors> {
  const CognicColors({
    required this.vert,
    required this.vertDark,
    required this.beige,
    required this.beigeDark,
    required this.textPrimary,
    required this.textMuted,
    required this.textHint,
    required this.errorColor,
    required this.onVertMuted,
    required this.warning,
    required this.cardColor,
  });

  /// Accent principal de la marque.
  final Color vert;

  /// Variante foncée de l'accent : c'est elle qui tient le contraste sur fond
  /// clair (le vert clair tombe sous 3:1), donc celle qu'utilisent les
  /// graphiques et les textes accentués.
  final Color vertDark;

  /// Fond général.
  final Color beige;

  /// Bordures, séparateurs et pistes de graphiques.
  final Color beigeDark;

  final Color textPrimary;
  final Color textMuted;
  final Color textHint;
  final Color errorColor;

  /// Texte secondaire posé sur l'accent.
  final Color onVertMuted;

  /// Avertissement, distinct de l'erreur.
  final Color warning;

  final Color cardColor;

  @override
  CognicColors copyWith({
    Color? vert,
    Color? vertDark,
    Color? beige,
    Color? beigeDark,
    Color? textPrimary,
    Color? textMuted,
    Color? textHint,
    Color? errorColor,
    Color? onVertMuted,
    Color? warning,
    Color? cardColor,
  }) {
    return CognicColors(
      vert: vert ?? this.vert,
      vertDark: vertDark ?? this.vertDark,
      beige: beige ?? this.beige,
      beigeDark: beigeDark ?? this.beigeDark,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textHint: textHint ?? this.textHint,
      errorColor: errorColor ?? this.errorColor,
      onVertMuted: onVertMuted ?? this.onVertMuted,
      warning: warning ?? this.warning,
      cardColor: cardColor ?? this.cardColor,
    );
  }

  @override
  CognicColors lerp(ThemeExtension<CognicColors>? other, double t) {
    if (other is! CognicColors) return this;
    return CognicColors(
      vert: Color.lerp(vert, other.vert, t)!,
      vertDark: Color.lerp(vertDark, other.vertDark, t)!,
      beige: Color.lerp(beige, other.beige, t)!,
      beigeDark: Color.lerp(beigeDark, other.beigeDark, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      onVertMuted: Color.lerp(onVertMuted, other.onVertMuted, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
    );
  }

  // Égalité par valeur : `ThemeData.==` compare ses extensions. Sans ces deux
  // redéfinitions, la comparaison se faisait par identité, et deux thèmes
  // construits séparément pour la même variante n'étaient jamais égaux —
  // chaque reconstruction du thème notifiait tous les widgets qui le lisent.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CognicColors &&
          other.vert == vert &&
          other.vertDark == vertDark &&
          other.beige == beige &&
          other.beigeDark == beigeDark &&
          other.textPrimary == textPrimary &&
          other.textMuted == textMuted &&
          other.textHint == textHint &&
          other.errorColor == errorColor &&
          other.onVertMuted == onVertMuted &&
          other.warning == warning &&
          other.cardColor == cardColor;

  @override
  int get hashCode => Object.hash(
        vert,
        vertDark,
        beige,
        beigeDark,
        textPrimary,
        textMuted,
        textHint,
        errorColor,
        onVertMuted,
        warning,
        cardColor,
      );
}

/// Accès court aux jetons de marque : `context.cq.textMuted`.
extension CognicColorsX on BuildContext {
  CognicColors get cq =>
      Theme.of(this).extension<CognicColors>() ?? AppTheme.fallbackColors;

  /// Texte et icônes posés sur l'accent plein : blanc en clair, sombre en
  /// sombre (le blanc sur le vert clair du thème sombre est illisible).
  Color get onAccent => Theme.of(this).colorScheme.onPrimary;
}

class AppTheme {
  AppTheme._();

  /// Rayon des cartes et boutons ; alias de [Radii.md] pour les écrans pas
  /// encore repris (Phase 4).
  static const double radius = Radii.md;

  /// Palette utilisée si l'extension est absente (tests de widget isolés).
  static const CognicColors fallbackColors = _lightColors;

  // ── Palettes ───────────────────────────────────────────────────────────
  //
  // Fond gris très clair (#F0F0F0), texte #141414, cartes blanches.
  // Accent : un vert profond de forêt (pin #2F5D46), riche et chaleureux,
  // en dégradé (#3D6E55 → #2F5D46 → #23493A) sous un texte blanc. Contrastes
  // mesurés (WCAG, cf. contrast_test) : texte 16:1, vert en texte 7,8:1,
  // texte blanc sur chaque teinte du dégradé ≥ 5,9:1.

  static const CognicColors _lightColors = CognicColors(
    vert: Color(0xFF2F5D46),
    vertDark: Color(0xFF27523E),
    beige: Color(0xFFF0F0F0),
    beigeDark: Color(0xFFE3E3E3),
    textPrimary: Color(0xFF141414),
    textMuted: Color(0xFF5E5E5E),
    textHint: Color(0xFF8A8A8A),
    errorColor: Color(0xFFB8382B),
    onVertMuted: Color(0xFFD6E6DA),
    warning: Color(0xFF8A5E1F),
    cardColor: Color(0xFFFFFFFF),
  );

  /// Palette sombre : même logique, valeurs recalculées pour un fond sombre
  /// (pas une inversion automatique).
  static const CognicColors _darkColors = CognicColors(
    vert: Color(0xFF86B99A),
    vertDark: Color(0xFF9BC9AC),
    beige: Color(0xFF151617),
    beigeDark: Color(0xFF2C2E30),
    textPrimary: Color(0xFFECECEC),
    textMuted: Color(0xFFA3A3A3),
    textHint: Color(0xFF6E6E6E),
    errorColor: Color(0xFFEF8A7E),
    onVertMuted: Color(0xFF1E2A17),
    warning: Color(0xFFE2B064),
    cardColor: Color(0xFF1E2022),
  );

  static CognicColors colorsFor(AppThemeVariant variant) => switch (variant) {
        AppThemeVariant.light => _lightColors,
        AppThemeVariant.dark => _darkColors,
      };

  /// Texte et icônes posés sur l'accent (boutons, pastilles, dégradés).
  static Color onAccentFor(AppThemeVariant variant) =>
      variant.isDark ? const Color(0xFF101511) : Colors.white;

  /// Dégradé d'accentuation de la maquette, orienté à 145°.
  static LinearGradient accentGradientFor(AppThemeVariant variant) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        // 145° CSS ≈ diagonale (135°) + 10°.
        transform: const GradientRotation(10 * math.pi / 180),
        colors: variant.isDark
            ? const [Color(0xFF9BC9AC), Color(0xFF86B99A), Color(0xFF6FA585)]
            : const [Color(0xFF3D6E55), Color(0xFF2F5D46), Color(0xFF23493A)],
        stops: const [0, 0.47, 1],
      );

  /// Thème clair, conservé pour les tests et les écrans hors préférences
  /// (démarrage, erreur fatale).
  static final ThemeData light = build(AppThemeVariant.light);

  // ── Construction ───────────────────────────────────────────────────────

  static ThemeData build(AppThemeVariant variant) {
    final cq = colorsFor(variant);
    final brightness = variant.isDark ? Brightness.dark : Brightness.light;
    final onAccent = onAccentFor(variant);
    final chrome = CardChrome.of(variant);

    final scheme = ColorScheme.fromSeed(
      seedColor: cq.vert,
      brightness: brightness,
      primary: cq.vert,
      onPrimary: onAccent,
      surface: cq.beige,
      onSurface: cq.textPrimary,
      onSurfaceVariant: cq.textMuted,
      outline: cq.beigeDark,
      outlineVariant: cq.beigeDark,
      error: cq.errorColor,
    );

    final field = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.sm),
      borderSide: BorderSide(color: cq.beigeDark),
    );
    final control = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.md),
    );
    final buttonLabel = _style(TypeScale.body, FontWeight.w600,
        TypeScale.labelEm, null);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: appFontFamily,
      colorScheme: scheme,
      // Transparent : le fond (gris et motif de feuilles) est peint une
      // seule fois sous toute l'app, par `ZenBackground`.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: cq.beige,
      // Fondu enchaîné discret entre les écrans, sur toutes les plateformes.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const FadeForwardsPageTransitionsBuilder(),
        },
      ),
      primaryColor: cq.vert,
      cardColor: cq.cardColor,
      extensions: [cq],

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: cq.textPrimary),
        titleTextStyle: _style(
            TypeScale.title, FontWeight.w700, TypeScale.titleEm, cq.textPrimary,
            height: TypeScale.titleHeight),
      ),

      // Cartes : filet intérieur clair et ombre très diffuse (cf. [Chrome]).
      cardTheme: CardThemeData(
        color: cq.cardColor,
        elevation: 1,
        shadowColor: chrome.shadow.color,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: chrome.border,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cq.cardColor,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Space.lg, vertical: Space.md),
        // Le texte indicatif est lu : contraste du texte secondaire.
        hintStyle: _style(TypeScale.body, FontWeight.w400, TypeScale.bodyEm,
            cq.textMuted),
        labelStyle: _style(TypeScale.body, FontWeight.w500, TypeScale.bodyEm,
            cq.textMuted),
        helperStyle: _style(TypeScale.caption, FontWeight.w400,
            TypeScale.captionEm, cq.textMuted),
        border: field,
        enabledBorder: field,
        focusedBorder: field.copyWith(
            borderSide: BorderSide(color: cq.vertDark, width: Borders.focus)),
        errorBorder:
            field.copyWith(borderSide: BorderSide(color: cq.errorColor)),
        focusedErrorBorder: field.copyWith(
            borderSide:
                BorderSide(color: cq.errorColor, width: Borders.focus)),
        errorStyle: _style(TypeScale.caption, FontWeight.w500,
            TypeScale.captionEm, cq.errorColor),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cq.vert,
          foregroundColor: onAccent,
          disabledBackgroundColor: cq.beigeDark,
          disabledForegroundColor: cq.textMuted,
          elevation: 0,
          minimumSize: const Size.fromHeight(Sizes.control),
          shape: control,
          textStyle: buttonLabel,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cq.vert,
          foregroundColor: onAccent,
          disabledBackgroundColor: cq.beigeDark,
          disabledForegroundColor: cq.textMuted,
          minimumSize: const Size.fromHeight(Sizes.control),
          shape: control,
          textStyle: buttonLabel,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cq.textPrimary,
          backgroundColor: cq.cardColor,
          minimumSize: const Size.fromHeight(Sizes.control),
          side: BorderSide(color: cq.beigeDark),
          shape: control,
          textStyle: buttonLabel,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cq.vertDark,
          minimumSize: const Size(Sizes.touchTarget, Sizes.touchTarget),
          textStyle: buttonLabel,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cq.vert,
        foregroundColor: onAccent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: control,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: variant.isDark ? cq.beigeDark : cq.textPrimary,
        contentTextStyle: _style(TypeScale.body, FontWeight.w500,
            TypeScale.bodyEm, variant.isDark ? cq.textPrimary : cq.beige),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cq.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: chrome.border,
        ),
      ),

      // Feuilles : fond plein (jamais transparent) et ombre douce qui les
      // détache de l'écran dessous.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cq.cardColor,
        modalBackgroundColor: cq.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: Chrome.sheetElevation,
        shadowColor: chrome.shadow.color.withValues(alpha: 1),
        dragHandleColor: cq.textHint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: cq.beigeDark,
        thickness: Borders.thin,
        space: Borders.thin,
      ),

      // Navigation : plus de vert foncé. L'indicateur est la teinte sauge
      // claire, et ce qui est posé dessus reste en couleur de texte.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cq.beige,
        indicatorColor: cq.vert,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // `fromMap` plutôt que `resolveWith` : mêmes styles, mais comparables
        // par valeur (une closure ne l'est que par identité, ce qui rendait
        // deux thèmes identiques différents). Première clé satisfaite gagnante.
        labelTextStyle: WidgetStateProperty.fromMap({
          WidgetState.selected: _style(TypeScale.caption, FontWeight.w700,
              TypeScale.captionEm, cq.textPrimary),
          WidgetState.any: _style(TypeScale.caption, FontWeight.w500,
              TypeScale.captionEm, cq.textMuted),
        }),
        iconTheme: WidgetStateProperty.fromMap({
          WidgetState.selected:
              IconThemeData(size: Sizes.iconLg, color: onAccent),
          WidgetState.any:
              IconThemeData(size: Sizes.iconLg, color: cq.textMuted),
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cq.beige,
        indicatorColor: cq.vert,
        selectedIconTheme: IconThemeData(size: Sizes.iconLg, color: onAccent),
        unselectedIconTheme:
            IconThemeData(size: Sizes.iconLg, color: cq.textMuted),
        selectedLabelTextStyle: _style(TypeScale.caption, FontWeight.w700,
            TypeScale.captionEm, cq.textPrimary),
        unselectedLabelTextStyle: _style(TypeScale.caption, FontWeight.w500,
            TypeScale.captionEm, cq.textMuted),
      ),

      // Éteint, l'interrupteur se perdait sur une carte blanche (piste et
      // contour au gris des séparateurs) : contour et pastille plus marqués.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.fromMap({
          WidgetState.selected: onAccent,
          WidgetState.any: cq.textMuted,
        }),
        trackColor: WidgetStateProperty.fromMap({
          WidgetState.selected: cq.vert,
          WidgetState.any: cq.beigeDark,
        }),
        trackOutlineColor: WidgetStateProperty.fromMap({
          WidgetState.selected: cq.vert,
          WidgetState.any: cq.textHint,
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cq.cardColor,
        selectedColor: cq.vert,
        side: BorderSide(color: cq.beigeDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        labelStyle: _style(TypeScale.caption, FontWeight.w500,
            TypeScale.captionEm, cq.textPrimary),
        // Texte d'une puce sélectionnée : posé sur la teinte sauge.
        secondaryLabelStyle: _style(TypeScale.caption, FontWeight.w600,
            TypeScale.captionEm, onAccent),
      ),

      // Six tailles (cf. [TypeScale]) réparties sur les rôles Material,
      // graisses franches sur les titres, interlettrage négatif.
      textTheme: TextTheme(
        displaySmall: _title(TypeScale.display, FontWeight.w800, cq.textPrimary),
        headlineSmall:
            _title(TypeScale.headline, FontWeight.w700, cq.textPrimary),
        titleLarge: _title(TypeScale.title, FontWeight.w700, cq.textPrimary),
        titleMedium:
            _title(TypeScale.bodyLarge, FontWeight.w600, cq.textPrimary),
        titleSmall: _title(TypeScale.body, FontWeight.w600, cq.textPrimary),
        bodyLarge: _body(TypeScale.bodyLarge, cq.textPrimary),
        bodyMedium: _body(TypeScale.body, cq.textPrimary),
        bodySmall: _body(TypeScale.caption, cq.textMuted),
        labelLarge: _style(TypeScale.body, FontWeight.w600, TypeScale.labelEm,
            cq.textPrimary),
        labelMedium: _style(TypeScale.caption, FontWeight.w600,
            TypeScale.captionEm, cq.textPrimary),
        labelSmall: _style(TypeScale.caption, FontWeight.w500,
            TypeScale.captionEm, cq.textMuted),
      ),
    );
  }

  /// Style de texte complet : police explicite (les composants Material ne
  /// fusionnent pas tous avec le texte par défaut), graisse, interlettrage
  /// proportionnel à la taille.
  static TextStyle _style(
    double size,
    FontWeight weight,
    double em,
    Color? color, {
    double? height,
  }) =>
      TextStyle(
        fontFamily: appFontFamily,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: TypeScale.tracking(size, em),
        height: height,
        color: color,
      );

  static TextStyle _title(double size, FontWeight weight, Color color) =>
      _style(size, weight, TypeScale.titleEm, color,
          height: TypeScale.titleHeight);

  static TextStyle _body(double size, Color color) => _style(
      size,
      FontWeight.w400,
      size <= TypeScale.caption ? TypeScale.captionEm : TypeScale.bodyEm,
      color,
      height: TypeScale.bodyHeight);
}

/// Bordure et ombre des cartes principales, selon le thème.
@immutable
class CardChrome {
  const CardChrome({required this.border, required this.shadow});

  final BorderSide border;
  final BoxShadow shadow;

  static CardChrome of(AppThemeVariant variant) => variant.isDark
      // En sombre, un filet clair éblouirait : à peine perceptible, et une
      // ombre plus marquée pour détacher la carte du fond.
      ? CardChrome(
          border: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: Chrome.borderWidth),
          shadow: BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: Chrome.shadowBlur,
            offset: const Offset(0, Chrome.shadowOffsetY),
          ),
        )
      : CardChrome(
          border: BorderSide(
              color: Colors.white.withValues(alpha: Chrome.borderOpacity),
              width: Chrome.borderWidth),
          shadow: BoxShadow(
            color: const Color(0xFF181E2D)
                .withValues(alpha: Chrome.shadowOpacity),
            blurRadius: Chrome.shadowBlur,
            offset: const Offset(0, Chrome.shadowOffsetY),
          ),
        );

  /// Décoration complète d'une carte principale.
  BoxDecoration decoration({required Color color, double radius = Radii.md}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.fromBorderSide(border),
        boxShadow: [shadow],
      );

  @override
  bool operator ==(Object other) =>
      other is CardChrome && other.border == border && other.shadow == shadow;

  @override
  int get hashCode => Object.hash(border, shadow);
}

/// Accès court au chrome et au dégradé du thème actif.
extension CardChromeX on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  CardChrome get chrome =>
      CardChrome.of(_isDark ? AppThemeVariant.dark : AppThemeVariant.light);

  LinearGradient get accentGradient => AppTheme.accentGradientFor(
      _isDark ? AppThemeVariant.dark : AppThemeVariant.light);
}
