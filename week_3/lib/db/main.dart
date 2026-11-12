import 'package:flutter/material.dart';

import 'home_page.dart';
import 'services/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = AppPreferences();
  await preferences.load();
  runApp(LpuStudentApp(preferences: preferences));
}

class LpuStudentApp extends StatelessWidget {
  const LpuStudentApp({super.key, required this.preferences});

  final AppPreferences preferences;
  static const Color lpuMaroon = Color(0xFF800000);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: preferences,
      builder: (context, child) => MaterialApp(
        title: 'LPU Student Portal',
        debugShowCheckedModeBanner: false,
        themeMode: preferences.themeMode,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: HomePage(preferences: preferences),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lpuMaroon,
        brightness: brightness,
        primary: lpuMaroon,
        secondary: const Color(0xFFFF006E),
        tertiary: const Color(0xFFDBFF49),
      ),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: lpuMaroon,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 1.2,
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lpuMaroon, width: 1.5),
        ),
      ),
    );
  }
}
