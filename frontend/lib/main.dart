import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaccinevault/providers/theme_provider.dart';
import 'package:vaccinevault/screens/main_wrapper_screen.dart';
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'VaccineVault',
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            fontFamily: 'SF Pro Display',
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.deepPurple,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            fontFamily: 'SF Pro Display',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF1A1A1A),
            cardColor: const Color(0xFF2D2D2D),
          ),
          themeMode: themeProvider.themeMode,
          home: GettingStartedScreen(),
          routes: {
            '/getting-started': (context) => GettingStartedScreen(),
            '/login': (context) => LoginScreen(),
            '/signup': (context) => SignupScreen(),
            '/home': (context) => MainWrapperScreen(),
            '/settings': (context) => const SettingsPage(),
            '/profile': (context) => const ProfilePage(),
          },
        );
      },
    );
  }
}


