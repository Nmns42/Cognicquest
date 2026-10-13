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
  // Contrastes mesurés (WCAG), sur le fond et sur les cartes :
  // texte ≥ 10:1, texte secondaire, accent en texte, erreur et
  // avertissement ≥ 4,5:1, texte sur l'accent ≥ 4,5:1.
  //
  // Accent : un eucalyptus pâle et désaturé (#ABC4B8). Trop clair pour
  // porter du blanc, il porte un vert très sombre (#1F3329, 7,2:1) : des
  // boutons doux, sans masse sombre. Le vert en texte (#4A7861) est le plus
  // clair qui tienne 4,5:1 sur le fond.

  static const CognicColors _lightColors = CognicColors(
    vert: Color(0xFFABC4B8),
    vertDark: Color(0xFF4A7861),
    beige: Color(0xFFF9F6F0),
    beigeDark: Color(0xFFE8E5DC),
    textPrimary: Color(0xFF2B3A36),
    textMuted: Color(0xFF63706A),
    textHint: Color(0xFF878D88),
    errorColor: Color(0xFFC44133),
    onVertMuted: Color(0xFF2E4A3D),
    warning: Color(0xFF966627),
    cardColor: Color(0xFFFFFDF9),
  );

  /// Palette sombre.
  ///
  /// Ce n'est pas une inversion automatique de la palette claire : les teintes
  /// sont désaturées et les contrastes recalculés pour rester lisibles sur
  /// fond sombre sans éblouir.
  static const CognicColors _darkColors = CognicColors(
    vert: Color(0xFF8DB098),
    vertDark: Color(0xFFA8C9B4),
    beige: Color(0xFF16191A),
    beigeDark: Color(0xFF2C3133),
    textPrimary: Color(0xFFE8EBE9),
    textMuted: Color(0xFF9AA5A0),
    textHint: Color(0xFF6B7672),
    errorColor: Color(0xFFE8766A),
    onVertMuted: Color(0xFF1E2A21),
    warning: Color(0xFFE0A657),
    cardColor: Color(0xFF212527),
  );

  static CognicColors colorsFor(AppThemeVariant variant) => switch (variant) {
        AppThemeVariant.light => _lightColors,
        AppThemeVariant.dark => _darkColors,
      };

  /// Texte et icônes posés sur l'accent plein (boutons, pastilles).
  static Color onAccentFor(AppThemeVariant variant) =>
      variant.isDark ? _darkColors.beige : const Color(0xFF1F3329);

  /// Thème clair, conservé pour les tests et les écrans hors préférences
  /// (démarrage, erreur fatale).
  static final ThemeData light = build(AppThemeVariant.light);

  // ── Construction ───────────────────────────────────────────────────────

  static ThemeData build(AppThemeVariant variant) {
    final cq = colorsFor(variant);
    final brightness = variant.isDark ? Brightness.dark : Brightness.light;
    final onAccent = onAccentFor(variant);

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
    const buttonLabel = TextStyle(
      fontFamily: appFontFamily,
      fontSize: TypeScale.body,
      fontWeight: FontWeight.w600,
      letterSpacing: TypeScale.trackingLabel,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: appFontFamily,
      colorScheme: scheme,
      // Transparent : le fond (beige et motif de feuilles) est peint une
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
        titleTextStyle: TextStyle(
          fontFamily: appFontFamily,
          color: cq.textPrimary,
          fontSize: TypeScale.title,
          fontWeight: FontWeight.w600,
          height: TypeScale.titleHeight,
        ),
      ),

      // Surfaces tonales, sans ombre : le calme vient de la retenue.
      cardTheme: CardThemeData(
        color: cq.cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: cq.beigeDark),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cq.cardColor,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Space.lg, vertical: Space.md),
        // Le texte indicatif est lu : contraste du texte secondaire, pas
        // celui des éléments décoratifs.
        hintStyle: TextStyle(
            fontFamily: appFontFamily,
            color: cq.textMuted,
            fontSize: TypeScale.body),
        labelStyle: TextStyle(
            fontFamily: appFontFamily,
            color: cq.textMuted,
            fontSize: TypeScale.body),
        helperStyle: TextStyle(
            fontFamily: appFontFamily,
            color: cq.textMuted,
            fontSize: TypeScale.caption),
        border: field,
        enabledBorder: field,
        focusedBorder:
            field.copyWith(borderSide: BorderSide(color: cq.vert, width: 2)),
        errorBorder:
            field.copyWith(borderSide: BorderSide(color: cq.errorColor)),
        focusedErrorBorder: field.copyWith(
            borderSide: BorderSide(color: cq.errorColor, width: 2)),
        errorStyle: TextStyle(
            fontFamily: appFontFamily,
            color: cq.errorColor,
            fontSize: TypeScale.caption),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cq.vert,
          foregroundColor: onAccent,
          disabledBackgroundColor: cq.beigeDark,
          disabledForegroundColor: cq.textMuted,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
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
          minimumSize: const Size.fromHeight(52),
          shape: control,
          textStyle: buttonLabel,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cq.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: cq.beigeDark),
          shape: control,
          textStyle: buttonLabel,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          // L'accent foncé tient 4,5:1 en texte ; l'accent plein, non.
          foregroundColor: cq.vertDark,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontFamily: appFontFamily,
            fontSize: TypeScale.body,
            fontWeight: FontWeight.w600,
          ),
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
        contentTextStyle: TextStyle(
          fontFamily: appFontFamily,
          color: variant.isDark ? cq.textPrimary : cq.beige,
          fontSize: TypeScale.body,
        ),
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
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cq.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        dragHandleColor: cq.textHint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: cq.beigeDark,
        thickness: 1,
        space: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cq.beige,
        indicatorColor: cq.vert.withValues(alpha: Tints.selected),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // `fromMap` plutôt que `resolveWith` : mêmes styles, mais comparables
        // par valeur (une closure ne l'est que par identité, ce qui rendait
        // deux thèmes identiques différents). Première clé satisfaite gagnante.
        labelTextStyle: WidgetStateProperty.fromMap({
          WidgetState.selected: TextStyle(
            fontFamily: appFontFamily,
            fontSize: TypeScale.caption,
            fontWeight: FontWeight.w600,
            color: cq.vertDark,
          ),
          WidgetState.any: TextStyle(
            fontFamily: appFontFamily,
            fontSize: TypeScale.caption,
            fontWeight: FontWeight.w500,
            color: cq.textMuted,
          ),
        }),
        iconTheme: WidgetStateProperty.fromMap({
          WidgetState.selected: IconThemeData(size: 24, color: cq.vertDark),
          WidgetState.any: IconThemeData(size: 24, color: cq.textMuted),
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cq.beige,
        indicatorColor: cq.vert.withValues(alpha: Tints.selected),
        selectedIconTheme: IconThemeData(size: 24, color: cq.vertDark),
        unselectedIconTheme: IconThemeData(size: 24, color: cq.textMuted),
        selectedLabelTextStyle: TextStyle(
          fontFamily: appFontFamily,
          fontSize: TypeScale.caption,
          fontWeight: FontWeight.w600,
          color: cq.vertDark,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: appFontFamily,
          fontSize: TypeScale.caption,
          color: cq.textMuted,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cq.cardColor,
        selectedColor: cq.vert.withValues(alpha: Tints.selected),
        side: BorderSide(color: cq.beigeDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        labelStyle: TextStyle(
            fontFamily: appFontFamily,
            color: cq.textPrimary,
            fontSize: TypeScale.caption),
        // Texte d'une puce sélectionnée : posé sur la teinte, donc en couleur
        // de texte (l'accent n'y tiendrait pas 4,5:1).
        secondaryLabelStyle: TextStyle(
            fontFamily: appFontFamily,
            color: cq.textPrimary,
            fontSize: TypeScale.caption),
      ),

      // Six tailles (cf. [TypeScale]) réparties sur les rôles Material. Le
      // texte tire ses couleurs de la palette active : c'est ce qui rend le
      // thème sombre lisible.
      textTheme: TextTheme(
        displaySmall: _title(TypeScale.display, cq.textPrimary),
        headlineSmall: _title(TypeScale.headline, cq.textPrimary),
        titleLarge: _title(TypeScale.title, cq.textPrimary),
        titleMedium: _title(TypeScale.bodyLarge, cq.textPrimary),
        titleSmall: _title(TypeScale.body, cq.textPrimary),
        bodyLarge: _body(TypeScale.bodyLarge, cq.textPrimary),
        bodyMedium: _body(TypeScale.body, cq.textPrimary),
        bodySmall: _body(TypeScale.caption, cq.textMuted),
        labelLarge: TextStyle(
            fontFamily: appFontFamily,
            fontSize: TypeScale.body,
            fontWeight: FontWeight.w600,
            letterSpacing: TypeScale.trackingLabel,
            color: cq.textPrimary),
        labelMedium: TextStyle(
            fontFamily: appFontFamily,
            fontSize: TypeScale.caption,
            fontWeight: FontWeight.w600,
            letterSpacing: TypeScale.trackingCaption,
            color: cq.textPrimary),
        labelSmall: TextStyle(
            fontFamily: appFontFamily,
            fontSize: TypeScale.caption,
            fontWeight: FontWeight.w500,
            letterSpacing: TypeScale.trackingCaption,
            color: cq.textMuted),
      ),
    );
  }

  static TextStyle _title(double size, Color color) => TextStyle(
        fontFamily: appFontFamily,
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: TypeScale.titleHeight,
        // Les petits titres gardent un interlettrage neutre ; seuls les grands
        // gagnent à être resserrés.
        letterSpacing: size >= TypeScale.title ? TypeScale.trackingTitle : 0,
        color: color,
      );

  static TextStyle _body(double size, Color color) => TextStyle(
        fontFamily: appFontFamily,
        fontSize: size,
        height: TypeScale.bodyHeight,
        letterSpacing: size <= TypeScale.caption
            ? TypeScale.trackingCaption
            : TypeScale.trackingBody,
        color: color,
      );
}
