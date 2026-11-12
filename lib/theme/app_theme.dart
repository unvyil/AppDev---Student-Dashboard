import 'package:flutter/material.dart';

class AppTokens {
  // 60-30-10 Color System
  static const Color maroonPrimary = Color(0xFF800000);
  static const Color maroonSubtle = Color(0xFFF9EAEA);

  // Light Mode Colors
  static const Color canvasLight = Color(0xFFF2F2F2);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF171717);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);

  // Dark Mode Colors
  static const Color canvasDark = Color(0xFF171717);
  static const Color cardDark = Color(0xFF262626);
  static const Color textDark = Color(0xFFFAFDEA);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);
  static const Color borderDark = Color(0xFF333333);

  // High-Energy Accents
  static const Color accentLime = Color(0xFFDBFF49);
  static const Color accentMagenta = Color(0xFFFF006E);

  // CCS Program Track Tokens
  static const Color trackBsitWm = Color(0xFF7B2CBF); // Royal Purple
  static const Color trackBsitNs = Color(0xFF0096C7); // Cyan / Teal
  static const Color trackBscsDs = Color(0xFFE85D04); // Deep Amber / Orange
  static const Color trackBscsSe = Color(0xFF2563EB); // Cobalt Blue

  // Elevation Shadows
  static const List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 8.0,
      offset: Offset(0, 2),
    ),
  ];

  static ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? canvasDark : canvasLight;
    final card = isDark ? cardDark : cardLight;
    final textColor = isDark ? textDark : textLight;
    final secondaryTextColor = isDark ? textSecondaryDark : textSecondaryLight;
    final borderColor = isDark ? borderDark : borderLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: canvas,
      primaryColor: maroonPrimary,
      cardColor: card,
      dividerColor: borderColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: maroonPrimary,
        brightness: brightness,
        primary: maroonPrimary,
        secondary: isDark ? accentLime : maroonPrimary,
        surface: card,
        onSurface: textColor,
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: maroonPrimary,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: isDark ? accentLime : maroonPrimary,
        unselectedItemColor: secondaryTextColor,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: maroonPrimary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? accentLime : maroonPrimary,
          side: BorderSide(
            color: isDark ? accentLime : maroonPrimary,
            width: 1.2,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          color: secondaryTextColor,
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          color: secondaryTextColor,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: maroonPrimary, width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: 'Inter', color: textColor),
        displayMedium: TextStyle(fontFamily: 'Inter', color: textColor),
        displaySmall: TextStyle(fontFamily: 'Inter', color: textColor),
        headlineLarge: TextStyle(fontFamily: 'Inter', color: textColor),
        headlineMedium: TextStyle(fontFamily: 'Inter', color: textColor),
        headlineSmall: TextStyle(fontFamily: 'Inter', color: textColor),
        titleLarge: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.bold, color: textColor),
        titleMedium: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w600, color: textColor),
        titleSmall: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w500, color: textColor),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: textColor),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: textColor),
        bodySmall: TextStyle(fontFamily: 'Inter', color: secondaryTextColor),
        labelLarge: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w600, color: textColor),
        labelMedium: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w500, color: textColor),
        labelSmall: TextStyle(fontFamily: 'Inter', color: secondaryTextColor),
      ),
    );
  }
}
