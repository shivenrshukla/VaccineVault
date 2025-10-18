import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  // 👇 IMPORTANT: Replace with your actual local IP address
  static const String _baseUrl = 'http://10.10.46.178:5050/api/auth';
  static const String _tokenKey = 'jwt_token';

  /// --- Private Helper Methods ---

  // Saves the authentication token to the device's local storage.
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// --- Public API Methods ---

  /// Checks for a stored token to determine if the user is already logged in.
  /// Returns the token if it exists, otherwise returns null.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Registers a new user with the backend.
  /// On success, it saves the received token and returns it.
  Future<String> register(User user) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      await _saveToken(token); // Save token on successful registration
      return token;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to register');
    }
  }

  /// Logs in an existing user.
  /// On success, it saves the received token and returns it.
  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      await _saveToken(token); // Save token on successful login
      return token;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to login');
    }
  }

  /// Logs out the current user.
  /// It informs the backend to invalidate the token and removes it from local storage.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token != null) {
      // Inform the backend to add the token to the denylist.
      await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      // Always remove the token from the device, even if the network call fails.
      await prefs.remove(_tokenKey);
    }
  }
}
