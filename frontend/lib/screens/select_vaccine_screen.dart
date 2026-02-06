// lib/screens/select_vaccine_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/vaccine_record.dart';
import '../services/auth_service.dart';

class SelectVaccineScreen extends StatefulWidget {
  const SelectVaccineScreen({super.key});

  @override
  State<SelectVaccineScreen> createState() => _SelectVaccineScreenState();
}

class _SelectVaccineScreenState extends State<SelectVaccineScreen> {
  List<VaccineRecord> _allVaccines = [];
  bool _isLoading = true;
  String? _error;

  static const String apiBaseUrl = 'http://localhost:5000';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchVaccines();
  }

  Future<void> _fetchVaccines() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/vaccines/recommendations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _allVaccines = data
              .map((json) => VaccineRecord.fromJson(json))
              // Only show "pending" vaccines as options to link
              .where((v) => v.isPending)
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load vaccines: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Vaccine'),
        backgroundColor: const Color(0xFF6B46C1),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
      );
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_allVaccines.isEmpty) {
      return const Center(child: Text('No pending vaccine records found.'));
    }

    return ListView.builder(
      itemCount: _allVaccines.length,
      itemBuilder: (context, index) {
        final vaccine = _allVaccines[index];
        return ListTile(
          title: Text(vaccine.name),
          subtitle: Text(vaccine.doseDisplay),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Send the selected vaccine's ID back to the previous screen
            Navigator.pop(context, vaccine.id);
          },
        );
      },
    );
  }
}
