import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';
import '../screens/getting_started_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  late Future<String?> _checkTokenFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future in initState to prevent it from being called on every rebuild
    _checkTokenFuture = _authService.getToken();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _checkTokenFuture,
      builder: (context, snapshot) {
        // Show a loading spinner while checking for the token
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If an error occurs, show an error screen (or the login screen)
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('An error occurred. Please restart the app.')),
          );
        }

        // Check if the snapshot has data and the token is not null/empty
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, show the HomeScreen
          return HomeScreen();
        } else {
          // User is not logged in, show the GettingStartedScreen
          return const GettingStartedScreen();
        }
      },
    );
  }
}

