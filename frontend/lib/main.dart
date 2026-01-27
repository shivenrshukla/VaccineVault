import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaccinevault/app_theme.dart';
import 'package:vaccinevault/providers/theme_provider.dart';
import 'package:vaccinevault/screens/main_wrapper_screen.dart';
import 'package:vaccinevault/routes/app_routes.dart';
import 'screens/getting_started_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/settings_page.dart';
import 'screens/profile_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      themeMode: themeProvider.themeMode,
      title: 'VaccineVault',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const GettingStartedScreen(),
      routes: {
        AppRoutes.gettingStartedScreen: (context) => const GettingStartedScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const SignupScreen(),
        AppRoutes.home: (context) => const MainWrapperScreen(),
        AppRoutes.settings: (context) => const SettingsPage(),
        AppRoutes.profile: (context) => const ProfilePage(),
      },
    );
  }
}