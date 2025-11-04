// lib/screens/vaccine_records_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/vaccine_record.dart';
import 'vaccine_certificate_screen.dart';

// ✅ NEW: Minimal model to hold brand data fetched for the dialog
class _Brand {
  final int id;
  final String brandName;
  final int numberOfDoses;

  _Brand({
    required this.id,
    required this.brandName,
    required this.numberOfDoses,
  });

  factory _Brand.fromJson(Map<String, dynamic> json) {
    return _Brand(
      id: json['id'],
      brandName: json['brandName'] ?? 'Unknown Brand',
      numberOfDoses: json['numberOfDoses'] ?? 1,
    );
  }
}

// ✅ NEW: Add the enum definition here
enum _DateInputType { specific, range }
enum _DisplayCategory { pending, completed, booster }

class VaccineRecordsScreen extends StatefulWidget {
  const VaccineRecordsScreen({super.key});

  @override
  State<VaccineRecordsScreen> createState() => _VaccineRecordsScreenState();
}

class _VaccineRecordsScreenState extends State<VaccineRecordsScreen> {
  List<VaccineRecord> _allVaccines = [];
  bool _isLoading = true;
  String? _error;
  // bool _showPending = true;
  _DisplayCategory _selectedCategory = _DisplayCategory.pending;

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
          _allVaccines =
              data.map((json) => VaccineRecord.fromJson(json)).toList();
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
    if (!mounted) return;

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

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        await _fetchVaccines();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${vaccine.name} scheduled!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule: ${response.body}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ UPDATED METHOD: Mark vaccine as already taken
  Future<void> _markVaccineAsTaken(
    VaccineRecord vaccine, {
    required int dosesCompleted,
    required DateTime dateTaken,
    required bool markAllAsCompleted,
    int? brandId,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
      ),
    );

