import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.light, 
      seedColor: Colors.deepPurple,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'SF Pro Display',
    scaffoldBackgroundColor: Colors.white,
  );

  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark, 
      seedColor: Colors.deepPurple,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    fontFamily: 'SF Pro Display',
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    cardColor: const Color(0xFF2D2D2D),
  );
}