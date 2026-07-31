/*
===========================================
MeccsIQ Pro v2.0
Build: #001
Version: v2.0.0
File: app_theme.dart
===========================================
*/

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  //========================
  // Colors
  //========================

  static const Color primary = Color(0xFF2F80ED);
  static const Color accent = Color(0xFF00D1FF);

  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFFF5252);

  // Dark

  static const Color darkBackground = Color(0xFF08131F);
  static const Color darkSurface = Color(0xFF111B2B);
  static const Color darkCard = Color(0xFF1B2940);

  // Light

  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Color(0xFFFDFDFD);

  // Text

  static const Color darkText = Colors.white;
  static const Color darkTextSecondary = Color(0xFFA7B4C6);

  static const Color lightText = Color(0xFF202124);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Radius

  static const double radius = 18;

  //========================
  // DARK THEME
  //========================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.dark,

      scaffoldBackgroundColor: darkBackground,

      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: darkSurface,
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: darkBackground,
        foregroundColor: Colors.white,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      dividerColor: Colors.white12,

      fontFamily: 'Roboto',
    );
  }

  //========================
  // LIGHT THEME
  //========================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.light,

      scaffoldBackgroundColor: lightBackground,

      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: lightSurface,
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: lightBackground,
        foregroundColor: Colors.black,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      dividerColor: Colors.black12,

      fontFamily: 'Roboto',
    );
  }
}
