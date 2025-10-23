// lib/screens/vaccine_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/vaccine_record.dart'; // ✅ Import the shared model

class VaccineScheduleScreen extends StatefulWidget {
  const VaccineScheduleScreen({super.key});

  @override
  State<VaccineScheduleScreen> createState() => _VaccineScheduleScreenState();
}

class _VaccineScheduleScreenState extends State<VaccineScheduleScreen> {
  // ✅ This list is for "Scheduled" items ONLY
  List<VaccineRecord> _scheduledVaccines = [];
  bool _isLoading = true;
  String? _error;

  static const String apiBaseUrl = 'http://localhost:5000';
  final AuthService _authService = AuthService();
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    await _loadAuthToken();
    if (_authToken != null && _authToken!.isNotEmpty) {
      await _fetchVaccines();
    } else {
      setState(() {
        _error = 'Please login to view your schedule';
        _isLoading = false;
      });
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _loadAuthToken() async {
    _authToken = await _authService.getToken();
  }

  Future<void> _fetchVaccines() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/vaccines/recommendations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allVaccines = data
            .map((json) => VaccineRecord.fromJson(json))
            .toList();

        // ✅ Filter for SCHEDULED vaccines only
        setState(() {
          _scheduledVaccines = allVaccines
              .where((v) => v.category == VaccineCategory.scheduled)
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load schedule: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error connecting to server: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ "Mark as Taken" logic now lives here
  Future<void> _updateVaccineStatus(VaccineRecord vaccine) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
      ),
    );

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/vaccines/status/${vaccine.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({'hasTaken': true}),
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        await _fetchVaccines(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${vaccine.name} marked as completed!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update: ${response.statusCode}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ✅ Confirmation dialog
  void _showConfirmationDialog(VaccineRecord vaccine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Vaccination'),
        content: Text(
          'Mark ${vaccine.name} as completed?\n\nThis will move it to your completed records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateVaccineStatus(vaccine);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Yes, I\'ve taken it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Schedule'),
        backgroundColor: const Color(0xFF6B46C1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchVaccines,
          ),
        ],
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    if (_scheduledVaccines.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No upcoming vaccines',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Go to "Vaccine Records" to schedule one.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchVaccines,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _scheduledVaccines.length,
        itemBuilder: (context, index) {
          final vaccine = _scheduledVaccines[index];
          return _buildScheduleCard(vaccine);
        },
      ),
    );
  }

  // ✅ This card is now interactive
  Widget _buildScheduleCard(VaccineRecord vaccine) {
    String formattedDate = 'Scheduled: Not set';
    if (vaccine.nextDueDate != null) {
      formattedDate =
          'Due: ${DateFormat.yMMMd().format(DateTime.parse(vaccine.nextDueDate!))}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () => _showConfirmationDialog(vaccine),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.check_box_outline_blank,
                color: Colors.grey.shade700,
                size: 40.0,
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaccine.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      vaccine.doseDisplay,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
