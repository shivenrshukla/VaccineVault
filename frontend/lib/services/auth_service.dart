import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:5000/api/auth';
  static const storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';
  final logger = Logger();

  Future<void> setBiometricEnabled(bool enabled) async {
    await storage.write(
      key: 'biometric_enabled',
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> isBiometricEnabled() async {
    String? value = await storage.read(key: 'biometric_enabled');
    return value == 'true';
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        logger.d('Login successful. Response body: ${response.body}');
        final data = json.decode(response.body);
        final token = data['token'];

        if (token != null) {
          logger.i('Token found: $token');
          await saveToken(token);
          // Just return on success
          return;
        } else {
          // Server error if token is missing on 200
          logger.i('Login successful, but no token found in response.');
          throw Exception('Login error: No token received from server.');
        }
      } else {
        logger.d('Login failed with status code: ${response.statusCode}');
        logger.d('Response body: ${response.body}');

        // Parse the error message from the server
        String errorMessage = 'Invalid username or password';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (_) {
          // Ignore if body isn't JSON
        }

        // THROW the error. This will be caught by the LoginScreen.
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Catch network errors or the exception we just threw
      logger.e('An exception occurred during login: $e');
      // Re-throw it so the UI's catch block can get it
      rethrow;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData), // Send the entire user object
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);

        final String? token = data['token'];
        if (token == null) {
          logger.e('Registration failed: No token received.');
          return false;
        }

        await saveToken(data['token']);
        return true;
      }

      logger.e(
        'Registration failed with status code: ${response.statusCode} and body: ${response.body}',
      );
      return false;
    } catch (e) {
      logger.e('Register error: $e');
      return false;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      if (kIsWeb) {
        // Web fallback: no secure storage, use SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);

        logger.w(
          'Using SharedPreferences for token storage on web; not secure!',
        );
      } else {
        // Mobile/Desktop: use secure storage
        await storage.write(key: _tokenKey, value: token);
        logger.i('Token saved in secure storage.');
      }
    } catch (e, stackTrace) {
      logger.e('Error saving token', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_tokenKey);
      } else {
        return await storage.read(key: _tokenKey);
      }
    } catch (e) {
      logger.e('Error reading token: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      String? token = await getToken();
      return token != null;
    } catch (e) {
      logger.e('Error checking login status: $e');
      return false;
    }
  }

  Future<void> clearToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
      } else {
        await storage.delete(key: _tokenKey);
      }
      logger.i('Token cleared successfully.');
    } catch (e) {
      logger.e('Error clearing token: $e');
    }
  }

  Future<void> logout() async {
    await clearToken();
  }
}
