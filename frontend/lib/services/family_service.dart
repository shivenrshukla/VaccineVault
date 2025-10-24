import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './auth_service.dart';

class FamilyService {
  static const String baseUrl = 'http://localhost:5000'; // Replace with your actual API URL
  static final AuthService _authService = AuthService();

  // --- Family Management Methods (from original file) ---

  // Get family overview (admin + all members with vaccine stats)
  static Future<Map<String, dynamic>> getFamilyOverview() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('$baseUrl/api/family/overview'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load family overview: ${response.body}');
    }
  }

  // Get all family members
  static Future<List<dynamic>> getFamilyMembers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('$baseUrl/api/family/members'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['familyMembers'] ?? [];
    } else {
      throw Exception('Failed to load family members: ${response.body}');
    }
  }

  // Add a new family member
  static Future<Map<String, dynamic>> addFamilyMember({
    required String username,
    required String email,
    required String gender,
    required String dateOfBirth,
    required String phoneNumber,
    String? relationshipToAdmin,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.post(
      Uri.parse('$baseUrl/api/family/members'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'username': username,
        'email': email,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'phoneNumber': phoneNumber,
        'relationshipToAdmin': relationshipToAdmin,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to add family member');
    }
  }

  // Get vaccines for a specific family member
  static Future<Map<String, dynamic>> getFamilyMemberVaccines(int memberId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('$baseUrl/api/family/members/$memberId/vaccines'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load member vaccines: ${response.body}');
    }
  }

  // Update family member details
  static Future<bool> updateFamilyMember(
    int memberId,
    Map<String, dynamic> updates,
  ) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.put(
      Uri.parse('$baseUrl/api/family/members/$memberId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to update family member');
    }
  }

  // Remove family member
  static Future<bool> removeFamilyMember(int memberId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.delete(
      Uri.parse('$baseUrl/api/family/members/$memberId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to remove family member');
    }
  }

  // --- NEW/UPDATED VACCINE METHODS (based on routes file) ---
  // Assumes routes are mounted at '/api/vaccines'

  /**
   * Gets recommended vaccines for the logged-in user.
   * Based on: GET /recommendations
   */
  static Future<Map<String, dynamic>> getRecommendedVaccines() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('$baseUrl/api/vaccines/recommendations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load recommendations: ${response.body}');
    }
  }

  /**
   * Marks a specific vaccine as completed.
   * Based on: PUT /status/:userVaccineId
   */
  static Future<bool> markVaccineAsDone(int vaccineId, String administeredDate) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.put(
      Uri.parse('$baseUrl/api/vaccines/status/$vaccineId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'status': 'completed', // Explicitly setting status as per controller
        'administeredDate': administeredDate,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to mark vaccine as done');
    }
  }

  /**
   * Schedules a due date for a vaccine.
   * Based on: PUT /schedule/:userVaccineId
   */
  static Future<bool> scheduleVaccine(int vaccineId, String scheduledDate) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.put(
      Uri.parse('$baseUrl/api/vaccines/schedule/$vaccineId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'scheduledDate': scheduledDate,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to schedule vaccine');
    }
  }
}

// Family@8bqgehdh