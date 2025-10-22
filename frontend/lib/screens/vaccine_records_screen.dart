// lib/screens/vaccine_records_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart'; // Import your existing AuthService

class VaccineRecordsScreen extends StatefulWidget {
  const VaccineRecordsScreen({super.key});

  @override
  State<VaccineRecordsScreen> createState() => _VaccineRecordsScreenState();
}

class _VaccineRecordsScreenState extends State<VaccineRecordsScreen> {
  List<VaccineRecord> _vaccines = [];
  bool _isLoading = true;
  String? _error;

  static const String apiBaseUrl = 'http://localhost:5000';
  
  final AuthService _authService = AuthService(); // Use your existing AuthService
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
        _error = 'Please login to view your records';
        _isLoading = false;
      });
      // Redirect to login
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
        setState(() {
          _vaccines = data.map((json) => VaccineRecord.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load vaccines: ${response.statusCode}';
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

  Future<void> _updateVaccineStatus(VaccineRecord vaccine) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
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
        // Refresh the vaccine list
        await _fetchVaccines();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${vaccine.name} marked as completed'),
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
      Navigator.pop(context); // Close loading dialog
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

  void _showConfirmationDialog(VaccineRecord vaccine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Vaccination'),
        content: Text(
          'Have you taken the ${vaccine.name} vaccine?\n\n'
          'This action will mark this dose as completed.',
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
    // Separate completed and scheduled vaccines
    final completedVaccines = _vaccines.where((v) => v.isCompleted).toList();
    final scheduledVaccines = _vaccines.where((v) => !v.isCompleted).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B5FBF),
              Color(0xFFB794F6),
              Color(0xFFD6BCFA),
              Color(0xFFFFB3BA),
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Vaccination Records',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    // Refresh button
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _isLoading ? null : _fetchVaccines,
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildContent(completedVaccines, scheduledVaccines),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<VaccineRecord> completed, List<VaccineRecord> scheduled) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchVaccines,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5FBF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchVaccines,
      color: const Color(0xFF8B5FBF),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Completed',
                    count: completed.length,
                    icon: Icons.check_circle,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Pending',
                    count: scheduled.length,
                    icon: Icons.schedule,
                    color: const Color(0xFF8B5FBF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Pending/Scheduled Vaccines Section (Show first)
            if (scheduled.isNotEmpty) ...[
              const Text(
                'Pending Vaccines',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 16),
              ...scheduled.map((vaccine) => _buildVaccineCard(vaccine)),
              const SizedBox(height: 24),
            ],

            // Completed Vaccines Section
            if (completed.isNotEmpty) ...[
              const Text(
                'Completed Vaccines',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 16),
              ...completed.map((vaccine) => _buildVaccineCard(vaccine)),
            ],

            // Empty state
            if (_vaccines.isEmpty) ...[
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.vaccines_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No vaccination records yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your recommended vaccines will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineCard(VaccineRecord vaccine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vaccine.isCompleted
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFF8B5FBF).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(13, 0, 0, 0),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Checkbox - Interactive for pending vaccines
            GestureDetector(
              onTap: vaccine.isCompleted
                  ? null
                  : () => _showConfirmationDialog(vaccine),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: vaccine.isCompleted
                      ? const Color(0xFF10B981)
                      : Colors.white,
                  border: Border.all(
                    color: vaccine.isCompleted
                        ? const Color(0xFF10B981)
                        : const Color(0xFF9CA3AF),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: vaccine.isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),

            // Vaccine Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vaccine.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                      decoration: vaccine.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (vaccine.diseaseProtectedAgainst != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Protects against: ${vaccine.diseaseProtectedAgainst}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vaccine.isCompleted
                            ? 'Completed: ${_formatDate(vaccine.lastDoseDate ?? vaccine.nextDueDate)}'
                            : 'Due: ${_formatDate(vaccine.nextDueDate)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        // 'Dose ${vaccine.completedDoses}${vaccine.totalDoses != null ? ' of ${vaccine.totalDoses}' : ''}',
                        vaccine.doseDisplay,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: vaccine.isCompleted
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFF8B5FBF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                vaccine.isCompleted ? 'Done' : 'Pending',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: vaccine.isCompleted
                      ? const Color(0xFF10B981)
                      : const Color(0xFF8B5FBF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'Not scheduled';
    
    try {
      final parsedDate = DateTime.parse(date);
      final now = DateTime.now();
      final difference = parsedDate.difference(now).inDays;
      
      final parts = date.split('-');
      if (parts.length != 3) return date;

      final year = parts[0];
      final month = _getMonthName(int.parse(parts[1]));
      final day = parts[2];

      String formattedDate = '$day $month $year';
      
      // Add urgency indicators for pending vaccines
      if (difference < 0) {
        formattedDate += ' (Overdue)';
      } else if (difference <= 7) {
        formattedDate += ' (Due soon)';
      }
      
      return formattedDate;
    } catch (e) {
      return date;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class VaccineRecord {
  final int id;
  final String name;
  final String? diseaseProtectedAgainst;
  final String status;
  final String? nextDueDate;
  final String? lastDoseDate;
  final int completedDoses;
  final int? totalDoses;

  VaccineRecord({
    required this.id,
    required this.name,
    this.diseaseProtectedAgainst,
    required this.status,
    this.nextDueDate,
    this.lastDoseDate,
    required this.completedDoses,
    this.totalDoses,
  });

  bool get isCompleted => status == 'completed';
  
  // ✅ NEW: Helper method for dose display
  String get doseDisplay {
    if (isCompleted) {
      // For completed vaccines, show the dose that was completed
      if (totalDoses != null) {
        return 'Dose $completedDoses of $totalDoses - Complete';
      } else {
        return 'Dose $completedDoses - Complete';
      }
    } else {
      // For pending vaccines, show the next dose to take
      final nextDose = completedDoses + 1;
      if (totalDoses != null) {
        return 'Dose $nextDose of $totalDoses';
      } else {
        return 'Dose $nextDose';
      }
    }
  }

  factory VaccineRecord.fromJson(Map<String, dynamic> json) {
    final vaccineInfo = json['Vaccine'] as Map<String, dynamic>?;
    
    int? totalDoses;
    if (vaccineInfo != null && vaccineInfo['schedule'] != null) {
      final schedule = vaccineInfo['schedule'] as Map<String, dynamic>;
      if (schedule['doses'] != null) {
        totalDoses = (schedule['doses'] as List).length;
      }
    }

    return VaccineRecord(
      id: json['id'] as int,
      name: vaccineInfo?['name'] as String? ?? 'Unknown Vaccine',
      diseaseProtectedAgainst: vaccineInfo?['diseaseProtectedAgainst'] as String?,
      status: json['status'] as String,
      nextDueDate: json['nextDueDate'] as String?,
      lastDoseDate: json['lastDoseDate'] as String?,
      completedDoses: json['completedDoses'] as int? ?? 0,
      totalDoses: totalDoses,
    );
  }
}
