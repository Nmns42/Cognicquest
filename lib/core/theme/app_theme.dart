import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: Colors.green),
    scaffoldBackgroundColor: Colors.white,
    textTheme: TextTheme(
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ),
    // Déclaration des constantes statiques
    vert: const Color(0xFF7A9E7E),
    beige: const Color(0xFFF9F6F0),
    beigeDark: const Color(0xFFEFECE6),
    textPrimary: const Color(0xFF2C3E50),
    textMuted: const Color(0xFF7F8C8D),
    textHint: const Color(0xFFBDC3C7),
    errorColor: const Color(0xFFE74C3C),
  );
}
