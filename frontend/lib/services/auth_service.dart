import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  static const String baseUrl = 'http://localhost:5000/api/auth';
  static const storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  Future<void> setBiometricEnabled(bool enabled) async {
    await storage.write(key: 'biometric_enabled', value: enabled ? 'true' : 'false');
  }

  Future<bool> isBiometricEnabled() async {
    String? value = await storage.read(key: 'biometric_enabled');
    return value == 'true';
  }

  // --- UPDATED ---
  // Changed return type from Future<bool> to Future<void>.
  // It will now throw an exception on failure instead of returning false.
  Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        // --- SUCCESS ---
        print('Login successful. Response body: ${response.body}');
        final data = json.decode(response.body);
        final token = data['token'];

        if (token != null) {
          print('Token found: $token');
          await saveToken(token);
          // Just return on success
          return;
        } else {
          // Server error if token is missing on 200
          print('Login successful, but no token found in response.');
          throw Exception('Login error: No token received from server.');
        }
      } else {
        // --- FAILURE ---
        print('Login failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        
        // Try to parse the error message from the server
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
      print('An exception occurred during login: $e');
      // Re-throw it so the UI's catch block can get it
      rethrow;
    }
  }

  // --- NEW METHOD ---
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('You are not logged in.');
      }

      final response = await http.put( // Or POST, depending on your API
        Uri.parse('$baseUrl/change-password'), // Assuming this endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Send token for auth
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        print('Password changed successfully.');
        return; // Success
      } else {
        // Handle failure (e.g., wrong current password, server error)
        print('Failed to change password. Status: ${response.statusCode}');
        String errorMessage = 'Failed to change password';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (_) {
          // Ignore if body isn't JSON
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Exception in changePassword: $e');
      rethrow; // Re-throw to be caught by the UI
    }
  }
  // --- END OF NEW METHOD ---

  Future<bool> signup(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await saveToken(data['token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  Future<bool> register(Object userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'), // Assuming a '/register' endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData), // Send the entire user object
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await saveToken(data['token']);
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
      } else {
        await storage.write(key: _tokenKey, value: token);
      }
      print('Token saved successfully.');
    } catch (e) {
      print('Error saving token: $e');
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
      print('Error reading token: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      String? token = await getToken();
      return token != null;
    } catch (e) {
      print('Error in isLoggedIn: $e');
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
      print('Token cleared successfully.');
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  Future<void> logout() async {
    await clearToken();
  }
}