// lib/screens/vaccine_records_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/vaccine_record.dart';

// --- NEW IMPORT ---
import 'vaccine_certificate_screen.dart'; // Import the new screen

class VaccineRecordsScreen extends StatefulWidget {
  const VaccineRecordsScreen({super.key});

  @override
  State<VaccineRecordsScreen> createState() => _VaccineRecordsScreenState();
}

class _VaccineRecordsScreenState extends State<VaccineRecordsScreen> {
  List<VaccineRecord> _allVaccines = [];
  bool _isLoading = true;
  String? _error;
  bool _showPending = true;

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
          'nextDueDate': selectedDate.toIso8601String().split('T')[0],
        }),
      );
      Navigator.pop(context);
      if (response.statusCode == 200) {
        await _fetchVaccines();
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

  // ✅ NEW METHOD: Mark vaccine as already taken
  Future<void> _markVaccineAsTaken(
    VaccineRecord vaccine,
    int dosesCompleted,
    DateTime dateTaken,
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
        Uri.parse('$apiBaseUrl/api/vaccines/mark-taken/${vaccine.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'dosesCompleted': dosesCompleted,
          'dateTaken': dateTaken.toIso8601String().split('T')[0],
        }),
      );
      Navigator.pop(context);
      if (response.statusCode == 200) {
        await _fetchVaccines();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${vaccine.name} marked as taken!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to mark as taken: ${response.body}'),
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

  // ✅ NEW METHOD: Show dialog to mark as taken
  void _showMarkAsTakenDialog(VaccineRecord vaccine) {
    int selectedDoses = 1;
    String selectedDateOption = 'specific';
    DateTime selectedSpecificDate = DateTime.now().subtract(
      const Duration(days: 7),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Calculate date based on range selection
          DateTime getDateFromRange(String range) {
            final now = DateTime.now();
            switch (range) {
              case '0-1':
                return now.subtract(Duration(days: 15));
              case '2-4':
                return now.subtract(Duration(days: 90));
              case '4-6':
                return now.subtract(Duration(days: 150));
              case '6-12':
                return now.subtract(Duration(days: 270));
              case '1-2y':
                return now.subtract(Duration(days: 540));
              case '2+y':
                return now.subtract(Duration(days: 900));
              default:
                return selectedSpecificDate;
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.history, color: Color(0xFF8B5FBF)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mark as Already Taken',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vaccine.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Dose Selection
                  Text(
                    'How many doses have you completed?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF8B5FBF)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: selectedDoses,
                      isExpanded: true,
                      underline: SizedBox(),
                      items: List.generate(
                        vaccine.totalDoses ?? 1,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text(
                            vaccine.totalDoses != null
                                ? 'Dose ${index + 1} of ${vaccine.totalDoses}'
                                : 'Dose ${index + 1}',
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDoses = value!;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 20),

                  // Date Selection
                  Text(
                    'When did you take it?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),

                  // Date Option Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() {
                              selectedDateOption = 'specific';
                            }),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedDateOption == 'specific'
                                    ? Color(0xFF8B5FBF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Specific Date',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selectedDateOption == 'specific'
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() {
                              selectedDateOption = 'range';
                            }),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedDateOption == 'range'
                                    ? Color(0xFF8B5FBF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Time Range',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selectedDateOption == 'range'
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),

                  // Specific Date Picker
                  if (selectedDateOption == 'specific')
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedSpecificDate,
                          firstDate: DateTime.now().subtract(
                            Duration(days: 365 * 10),
                          ),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Color(0xFF6B46C1),
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedSpecificDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF8B5FBF)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Color(0xFF8B5FBF),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              DateFormat.yMMMd().format(selectedSpecificDate),
                              style: TextStyle(fontSize: 14),
                            ),
                            Spacer(),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF8B5FBF),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Range Selection
                  if (selectedDateOption == 'range')
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF8B5FBF)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: '2-4',
                        isExpanded: true,
                        underline: SizedBox(),
                        items: [
                          DropdownMenuItem(
                            value: '0-1',
                            child: Text('0-1 month ago'),
                          ),
                          DropdownMenuItem(
                            value: '2-4',
                            child: Text('2-4 months ago'),
                          ),
                          DropdownMenuItem(
                            value: '4-6',
                            child: Text('4-6 months ago'),
                          ),
                          DropdownMenuItem(
                            value: '6-12',
                            child: Text('6-12 months ago'),
                          ),
                          DropdownMenuItem(
                            value: '1-2y',
                            child: Text('1-2 years ago'),
                          ),
                          DropdownMenuItem(
                            value: '2+y',
                            child: Text('2+ years ago'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDateOption = value!;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  final dateToUse = selectedDateOption == 'specific'
                      ? selectedSpecificDate
                      : getDateFromRange(selectedDateOption);
                  _markVaccineAsTaken(vaccine, selectedDoses, dateToUse);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B5FBF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
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

  // --- NEW NAVIGATION METHOD ---
  void _navigateToCertificateScreen(VaccineRecord vaccine) {
    // We pass the whole vaccine record, which includes the list of certificates
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VaccineCertificateScreen(vaccine: vaccine),
      ),
    ).then((_) {
      // This runs when we come BACK from the certificate screen.
      // We should refresh the data in case a file was uploaded.
      _fetchVaccines();
    });
  }
  // -------------------------

  @override
  Widget build(BuildContext context) {
    final List<VaccineRecord> completedDisplayList = [];
    final List<VaccineRecord> pendingDisplayList = [];

    for (final record in _allVaccines) {
      if (record.isCompleted) {
        completedDisplayList.add(record);
      } else {
        pendingDisplayList.add(record);
        final completedPart = record.completedPart;
        if (completedPart != null) {
          completedDisplayList.add(completedPart);
        }
      }
    }

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

  //
  // --- UPDATED: PENDING CARD ---
  //
  Widget _buildPendingCard(VaccineRecord vaccine) {
    final bool isScheduled =
        vaccine.nextDueDate != null &&
        DateTime.tryParse(vaccine.nextDueDate!)?.isAfter(DateTime.now()) ==
            true;

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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToCertificateScreen(vaccine),
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
                        if (vaccine.certificates.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${vaccine.certificates.length} Certificate(s)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                vaccine.doseDisplay,
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
              Row(
                children: [
                  // Schedule Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showScheduleDialog(vaccine),
                      icon: Icon(
                        isScheduled || isDue
                            ? Icons.edit_calendar_outlined
                            : Icons.calendar_today,
                        size: 18,
                      ),
                      label: Text(
                        isScheduled || isDue ? 'Reschedule' : 'Schedule',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5FBF),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Mark as Taken Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMarkAsTakenDialog(vaccine),
                      icon: Icon(Icons.history, size: 18),
                      label: Text(
                        'Already Taken',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5FBF),
                        side: BorderSide(color: const Color(0xFF8B5FBF)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //
  // --- UPDATED: COMPLETED CARD ---
  //
  Widget _buildCompletedCard(VaccineRecord vaccine) {
    String dateText = 'Date not recorded';
    final completionDate = vaccine.lastDoseDate;
    if (completionDate != null) {
      try {
        dateText =
            'Completed: ${DateFormat.yMMMd().format(DateTime.parse(completionDate))}';
      } catch (e) {
        dateText = 'Completed: $completionDate';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToCertificateScreen(vaccine),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 28,
                    ),
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
                          if (vaccine.certificates.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.attach_file,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${vaccine.certificates.length} Certificate(s)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  vaccine.doseDisplay,
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
        ),
      ),
    );
  }
}
