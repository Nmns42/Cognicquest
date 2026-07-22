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
    // Ajout des propriétés de couleur demandées
    vert: const Color(0xFF7A9E7E),
    textMuted: const Color(0xFFBA7517),
    beigeDark: const Color(0xFFF5F0E8),
    textPrimary: Colors.black,
    textHint: const Color(0xFFD8CFC2),
    beige: const Color(0xFFF5F0E8),
    errorColor: const Color(0xFFD85A30),
  );
}
