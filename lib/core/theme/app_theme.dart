import 'package:flutter/material.dart';

/// Variantes de thème — « Choix du thème (beige, vert sauge, brun,
/// sombre) » (CdC).
enum AppThemeVariant {
  beige('beige', 'Beige', 'Le thème d\'origine, chaud et clair'),
  sage('sage', 'Vert sauge', 'Plus végétal, contrastes doux'),
  brown('brown', 'Brun', 'Terreux, reposant en soirée'),
  dark('dark', 'Sombre', 'Pour travailler la nuit');

  const AppThemeVariant(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  bool get isDark => this == AppThemeVariant.dark;

  static AppThemeVariant fromValue(String? value) {
    for (final variant in values) {
      if (variant.value == value) return variant;
    }
    return AppThemeVariant.beige;
  }
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
}

class AppTheme {
  AppTheme._();

  /// Rayon des cartes et champs. Reste une constante : ce n'est pas une
  /// couleur, elle ne dépend pas du thème.
  static const double radius = 16;

  /// Palette utilisée si l'extension est absente (tests de widget isolés).
  static const CognicColors fallbackColors = _beigeColors;

  // ── Palettes ───────────────────────────────────────────────────────────

  static const CognicColors _beigeColors = CognicColors(
    vert: Color(0xFF7A9E7E),
    vertDark: Color(0xFF5F8163),
    beige: Color(0xFFF9F6F0),
    beigeDark: Color(0xFFEFECE6),
    textPrimary: Color(0xFF2C3E50),
    textMuted: Color(0xFF7F8C8D),
    textHint: Color(0xFFBDC3C7),
    errorColor: Color(0xFFE74C3C),
    onVertMuted: Color(0xFFE4EEE5),
    warning: Color(0xFFE39A3B),
    cardColor: Colors.white,
  );

  static const CognicColors _sageColors = CognicColors(
    vert: Color(0xFF6E9B77),
    vertDark: Color(0xFF4F7557),
    beige: Color(0xFFF2F5F0),
    beigeDark: Color(0xFFE2E9E0),
    textPrimary: Color(0xFF26352B),
    textMuted: Color(0xFF6C7D70),
    textHint: Color(0xFFAFBCB2),
    errorColor: Color(0xFFC0503F),
    onVertMuted: Color(0xFFE2EFE4),
    warning: Color(0xFFCE8A34),
    cardColor: Color(0xFFFBFDFA),
  );

  static const CognicColors _brownColors = CognicColors(
    vert: Color(0xFF8A7A5C),
    vertDark: Color(0xFF665A41),
    beige: Color(0xFFF7F2EA),
    beigeDark: Color(0xFFE9E0D2),
    textPrimary: Color(0xFF3A2F24),
    textMuted: Color(0xFF837567),
    textHint: Color(0xFFC0B3A3),
    errorColor: Color(0xFFB4503C),
    onVertMuted: Color(0xFFEFE8DA),
    warning: Color(0xFFC98A33),
    cardColor: Color(0xFFFFFCF6),
  );

  /// Palette sombre.
  ///
  /// Ce n'est pas une inversion automatique de la palette claire : les teintes
  /// sont désaturées et les contrastes recalculés pour rester lisibles sur
  /// fond sombre sans éblouir.
  static const CognicColors _darkColors = CognicColors(
    vert: Color(0xFF8FB894),
    vertDark: Color(0xFFA9CCAE),
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
        AppThemeVariant.beige => _beigeColors,
        AppThemeVariant.sage => _sageColors,
        AppThemeVariant.brown => _brownColors,
        AppThemeVariant.dark => _darkColors,
      };

  /// Thème clair d'origine, conservé pour les tests et les écrans hors
  /// préférences (démarrage, erreur fatale).
  static final ThemeData light = build(AppThemeVariant.beige);

  // ── Construction ───────────────────────────────────────────────────────

  static ThemeData build(AppThemeVariant variant) {
    final cq = colorsFor(variant);
    final brightness = variant.isDark ? Brightness.dark : Brightness.light;

    final scheme = ColorScheme.fromSeed(
      seedColor: cq.vert,
      brightness: brightness,
      primary: cq.vert,
      onPrimary: variant.isDark ? cq.onVertMuted : Colors.white,
      surface: cq.beige,
      onSurface: cq.textPrimary,
      error: cq.errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: cq.beige,
      primaryColor: cq.vert,
      cardColor: cq.cardColor,
      extensions: [cq],

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: cq.textPrimary),
        titleTextStyle: TextStyle(
          color: cq.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: cq.cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: cq.beigeDark),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cq.cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: cq.textHint, fontSize: 14),
        labelStyle: TextStyle(color: cq.textMuted, fontSize: 14),
        helperStyle: TextStyle(color: cq.textMuted, fontSize: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: cq.beigeDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: cq.beigeDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: cq.vert, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: cq.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: cq.errorColor, width: 1.6),
        ),
        errorStyle: TextStyle(color: cq.errorColor, fontSize: 12),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cq.vert,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: cq.vert.withValues(alpha: 0.45),
          disabledForegroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cq.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: cq.beigeDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cq.vert,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: variant.isDark ? cq.beigeDark : cq.textPrimary,
        contentTextStyle: TextStyle(
          color: variant.isDark ? cq.textPrimary : cq.beige,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: cq.beigeDark,
        thickness: 1,
        space: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cq.cardColor,
        indicatorColor: cq.vert.withValues(alpha: 0.18),
        elevation: 3,
        // `fromMap` plutôt que `resolveWith` : mêmes styles, mais comparables
        // par valeur (une closure ne l'est que par identité, ce qui rendait
        // deux thèmes identiques différents). Première clé satisfaite gagnante.
        labelTextStyle: WidgetStateProperty.fromMap({
          WidgetState.selected: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cq.vertDark,
          ),
          WidgetState.any: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: cq.textMuted,
          ),
        }),
        iconTheme: WidgetStateProperty.fromMap({
          WidgetState.selected: IconThemeData(size: 22, color: cq.vertDark),
          WidgetState.any: IconThemeData(size: 22, color: cq.textMuted),
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cq.cardColor,
        indicatorColor: cq.vert.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(size: 22, color: cq.vertDark),
        unselectedIconTheme: IconThemeData(size: 22, color: cq.textMuted),
        selectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cq.vertDark,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 12,
          color: cq.textMuted,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cq.cardColor,
        selectedColor: cq.vert.withValues(alpha: 0.15),
        side: BorderSide(color: cq.beigeDark),
        labelStyle: TextStyle(color: cq.textPrimary, fontSize: 12),
        secondaryLabelStyle: TextStyle(color: cq.vertDark, fontSize: 12),
      ),

      // Le texte tire désormais ses couleurs de la palette active. C'est ce
      // qui débloque réellement les thèmes : auparavant `textTheme` figeait
      // `textPrimary` clair, et le mode sombre affichait du texte sombre sur
      // fond sombre.
      textTheme: TextTheme(
        titleLarge: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: cq.textPrimary),
        titleMedium: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: cq.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: cq.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: cq.textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: cq.textMuted),
      ),
    );
  }
}
