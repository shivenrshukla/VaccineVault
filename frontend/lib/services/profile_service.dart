import 'dart:convert';
import 'package:http/http.dart' as http;
import './auth_service.dart';
import 'package:logger/logger.dart';

class ProfileService {
  final String baseUrl = 'http://10.0.2.2:5000/api/auth';
  final AuthService authService = AuthService();    // Instance of AuthService
  final http.Client client;
  final logger = Logger();

  ProfileService({
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('You are not logged in.');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        logger.i('Password changed successfully.');
        return; // Success
      } else {
        // Handle failure (e.g., wrong current password, server error)
        logger.e('Failed to change password. Status: ${response.statusCode}');
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
      logger.e('Exception in changePassword: $e');
      rethrow; // Re-throw to be caught by the UI
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      // Get token from AuthService
      final token = await authService.getToken(); 
      if (token == null || token.isEmpty) {
        logger.w('No profile found: User is not logged in.');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 401) {
        logger.w('Unauthorized access when fetching profile. Token may be invalid or expired.');
        await authService.clearToken();
        return null;
      }

      logger.e('Failed to fetch profile. Status code: ${response.statusCode}');
      return null;
    } catch (e, stackTrace) {
      logger.e('Error fetching profile', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updatedData) async {
    try {
      final token = await authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('You are not logged in.');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/profile-update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updatedData),
      );

      if (response.statusCode == 200) {
        logger.i('Profile updated successfully.');
      }

      if (response.statusCode == 401) {
        logger.w('Unauthorized access when updating profile.Token may be invalid or expired.');
        await authService.clearToken();
        throw Exception('Unauthorized: Please log in again to update your profile.');
      }

      logger.e('Failed to update profile. Status code: ${response.statusCode}');
      throw Exception('Failed to update profile: ${response.body}');
    } catch (e, stackTrace) {
      logger.e('Error updating profile', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
