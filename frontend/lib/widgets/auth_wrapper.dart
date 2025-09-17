import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/getting_started_screen.dart';
import '../screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return _authService.isLoggedIn ? HomeScreen() : GettingStartedScreen();
  }
}
