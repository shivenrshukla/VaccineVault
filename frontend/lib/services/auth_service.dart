import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService {
  // 👇 IMPORTANT: Replace with your actual local IP address
  static const String _baseUrl = 'http://localhost:5000/api/auth';
  
  // Use secure storage instead of SharedPreferences
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  /// --- Private Helper Methods ---

  // Saves the authentication token to secure encrypted storage
  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// --- Public API Methods ---

  /// Checks for a stored token to determine if the user is already logged in.
  /// Returns the token if it exists, otherwise returns null.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Checks if user is authenticated
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Registers a new user with the backend.
  /// On success, it saves the received token and returns it.
  Future<String> register(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _saveToken(token); // Save token securely on successful registration
        return token;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to register');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Logs in an existing user.
  /// On success, it saves the received token and returns it.
  Future<String> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _saveToken(token); // Save token securely on successful login
        return token;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to login');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  /// Logs out the current user.
  /// It informs the backend to invalidate the token and removes it from secure storage.
  Future<void> logout() async {
    final token = await _storage.read(key: _tokenKey);

    if (token != null) {
      try {
        // Inform the backend to add the token to the denylist.
        await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (e) {
        // Continue with logout even if backend call fails
        print('Logout backend call failed: $e');
      }
      
      // Always remove the token from secure storage
      await _storage.delete(key: _tokenKey);
    }
  }

  /// Clear all stored data (useful for complete logout or account deletion)
  Future<void> clearAllData() async {
    await _storage.deleteAll();
  }
}
