// lib/screens/travel_vaccines_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/vaccine_record.dart';

class TravelVaccinesScreen extends StatefulWidget {
  const TravelVaccinesScreen({super.key});

  @override
  State<TravelVaccinesScreen> createState() => _TravelVaccinesScreenState();
}

class _TravelVaccinesScreenState extends State<TravelVaccinesScreen> {
  List<VaccineRecord> _userVaccines = [];
  bool _isLoading = true;
  String? _error;

  static const String apiBaseUrl = 'http://localhost:5000';
  final AuthService _authService = AuthService();
  String? _authToken;

  // Regional vaccine requirements with minimum doses needed
  final List<Map<String, dynamic>> regions = [
    {
      "name": "Sub-Saharan Africa",
      "icon": Icons.public,
      "color": Color(0xFFEF4444),
      "vaccines": [
        {"name": "Yellow Fever Vaccine", "minDoses": 1},
        {"name": "Typhoid Vaccine", "minDoses": 1},
        {"name": "Hepatitis A & B Vaccines", "minDoses": 2},
        {"name": "Meningococcal Vaccine", "minDoses": 1},
        {"name": "Rabies Pre-Exposure Vaccine", "minDoses": 3},
      ],
      "description":
          "Required and recommended vaccines for travel to Sub-Saharan African countries",
    },
    {
      "name": "South America",
      "icon": Icons.terrain,
      "color": Color(0xFF10B981),
      "vaccines": [
        {"name": "Yellow Fever Vaccine", "minDoses": 1},
        {"name": "Typhoid Vaccine", "minDoses": 1},
        {"name": "Hepatitis A & B Vaccines", "minDoses": 2},
        {"name": "Rabies Pre-Exposure Vaccine", "minDoses": 3},
      ],
      "description":
          "Essential vaccines for South American travel, especially Amazon regions",
    },
    {
      "name": "Southeast Asia",
      "icon": Icons.temple_buddhist,
      "color": Color(0xFFF59E0B),
      "vaccines": [
        {"name": "Typhoid Vaccine", "minDoses": 1},
        {"name": "Japanese Encephalitis Vaccine", "minDoses": 2},
        {"name": "Hepatitis A & B Vaccines", "minDoses": 2},
        {"name": "Rabies Pre-Exposure Vaccine", "minDoses": 3},
      ],
      "description":
          "Recommended vaccines for rural and urban areas in Southeast Asia",
    },
    {
      "name": "Middle East",
      "icon": Icons.mosque,
      "color": Color(0xFF8B5FBF),
      "vaccines": [
        {"name": "Meningococcal Vaccine", "minDoses": 1},
        {"name": "Typhoid Vaccine", "minDoses": 1},
        {"name": "Hepatitis A & B Vaccines", "minDoses": 2},
      ],
      "description":
          "Required for Hajj pilgrims and recommended for general travel",
    },
    {
      "name": "North America / Europe",
      "icon": Icons.location_city,
      "color": Color(0xFF3B82F6),
      "vaccines": [
        {"name": "Influenza (Flu) Vaccine", "minDoses": 1},
        {"name": "Meningococcal Vaccine", "minDoses": 1},
      ],
      "description": "Recommended for students and international travelers",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    await _loadAuthToken();
    if (_authToken != null && _authToken!.isNotEmpty) {
      await _fetchUserVaccines();
    } else {
      setState(() {
        _error = 'Please login to view travel vaccines';
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

  Future<void> _fetchUserVaccines() async {
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
          _userVaccines = data
              .map((json) => VaccineRecord.fromJson(json))
              .toList();
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

  // Check if user has a specific vaccine (completed or pending)
  VaccineRecord? _getUserVaccine(String vaccineName) {
    try {
      return _userVaccines.firstWhere(
        (v) => v.name.toLowerCase().contains(
          vaccineName.toLowerCase().split(' ')[0],
        ),
        orElse: () => throw Exception('Not found'),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _scheduleVaccine(
    VaccineRecord vaccine,
    DateTime selectedDate,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
      ),
    );

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/vaccines/schedule/${vaccine.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'nextDueDate': selectedDate.toIso8601String().split('T')[0],
        }),
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        await _fetchUserVaccines(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${vaccine.name} scheduled!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to schedule: ${response.body}'),
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

  void _showScheduleDialog(VaccineRecord vaccine) async {
    DateTime initial = DateTime.now().add(const Duration(days: 1));
    if (vaccine.nextDueDate != null) {
      try {
        DateTime parsedDate = DateTime.parse(vaccine.nextDueDate!);
        if (parsedDate.isAfter(DateTime.now())) {
          initial = parsedDate;
        }
      } catch (e) {
        // ignore parse error
      }
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B46C1),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B46C1),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      _scheduleVaccine(vaccine, pickedDate);
    }
  }

  void _showRegionDetails(Map<String, dynamic> region) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (region['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          region['icon'] as IconData,
                          color: region['color'] as Color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              region['name'] as String,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              region['description'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Vaccine list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: (region['vaccines'] as List).length,
                    itemBuilder: (context, index) {
                      final vaccineInfo =
                          (region['vaccines'] as List)[index]
                              as Map<String, dynamic>;
                      final vaccineName = vaccineInfo['name'] as String;
                      final minDoses = vaccineInfo['minDoses'] as int;
                      final userVaccine = _getUserVaccine(vaccineName);

                      return _buildVaccineStatusCard(
                        vaccineName,
                        minDoses,
                        userVaccine,
                        region['color'] as Color,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVaccineStatusCard(
    String vaccineName,
    int minDosesRequired,
    VaccineRecord? userVaccine,
    Color regionColor,
  ) {
    // Check if user has taken minimum required doses for THIS vaccine
    bool hasMinimumDoses = false;
    if (userVaccine != null) {
      hasMinimumDoses = userVaccine.completedDoses >= minDosesRequired;
    }

    bool isScheduled =
        userVaccine != null &&
        userVaccine.nextDueDate != null &&
        DateTime.parse(userVaccine.nextDueDate!).isAfter(DateTime.now()) &&
        !hasMinimumDoses; // Don't show scheduled if already has minimum doses
    bool isNotInRecords = userVaccine == null;

    IconData statusIcon;
    Color statusColor;
    String statusText;
    Widget? actionButton;

    // Show green if minimum doses are met
    if (hasMinimumDoses) {
      statusIcon = Icons.check_circle;
      statusColor = const Color(0xFF10B981);

      if (userVaccine!.isCompleted) {
        statusText = 'Completed - ${userVaccine.doseDisplay}';
      } else {
        // Has minimum but not fully complete
        statusText =
            'Ready for travel (${userVaccine.completedDoses}/${userVaccine.totalDoses ?? '?'} doses taken)';
        actionButton = TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _showScheduleDialog(userVaccine);
          },
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text('Complete Series'),
          style: TextButton.styleFrom(foregroundColor: statusColor),
        );
      }
    } else if (isScheduled) {
      statusIcon = Icons.event_available;
      statusColor = Colors.blue;
      statusText =
          'Scheduled: ${DateFormat.yMMMd().format(DateTime.parse(userVaccine.nextDueDate!))}';
      actionButton = TextButton.icon(
        onPressed: () {
          Navigator.pop(context);
          _showScheduleDialog(userVaccine);
        },
        icon: const Icon(Icons.edit_calendar, size: 18),
        label: const Text('Reschedule'),
        style: TextButton.styleFrom(foregroundColor: regionColor),
      );
    } else if (isNotInRecords) {
      statusIcon = Icons.info_outline;
      statusColor = Colors.orange;
      statusText = 'Not in your records';
    } else {
      statusIcon = Icons.schedule;
      statusColor = Colors.orange;
      statusText = 'Not scheduled';
      actionButton = ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          _showScheduleDialog(userVaccine);
        },
        icon: const Icon(Icons.calendar_today, size: 18),
        label: const Text('Schedule'),
        style: ElevatedButton.styleFrom(
          backgroundColor: regionColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaccineName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actionButton != null) ...[
            const SizedBox(height: 12),
            actionButton,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Travel Vaccines"),
        backgroundColor: const Color(0xFF8B5FBF),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchUserVaccines,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
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
                'Error loading data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchUserVaccines,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5FBF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUserVaccines,
      color: const Color(0xFF8B5FBF),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: regions.length,
        itemBuilder: (context, index) {
          final region = regions[index];
          final regionVaccines = region['vaccines'] as List;

          // Calculate completion status based on minimum required doses
          int completed = 0;
          for (var vaccineInfo in regionVaccines) {
            final vaccineName = vaccineInfo['name'] as String;
            final minDoses = vaccineInfo['minDoses'] as int;
            final userVaccine = _getUserVaccine(vaccineName);

            // Check if user has taken minimum required doses for this vaccine
            if (userVaccine != null && userVaccine.completedDoses >= minDoses) {
              completed++;
            }
          }

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: InkWell(
              onTap: () => _showRegionDetails(region),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (region['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        region['icon'] as IconData,
                        color: region['color'] as Color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            region['name'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${regionVaccines.length} vaccines required',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: completed / regionVaccines.length,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              region['color'] as Color,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completed of ${regionVaccines.length} completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