    try {
      // ✅ Build the request body
      final Map<String, dynamic> requestBody = {
        // ✅ Send the full ISO string, though backend only uses the date part for now
        'dateTaken': dateTaken.toIso8601String().split('T')[0],
        'markAllAsCompleted': markAllAsCompleted,
        'dosesCompleted': dosesCompleted, // Send anyway
      };
      if (brandId != null) {
        requestBody['brandId'] = brandId;
      }

      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/vaccines/mark-taken/${vaccine.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode(requestBody),
      );
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        await _fetchVaccines();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${vaccine.name} marked as taken!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // ✅ Handle specific errors from the backend
        String errorMessage = 'Failed to mark as taken';
        try {
          final data = json.decode(response.body);
          if (data['message'] != null) {
            errorMessage = data['message'];
          } else {
            errorMessage = response.body;
          }
        } catch (_) {
          errorMessage = response.body;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ COMPLETELY REBUILT METHOD: Show dialog to mark as taken
  // ✅ COMPLETELY REBUILT METHOD: Show dialog to mark as taken
  void _showMarkAsTakenDialog(VaccineRecord vaccine) {
    // --- NEW: Enum for date input type ---
    // enum _DateInputType { specific, range }

    // --- Dialog State ---
    int selectedDoses = 1;
    // MODIFICATION: Initialize with a clean date (noon)
    DateTime selectedSpecificDate = DateUtils.dateOnly(
            DateTime.now().subtract(const Duration(days: 7)))
        .add(const Duration(hours: 12));
    bool markAllDoses = false;

    // --- NEW: State for approximate date ---
    _DateInputType _dateInputType = _DateInputType.specific;
    String? _selectedRange;
    final List<String> _dateRanges = const [
      '2-4 months ago',
      '6 months ago',
      '1 year ago',
      '2+ years ago'
    ];
    // ---

    // Brand state
    List<_Brand> availableBrands = [];
    _Brand? selectedBrand;
    bool isBrandLoading = true;
    bool brandFetchFailed = false;

    // This tracks the *actual* total doses based on brand selection
    int totalDosesForDisplay = vaccine.totalDoses ?? 1;
    // --- End Dialog State ---

    // --- NEW: Helper function to calculate date from range ---
    DateTime _calculateDateFromRange(String range) {
      final now = DateTime.now();
      switch (range) {
        case '2-4 months ago':
          // Approximates as 3 months ago
          return now.subtract(const Duration(days: 3 * 30));
        case '6 months ago':
          // Approximates as 6 months ago
          return now.subtract(const Duration(days: 6 * 30));
        case '1 year ago':
          return now.subtract(const Duration(days: 365));
        case '2+ years ago':
          // Approximates as 2 years ago
          return now.subtract(const Duration(days: 2 * 365));
        default:
          return now;
      }
    }

    // Function to fetch brands for this specific user vaccine record
    Future<void> fetchBrands(StateSetter setDialogState) async {
      try {
        setDialogState(() {
          isBrandLoading = true;
          brandFetchFailed = false;
        });

        // UPDATED API CALL
        final res = await http.get(
          Uri.parse(
              '$apiBaseUrl/api/vaccines/brands/for-user-vaccine/${vaccine.id}'),
          headers: {'Authorization': 'Bearer $_authToken'},
        );

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final brandList = (data['brands'] as List? ?? [])
              .map((json) => _Brand.fromJson(json))
              .toList();

          setDialogState(() {
            availableBrands = brandList;
            isBrandLoading = false;
            // If brands exist, pre-select the first one
            if (availableBrands.isNotEmpty) {
              selectedBrand = availableBrands.first;
              totalDosesForDisplay = selectedBrand!.numberOfDoses;
              selectedDoses = 1; // Reset doses
            } else {
              // No brands, use the generic vaccine's dose count
              totalDosesForDisplay = vaccine.totalDoses ?? 1;
            }
          });
        } else {
          setDialogState(() {
            isBrandLoading = false;
            brandFetchFailed = true;
          });
        }
      } catch (_) {
        if (mounted) {
          setDialogState(() {
            isBrandLoading = false;
            brandFetchFailed = true;
          });
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Fetch brands *once* when the dialog builds
          if (isBrandLoading && !brandFetchFailed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              fetchBrands(setDialogState);
            });
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.history, color: Color(0xFF8B5FBF)),
                SizedBox(width: 8),
                Expanded(
                    child: Text('Mark as Already Taken',
                        style: TextStyle(fontSize: 18))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Vaccine name
                  Text(
                    vaccine.name,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748)),
                  ),
                  SizedBox(height: 20),

                  /// BRAND DROPDOWN
                  if (isBrandLoading)
                    Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF8B5FBF))),

                  if (!isBrandLoading && brandFetchFailed)
                    Center(
                        child: Text('Failed to load brands.',
                            style: TextStyle(color: Colors.red))),

                  // Only show brand dropdown if brands are available
                  if (!isBrandLoading && availableBrands.isNotEmpty) ...[
                    Text(
                      'Select Brand:*',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800]),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF8B5FBF)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<_Brand>(
                        value: selectedBrand,
                        isExpanded: true,
                        underline: SizedBox.shrink(),
                        items: availableBrands.map((brand) {
                          return DropdownMenuItem(
                            value: brand,
                            child: Text(
                              '${brand.brandName} (${brand.numberOfDoses} doses)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedBrand = value;
                            // Update total doses based on brand selection
                            totalDosesForDisplay =
                                value?.numberOfDoses ?? (vaccine.totalDoses ?? 1);
                            // Reset selected doses if it's now invalid
                            if (selectedDoses > totalDosesForDisplay) {
                              selectedDoses = totalDosesForDisplay;
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                  ],

                  /// "ALL DOSES" CHECKBOX
                  // (This logic is already correct as per your request)
                  CheckboxListTile(
                    title: Text(
                      'All doses of this vaccine are taken',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800]),
                    ),
                    value: markAllDoses,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        markAllDoses = value ?? false;
                        if (markAllDoses) {
                          // If "all" is checked, set doses to max
                          selectedDoses = totalDosesForDisplay;
                        } else {
                          // If unchecked, reset to 1
                          selectedDoses = 1;
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: Color(0xFF8B5FBF),
                  ),
                  SizedBox(height: 12),

                  /// DOSE DROPDOWN
                  // Disable dropdown if "all doses" is checked
                  IgnorePointer(
                    ignoring: markAllDoses,
                    child: Opacity(
                      opacity: markAllDoses ? 0.5 : 1.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How many doses have you completed?',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800]),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF8B5FBF)),
                              borderRadius: BorderRadius.circular(8),
                              color: markAllDoses
                                  ? Colors.grey[200]
                                  : Colors.white,
                            ),
                            child: DropdownButton<int>(
                              value: selectedDoses,
                              isExpanded: true,
                              underline: SizedBox.shrink(),
                              // Use dynamic totalDosesForDisplay
                              items: List.generate(
                                totalDosesForDisplay,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text(
                                      'Dose ${i + 1} of $totalDosesForDisplay'),
                                ),
                              ),
                              onChanged: (v) =>
                                  setDialogState(() => selectedDoses = v!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  /// --- NEW: DATE INPUT SECTION ---
                  Text(
                    'When did you take the *last* dose?',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800]),
                  ),
                  SizedBox(height: 8),
                  // --- NEW: Toggle Buttons ---
                  ToggleButtons(
                    isSelected: [
                      _dateInputType == _DateInputType.specific,
                      _dateInputType == _DateInputType.range,
                    ],
                    onPressed: (index) {
                      setDialogState(() {
                        _dateInputType = index == 0
                            ? _DateInputType.specific
                            : _DateInputType.range;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: Color(0xFF8B5FBF),
                    color: Color(0xFF8B5FBF),
                    borderColor: Color(0xFF8B5FBF),
                    selectedBorderColor: Color(0xFF8B5FBF),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Specific Date'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Approx. Range'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // --- NEW: Conditional Input ---
                  if (_dateInputType == _DateInputType.specific)
                    // 1. Specific Date/Time Picker
                    GestureDetector(
                      onTap: () async {
                        // 1. Pick Date
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedSpecificDate,
                          firstDate: DateTime(1900), // Allow historical dates
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate == null) return; // User canceled date
                        if (!context.mounted) return;

                        // 2. Pick Time
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay.fromDateTime(selectedSpecificDate),
                        );

                        // 3. Combine Date and Time
                        // If user cancels time, default to 12:00 PM (noon)
                        final time =
                            pickedTime ?? const TimeOfDay(hour: 12, minute: 0);

                        setDialogState(() {
                          selectedSpecificDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF8B5FBF)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: Color(0xFF8B5FBF), size: 20),
                            SizedBox(width: 12),
                            // MODIFICATION: Format to show date and time
                            Text(DateFormat.yMMMd()
                                .add_jm()
                                .format(selectedSpecificDate)),
                            Spacer(),
                            Icon(Icons.arrow_drop_down,
                                color: Color(0xFF8B5FBF)),
                          ],
                        ),
                      ),
                    )
                  else
                    // 2. Approximate Range Dropdown
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF8B5FBF)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRange,
                        hint: Text('Select a time range'),
                        isExpanded: true,
                        underline: SizedBox.shrink(),
                        items: _dateRanges.map((range) {
                          return DropdownMenuItem(
                            value: range,
                            child: Text(range),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedRange = value;
                          });
                        },
                      ),
                    ),
                  // --- END OF NEW DATE SECTION ---
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    Text('Cancel', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () async {
                  // --- NEW: Date validation and selection logic ---
                  DateTime dateToSend;

                  if (_dateInputType == _DateInputType.specific) {
                    dateToSend = selectedSpecificDate;
                  } else {
                    // It's a range, check if one was selected
                    if (_selectedRange == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Please select an approximate time range.'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return; // Stop submission
                    }
                    dateToSend = _calculateDateFromRange(_selectedRange!);
                  }
                  // ---

                  // Validation: If brands exist, one must be selected
                  if (availableBrands.isNotEmpty && selectedBrand == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Please select a brand for this vaccine.'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context); // Close dialog

                  // Call updated method with all parameters
                  await _markVaccineAsTaken(
                    vaccine,
                    dosesCompleted: selectedDoses,
                    dateTaken: dateToSend, // ✅ Use the new date logic
                    markAllAsCompleted: markAllDoses,
                    brandId: selectedBrand?.id,
                  );
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

  // ✅ NEW: Helper widget for empty states
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTab(
    BuildContext context, {
    required String text,
    required IconData icon,
    required _DisplayCategory category,
    required Color activeColor,
  }) {
    final bool isActive = _selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ NEW: Add a third list for boosters
    final List<VaccineRecord> completedDisplayList = [];
    final List<VaccineRecord> pendingDisplayList = [];
    final List<VaccineRecord> boosterDisplayList = [];

    // ✅ NEW: This logic sorts into all 3 lists
    for (final record in _allVaccines) {
      if (record.isCompleted) {
        // This is a fully completed, non-recurring vaccine.
        completedDisplayList.add(record);
      } else {
        // This is PENDING (status != 'completed')

        // Check for its "completed" part (for partials/boosters)
        final completedPart = record.completedPart;
        if (completedPart != null) {
          completedDisplayList.add(completedPart);
        }

        // Now, sort the *pending* record itself
        bool isBooster = record.totalDoses != null &&
            record.completedDoses >= record.totalDoses!;

        if (isBooster) {
          boosterDisplayList.add(record);
        } else {
          pendingDisplayList.add(record);
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
                      // --- THIS IS THE TOGGLE BAR SECTION ---
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildToggleTab(
                                context,
                                text: 'Pending (${pendingDisplayList.length})',
                                icon: Icons.schedule,
                                category: _DisplayCategory.pending,
                                activeColor: const Color(0xFF8B5FBF),
                              ),
                              _buildToggleTab(
                                context,
                                text: 'Booster (${boosterDisplayList.length})',
                                icon: Icons.health_and_safety_outlined,
                                category: _DisplayCategory.booster,
                                activeColor: const Color(0xFF3182CE),
                              ),
                              _buildToggleTab(
                                context,
                                text: 'Completed (${completedDisplayList.length})',
                                icon: Icons.check_circle,
                                category: _DisplayCategory.completed,
                                activeColor: const Color(0xFF10B981),
                              ),
                            ], // ⬅️ Row's children END here
                          ),
                        ),
                      ), // ⬅️ Padding (for toggles) ENDS here

                      // --- ✅ CORRECTED: ---
                      // The Expanded content starts HERE,
                      // as the *next* child of the Column.
                      Expanded(
                        child: _buildContent(
                          completedDisplayList,
                          pendingDisplayList,
                          boosterDisplayList,
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
    List<VaccineRecord> boosters,
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
            // This switch statement displays the correct list
            // based on the _selectedCategory state
            Builder(
              builder: (context) {
                switch (_selectedCategory) {
                  case _DisplayCategory.pending:
                    if (pending.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'No Pending Vaccines',
                        message: 'All your vaccines are up to date!',
                      );
                    }
                    return Column(
                      children: pending
                          .map((vaccine) => _buildPendingCard(vaccine))
                          .toList(),
                    );
                  
                  case _DisplayCategory.booster:
                    if (boosters.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.shield_outlined,
                        title: 'No Boosters Due',
                        message: 'Your upcoming boosters will appear here.',
                      );
                    }
                    // Boosters use the same card as pending
                    return Column(
                      children: boosters
                          .map((vaccine) => _buildPendingCard(vaccine))
                          .toList(),
                    );
                  
                  case _DisplayCategory.completed:
                    if (completed.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.vaccines_outlined,
                        title: 'No Completed Vaccines',
                        message: 'Completed vaccines will appear here.',
                      );
                    }
                    return Column(
                      children: completed
                          .map((vaccine) => _buildCompletedCard(vaccine))
                          .toList(),
                    );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  // --- PENDING CARD (No changes needed) ---

  Widget _buildPendingCard(VaccineRecord vaccine) {
    final bool isScheduled = vaccine.nextDueDate != null &&
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
  // --- COMPLETED CARD (No changes needed) ---
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