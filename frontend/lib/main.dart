import 'package:flutter/material.dart';
import 'package:vaccinevault/screens/main_wrapper_screen.dart';
import 'screens/getting_started_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaccineVault',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'SF Pro Display',
      ),
      home: GettingStartedScreen(),
      routes: {
        '/getting-started': (context) => GettingStartedScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => MainWrapperScreen(),
      },
    );
  }
}
