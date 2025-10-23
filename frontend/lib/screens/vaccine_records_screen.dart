// lib/screens/vaccine_records_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/vaccine_record.dart';

class VaccineRecordsScreen extends StatefulWidget {
  const VaccineRecordsScreen({super.key});

  @override
  State<VaccineRecordsScreen> createState() => _VaccineRecordsScreenState();
}

class _VaccineRecordsScreenState extends State<VaccineRecordsScreen> {
  List<VaccineRecord> _allVaccines = [];
  bool _isLoading = true;
  String? _error;
  bool _showPending = true; // Toggle state: true = pending, false = completed

  // Use http://10.0.2.2:5000 for Android Emulator
  // Use http://localhost:5000 for iOS Simulator or Web
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
        _error = 'Please login to view your records';
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
        setState(() {
          _allVaccines = data
              .map((json) => VaccineRecord.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              'Failed to load vaccines: ${response.statusCode} - ${response.body}';
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
          // Format as YYYY-MM-DD
          'nextDueDate': selectedDate.toIso8601String().split('T')[0],
        }),
      );
      Navigator.pop(context); // Close loading dialog
      if (response.statusCode == 200) {
        await _fetchVaccines(); // Refresh the list
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
        // Ensure initial date is not in the past
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
      firstDate: DateTime.now(), // Can't schedule for the past
      lastDate: DateTime.now().add(
        const Duration(days: 365 * 5),
      ), // 5 years out
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B46C1), // Header background
              onPrimary: Colors.white, // Header text
              onSurface: Colors.black, // Calendar text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B46C1), // Button text
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // User picked a date, now call the API
      _scheduleVaccine(vaccine, pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Create the two "display" lists based on your logic ---
    final List<VaccineRecord> completedDisplayList = [];
    final List<VaccineRecord> pendingDisplayList = [];

    for (final record in _allVaccines) {
      if (record.isCompleted) {
        // If the whole series is done, just add it to completed
        completedDisplayList.add(record);
      } else {
        // It's pending. Add the *next* dose to the pending list.
        pendingDisplayList.add(record);

        // NOW, check if it has a "completed part" to show
        final completedPart = record.completedPart;
        if (completedPart != null) {
          // Add the fake "Dose 1" to the completed list
          completedDisplayList.add(completedPart);
        }
      }
    }
    // --- End of list processing ---

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF553C9A),
              Color(0xFF8B5FBF),
              Color(0xFFB794F6),
              Color(0xFFD6BCFA),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
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
                      'Vaccine Records',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _isLoading ? null : _fetchVaccines,
                    ),
                  ],
                ),
              ),

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
                  child: Column(
                    children: [
                      // Toggle Button
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _showPending = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _showPending
                                          ? const Color(0xFF8B5FBF)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          color: _showPending
                                              ? Colors.white
                                              : Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pending (${pendingDisplayList.length})',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _showPending
                                                ? Colors.white
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _showPending = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !_showPending
                                          ? const Color(0xFF10B981)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: !_showPending
                                              ? Colors.white
                                              : Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Completed (${completedDisplayList.length})',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: !_showPending
                                                ? Colors.white
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Content
                      Expanded(
                        child: _buildContent(
                          completedDisplayList,
                          pendingDisplayList,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    List<VaccineRecord> completed,
    List<VaccineRecord> pending,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF553C9A)),
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
                'Error loading records',
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
                onPressed: _fetchVaccines,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF553C9A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (pending.isEmpty && completed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vaccines_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No records found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your vaccination records will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchVaccines,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Records'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF553C9A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchVaccines,
      color: const Color(0xFF553C9A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show pending or completed based on toggle
            if (_showPending) ...[
              if (pending.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Pending Vaccines',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All your vaccines are up to date!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...pending.map((vaccine) => _buildPendingCard(vaccine)),
            ] else ...[
              if (completed.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.vaccines_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Completed Vaccines',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completed vaccines will appear here.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...completed.map((vaccine) => _buildCompletedCard(vaccine)),
            ],
          ],
        ),
      ),
    );
  }

  // CARD FOR PENDING VACCINES (with Schedule button)
  Widget _buildPendingCard(VaccineRecord vaccine) {
    // Check if scheduled (has a future date)
    final bool isScheduled =
        vaccine.nextDueDate != null &&
        DateTime.parse(vaccine.nextDueDate!).isAfter(DateTime.now());

    // Check if due (has a past date and is not completed)
    final bool isDue =
        vaccine.nextDueDate != null && !isScheduled && vaccine.isPending;

    String dateText;
    Color dateColor;
    IconData dateIcon;

    if (isScheduled) {
      dateText =
          'Scheduled: ${DateFormat.yMMMd().format(DateTime.parse(vaccine.nextDueDate!))}';
      dateColor = Colors.blue.shade700;
      dateIcon = Icons.event_available;
    } else if (isDue) {
      dateText =
          'Overdue: ${DateFormat.yMMMd().format(DateTime.parse(vaccine.nextDueDate!))}';
      dateColor = Colors.red.shade700;
      dateIcon = Icons.error_outline;
    } else {
      dateText = 'Not Scheduled';
      dateColor = Colors.orange.shade700;
      dateIcon = Icons.event_busy;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.3)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(dateIcon, color: dateColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vaccine.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              vaccine.doseDisplay, // This will show "Dose 2 of 2"
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              dateText,
              style: TextStyle(
                fontSize: 14,
                color: dateColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(height: 24),
            // "Schedule" Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showScheduleDialog(vaccine),
                icon: Icon(
                  isScheduled || isDue
                      ? Icons.edit_calendar_outlined
                      : Icons.calendar_today,
                ),
                label: Text(
                  isScheduled || isDue ? 'Reschedule' : 'Schedule Now',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5FBF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CARD FOR COMPLETED VACCINES (Read-only)
  Widget _buildCompletedCard(VaccineRecord vaccine) {
    String dateText = 'Date not recorded';
    // Use lastDoseDate first
    final completionDate = vaccine.lastDoseDate;
    if (completionDate != null) {
      try {
        dateText =
            'Completed: ${DateFormat.yMMMd().format(DateTime.parse(completionDate))}';
      } catch (e) {
        dateText = 'Completed: $completionDate';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 4),
                  Text(
                    vaccine.doseDisplay, // This will show "Dose 1 of 2 - Taken"
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateText,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
