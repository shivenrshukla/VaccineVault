import 'dart:convert';
import 'package:http/http.dart' as http;
import './auth_service.dart'; // Import AuthService

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api/auth';
  
  // Create an instance of AuthService
  static final AuthService _authService = AuthService();

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      // Get token from AuthService
      String? token = await _authService.getToken(); 
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  static Future<bool> updateProfile(Map<String, dynamic> userData) async {
    try {
      // Get token from AuthService
      String? token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/profile-update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(userData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
}
