import 'package:flutter/material.dart';

/// Retro-inspired theme for Stash 64.
class AppTheme {
  // Core palette — dark with warm accent colors
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color surfaceDark = Color(0xFF16213E);
  static const Color cardDark = Color(0xFF1F2B47);
  static const Color accentGold = Color(0xFFE2B714);
  static const Color accentCyan = Color(0xFF00D4AA);
  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color errorRed = Color(0xFFFF6B6B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accentGold,
        secondary: accentCyan,
        surface: surfaceDark,
        error: errorRed,
        onPrimary: primaryDark,
        onSecondary: primaryDark,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: primaryDark,
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: accentGold,
          letterSpacing: 2,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentGold,
        foregroundColor: primaryDark,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardDark,
        selectedColor: accentGold.withOpacity(0.3),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
        side: BorderSide(color: textSecondary.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentGold, width: 2),
        ),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: accentGold,
          letterSpacing: 1.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'monospace',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: accentGold,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: textSecondary.withOpacity(0.2),
      ),
    );
  }

  // Touch-friendly minimum tap target (48dp per Material guidelines,
  // but we use 56dp for comfortable Raspberry Pi touchscreen use)
  static const double touchTargetSize = 56.0;

  // Grid layout helpers
  static int gridCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1200) return 5;
    if (screenWidth >= 900) return 4;
    if (screenWidth >= 600) return 3;
    return 2;
  }

  static double gridChildAspectRatio(double screenWidth) {
    // Taller cards for smaller screens (more room for text)
    if (screenWidth >= 900) return 0.65;
    return 0.60;
  }
}
