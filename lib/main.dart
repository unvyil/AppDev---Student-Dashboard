import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_page.dart';
import 'services/app_preferences.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://slwbqvbpumlspagacwnp.supabase.co',
    publishableKey: 'sb_publishable_D7EtEcU34JzAO2zpcek1bQ_yl99gO3C',
  );
  final preferences = AppPreferences();
  await preferences.load();
  runApp(LpuStudentApp(preferences: preferences));
}

class LpuStudentApp extends StatelessWidget {
  const LpuStudentApp({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: preferences,
        builder: (context, _) => MaterialApp(
          title: 'LPU-Cavite Student Dashboard',
          debugShowCheckedModeBanner: false,
          themeMode: preferences.themeMode,
          theme: AppTokens.buildTheme(Brightness.light),
          darkTheme: AppTokens.buildTheme(Brightness.dark),
          initialRoute: '/login',
          routes: {
            '/login': (_) => AuthPage(preferences: preferences),
          },
        ),
      );
}
