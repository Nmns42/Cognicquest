import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color beige       = Color(0xFFF5F0E8);
  static const Color beigeDark   = Color(0xFFD8CFC2);
  static const Color vert        = Color(0xFF7A9E7E);
  static const Color textPrimary = Color(0xFF2C2C2A);
  static const Color textMuted   = Color(0xFF6B6B68);
  static const Color textHint    = Color(0xFF9E9E9A);
  static const Color white       = Color(0xFFFFFFFF);
  static const Color errorColor  = Color(0xFFD85A30);

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final txt = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: beige,
      colorScheme: ColorScheme.fromSeed(
        seedColor: vert,
        background: beige,
        surface: white,
        primary: vert,
        onPrimary: white,
        error: errorColor,
      ),
      textTheme: txt.copyWith(
        titleLarge: txt.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleMedium: txt.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyLarge: txt.bodyLarge?.copyWith(
          color: textPrimary,
          fontSize: 16,
          height: 1.6,
        ),
        bodyMedium: txt.bodyMedium?.copyWith(
          color: textMuted,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: beigeDark, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vert,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: beigeDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: beigeDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: vert, width: 2),
        ),
        hintStyle: const TextStyle(color: textHint, fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: beige,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: vert,
        unselectedItemColor: textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}