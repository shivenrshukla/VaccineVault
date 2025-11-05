// lib/screens/vaccine_records_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/vaccine_record.dart';
import 'vaccine_certificate_screen.dart';

// Minimal model to hold brand data fetched for the dialog
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

enum _DateInputType { specific, range }

// Added 'situational' category
enum _DisplayCategory { pending, completed, booster, situational }

// Rabies Exposure Categories
enum _RabiesCategory { catII, catIII }

class VaccineRecordsScreen extends StatefulWidget {
  const VaccineRecordsScreen({super.key});

  @override
  State<VaccineRecordsScreen> createState() => _VaccineRecordsScreenState();
}

class _VaccineRecordsScreenState extends State<VaccineRecordsScreen> {
  List<VaccineRecord> _allVaccines = [];
  bool _isLoading = true;
  String? _error;
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

  // ✅ NEW: Call backend to generate the actual schedule
  Future<void> _createRabiesSchedule({
    required DateTime exposureDate,
    required bool isImmunized,
    required _RabiesCategory category,
  }) async {
    // 1. Show loading
    if (!mounted) return;
    Navigator.pop(context); // Close the assessment dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      // 2. Call Backend
      // NOTE: You need to implement this endpoint on your backend!
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/vaccines/situational/schedule-rabies'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'exposureDate': exposureDate.toIso8601String().split('T')[0],
          'isPreviouslyImmunized': isImmunized,
          'exposureCategory': category.name, // 'catII' or 'catIII'
        }),
      );

      // 3. Handle Response
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Rabies schedule created successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // 4. Switch to Pending tab to show new doses
        setState(() {
          _selectedCategory = _DisplayCategory.pending;
        });
        _fetchVaccines(); // Reload data
      } else {
        throw Exception('Failed to create schedule: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
      final Map<String, dynamic> requestBody = {
        'dateTaken': dateTaken.toIso8601String().split('T')[0],
        'markAllAsCompleted': markAllAsCompleted,
        'dosesCompleted': dosesCompleted,
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
      Navigator.pop(context);

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
      Navigator.pop(context);

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

  void _showMarkAsTakenDialog(VaccineRecord vaccine) {
    int selectedDoses = 1;
    DateTime selectedSpecificDate = DateUtils.dateOnly(
      DateTime.now().subtract(const Duration(days: 7)),
    ).add(const Duration(hours: 12));
    bool markAllDoses = false;

    _DateInputType dateInputType = _DateInputType.specific;
    String? selectedRange;
    final List<String> dateRanges = const [
      '2-4 months ago',
      '6 months ago',
      '1 year ago',
      '2+ years ago',
    ];

    List<_Brand> availableBrands = [];
    _Brand? selectedBrand;
    bool isBrandLoading = true;
    bool brandFetchFailed = false;

    int totalDosesForDisplay = vaccine.totalDoses ?? 1;

    DateTime calculateDateFromRange(String range) {
      final now = DateTime.now();
      switch (range) {
        case '2-4 months ago':
          return now.subtract(const Duration(days: 3 * 30));
        case '6 months ago':
          return now.subtract(const Duration(days: 6 * 30));
        case '1 year ago':
          return now.subtract(const Duration(days: 365));
        case '2+ years ago':
          return now.subtract(const Duration(days: 2 * 365));
        default:
          return now;
      }
    }

    Future<void> fetchBrands(StateSetter setDialogState) async {
      try {
        setDialogState(() {
          isBrandLoading = true;
          brandFetchFailed = false;
        });

        final res = await http.get(
          Uri.parse(
            '$apiBaseUrl/api/vaccines/brands/for-user-vaccine/${vaccine.id}',
          ),
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
            if (availableBrands.isNotEmpty) {
              selectedBrand = availableBrands.first;
              totalDosesForDisplay = selectedBrand!.numberOfDoses;
              selectedDoses = 1;
            } else {
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
          if (isBrandLoading && !brandFetchFailed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              fetchBrands(setDialogState);
            });
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  if (isBrandLoading)
                    Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B5FBF),
                      ),
                    ),
                  if (!isBrandLoading && brandFetchFailed)
                    Center(
                      child: Text(
                        'Failed to load brands.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  if (!isBrandLoading && availableBrands.isNotEmpty) ...[
                    Text(
                      'Select Brand:*',
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
                            totalDosesForDisplay =
                                value?.numberOfDoses ??
                                (vaccine.totalDoses ?? 1);
                            if (selectedDoses > totalDosesForDisplay) {
                              selectedDoses = totalDosesForDisplay;
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                  CheckboxListTile(
                    title: Text(
                      'All doses of this vaccine are taken',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    value: markAllDoses,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        markAllDoses = value ?? false;
                        if (markAllDoses) {
                          selectedDoses = totalDosesForDisplay;
                        } else {
                          selectedDoses = 1;
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: Color(0xFF8B5FBF),
                  ),
                  SizedBox(height: 12),
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
                              color: Colors.grey[800],
                            ),
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
                              items: List.generate(
                                totalDosesForDisplay,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text(
                                    'Dose ${i + 1} of $totalDosesForDisplay',
                                  ),
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
                  Text(
                    'When did you take the *last* dose?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  ToggleButtons(
                    isSelected: [
                      dateInputType == _DateInputType.specific,
                      dateInputType == _DateInputType.range,
                    ],
                    onPressed: (index) {
                      setDialogState(() {
                        dateInputType = index == 0
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
                  if (dateInputType == _DateInputType.specific)
                    GestureDetector(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedSpecificDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate == null) return;
                        if (!context.mounted) return;

                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            selectedSpecificDate,
                          ),
                        );

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
                            Icon(
                              Icons.calendar_today,
                              color: Color(0xFF8B5FBF),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              DateFormat.yMMMd().add_jm().format(
                                selectedSpecificDate,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF8B5FBF),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF8B5FBF)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedRange,
                        hint: Text('Select a time range'),
                        isExpanded: true,
                        underline: SizedBox.shrink(),
                        items: dateRanges.map((range) {
                          return DropdownMenuItem(
                            value: range,
                            child: Text(range),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedRange = value;
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
                onPressed: () async {
                  DateTime dateToSend;
                  if (dateInputType == _DateInputType.specific) {
                    dateToSend = selectedSpecificDate;
                  } else {
                    if (selectedRange == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select an approximate time range.',
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    dateToSend = calculateDateFromRange(selectedRange!);
                  }

                  if (availableBrands.isNotEmpty && selectedBrand == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please select a brand for this vaccine.',
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  await _markVaccineAsTaken(
                    vaccine,
                    dosesCompleted: selectedDoses,
                    dateTaken: dateToSend,
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
      } catch (e) {}
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

  void _navigateToCertificateScreen(VaccineRecord vaccine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VaccineCertificateScreen(vaccine: vaccine),
      ),
    ).then((_) {
      _fetchVaccines();
    });
  }

  // ✅ UPDATED: Strict check for 3+ doses AND future due date
  bool _isRabiesImmunized() {
    final now = DateTime.now();

    return _allVaccines.any((v) {
      // 1. Check if it's a rabies vaccine
      if (!v.name.toLowerCase().contains('rabies')) return false;

      // 2. Condition: 3/3 doses complete (checking >= 3 to be safe)
      if (v.completedDoses < 3) return false;

      // 3. Condition: next due date is > today
      // If nextDueDate is null (e.g., fully done forever), this returns false.
      if (v.nextDueDate == null) return false;

      final nextDue = DateTime.tryParse(v.nextDueDate!);
      // Return true only if we successfully parsed a date AND it is in the future
      return nextDue != null && nextDue.isAfter(now);
    });
  }

  void _showRabiesAssessmentDialog() {
    _RabiesCategory? selectedCategory;
    // Uses the updated strict check for 3 doses + future due date
    bool isImmunized = _isRabiesImmunized();
    DateTime exposureDate = DateTime.now(); // Default Day 0 to today

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.pets, color: Colors.orange[800]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Animal Bite Assessment',
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
                  // --- IMMUNIZATION STATUS BANNER ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isImmunized
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isImmunized ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isImmunized ? Icons.shield : Icons.shield_outlined,
                          color: isImmunized ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isImmunized
                                ? 'Previously Immunized against Rabies'
                                : 'NOT Previously Immunized',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isImmunized
                                  ? Colors.green[800]
                                  : Colors.red[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- DATE SELECTION (DAY 0) ---
                  const Text(
                    'When did the bite occur? (Day 0)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: exposureDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() => exposureDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat.yMMMd().format(exposureDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- CATEGORY SELECTION ---
                  const Text(
                    'Select Exposure Category:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  RadioListTile<_RabiesCategory>(
                    title: const Text(
                      'Category II (Minor)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Nibbling of uncovered skin, minor scratches without bleeding.',
                    ),
                    value: _RabiesCategory.catII,
                    groupValue: selectedCategory,
                    activeColor: Colors.orange[800],
                    onChanged: (val) =>
                        setStateDialog(() => selectedCategory = val),
                  ),
                  RadioListTile<_RabiesCategory>(
                    title: const Text(
                      'Category III (Severe)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Transdermal bites, licks on broken skin, bleeding, mucous contact.',
                    ),
                    value: _RabiesCategory.catIII,
                    groupValue: selectedCategory,
                    activeColor: Colors.red[800],
                    onChanged: (val) =>
                        setStateDialog(() => selectedCategory = val),
                  ),

                  // --- RECOMMENDATION PREVIEW ---
                  if (selectedCategory != null) ...[
                    const Divider(height: 30, thickness: 1),
                    const Text(
                      'Recommendation:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRabiesRecommendation(selectedCategory!, isImmunized),
                  ],
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
              // ✅ PASS ALL DATA TO FINDER ON CONFIRM
              ElevatedButton(
                onPressed: selectedCategory == null
                    ? null
                    : () {
                        Navigator.pop(context); // Close dialog
                        _findAndScheduleRabies(
                          exposureDate: exposureDate,
                          isImmunized: isImmunized,
                          category: selectedCategory!,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Schedule Dose 1 Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ UPDATED: Finds best record based on status & provides contextual alerts
  void _findAndScheduleRabies({
    required DateTime exposureDate,
    required bool isImmunized,
    required _RabiesCategory category,
  }) {
    try {
      // 1. Determine status keyword to look for in vaccine name
      final statusKeyword = isImmunized ? 'immunized' : 'unimmunized';

      // 2. Try finding a SPECIFIC matched record first
      // e.g., looks for "Rabies Vaccine (Post-exposure) - Unimmunized"
      VaccineRecord? targetVaccine;
      try {
        targetVaccine = _allVaccines.firstWhere((v) {
          final name = v.name.toLowerCase();
          return name.contains('rabies') &&
              name.contains('post') &&
              name.contains(statusKeyword) &&
              !v.isCompleted;
        });
      } catch (_) {
        targetVaccine = null;
      }

      // 3. Fallback: Find ANY generic "Post-exposure" record if specific one is missing
      targetVaccine ??= _allVaccines.firstWhere((v) {
        final name = v.name.toLowerCase();
        return name.contains('rabies') &&
            name.contains('post') &&
            !v.isCompleted;
      }, orElse: () => throw Exception('No Post-exposure record found'));

      // 4. Switch to Pending tab so user sees the new schedule immediately
      setState(() {
        _selectedCategory = _DisplayCategory.pending;
      });

      // 5. Use EXISTING workflow to schedule Dose 1
      _scheduleVaccine(targetVaccine, exposureDate);

      // 6. Show CRITICAL reminder based on Category & Status
      String reminderText =
          'Dose 1 scheduled! Remember to follow the full regimen.';
      Color snackBarColor = Colors.orange[900]!;

      if (!isImmunized && category == _RabiesCategory.catIII) {
        // Critical case: needs RIG
        reminderText =
            '⚠️ CRITICAL: For Category III, you MUST also get Rabies Immunoglobulin (RIG) immediately!';
        snackBarColor = Colors.red[800]!;
      } else if (!isImmunized) {
        reminderText =
            'Dose 1 scheduled. You need ALL 5 doses (Days 0,3,7,14,28).';
      } else {
        reminderText = 'Dose 1 scheduled. You only need 2 doses (Days 0 & 3).';
      }

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reminderText),
            backgroundColor: snackBarColor,
            duration: const Duration(
              seconds: 8,
            ), // Longer duration for importance
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {}, // Dismisses
            ),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      // Show error if NO appropriate record was found in the list
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Missing Vaccine Record'),
          content: const Text(
            'We could not find a "Rabies Post-Exposure" vaccine in your records list.\n\nPlease contact support to have this situational vaccine added to your profile so it can be scheduled.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRabiesRecommendation(
    _RabiesCategory category,
    bool isImmunized,
  ) {
    bool needsRIG = !isImmunized && category == _RabiesCategory.catIII;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RIG (Immunoglobulin): ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text(
                  needsRIG
                      ? '✅ Infiltrate wounds with RIG as soon as possible'
                      : '❌ NOT indicated',
                  style: TextStyle(
                    color: needsRIG ? Colors.red[700] : Colors.grey[700],
                    fontWeight: needsRIG ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Vaccine Schedule:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          if (isImmunized) ...[
            Text('• Intradermal (ID): 2 doses (days 0, 3)'),
            Text('  OR'),
            Text('• Intramuscular (IM): 2 doses (days 0, 3)'),
          ] else ...[
            Text('• Intradermal (ID): 4 doses (days 0, 3, 7, 28)'),
            Text('  OR'),
            Text('• Intramuscular (IM): 5 doses (days 0, 3, 7, 14, 28)'),
          ],
          SizedBox(height: 16),
          Text(
            '⚠️ Seek immediate medical attention to administer these doses.',
            style: TextStyle(
              color: Colors.orange[900],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

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
            Icon(icon, size: 64, color: Colors.grey[300]),
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
              textAlign: TextAlign.center,
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
      // Use flex 1 for all to distribute evenly
      flex: 1,
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey[600],
                size: 22,
              ),
              // Only show text if it fits, or scale it down
              if (isActive || MediaQuery.of(context).size.width > 350) ...[
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<VaccineRecord> completedDisplayList = [];
    final List<VaccineRecord> pendingDisplayList = [];
    final List<VaccineRecord> boosterDisplayList = [];

    for (final record in _allVaccines) {
      if (record.isCompleted) {
        completedDisplayList.add(record);
      } else {
        final completedPart = record.completedPart;
        if (completedPart != null) {
          completedDisplayList.add(completedPart);
        }
        bool isBooster =
            record.totalDoses != null &&
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
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildToggleTab(
                                  context,
                                  text: 'Pending',
                                  icon: Icons.schedule,
                                  category: _DisplayCategory.pending,
                                  activeColor: const Color(0xFF8B5FBF),
                                ),
                                _buildToggleTab(
                                  context,
                                  text: 'Booster',
                                  icon: Icons.health_and_safety_outlined,
                                  category: _DisplayCategory.booster,
                                  activeColor: const Color(0xFF3182CE),
                                ),
                                _buildToggleTab(
                                  context,
                                  text: 'Completed',
                                  icon: Icons.check_circle,
                                  category: _DisplayCategory.completed,
                                  activeColor: const Color(0xFF10B981),
                                ),
                                _buildToggleTab(
                                  context,
                                  text: 'Situational',
                                  icon: Icons.medical_services_outlined,
                                  category: _DisplayCategory.situational,
                                  activeColor: Colors.orange.shade700,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

    if (pending.isEmpty &&
        completed.isEmpty &&
        _selectedCategory != _DisplayCategory.situational) {
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

                  case _DisplayCategory.situational:
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency & Situational Vaccines',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.pets,
                                        color: Colors.orange.shade800,
                                        size: 28,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Animal Bite (Rabies)',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2D3748),
                                            ),
                                          ),
                                          Text(
                                            'For dog/animal bites, scratches, or licks on broken skin.',
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
                                SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _showRabiesAssessmentDialog,
                                    icon: Icon(Icons.medical_services_outlined),
                                    label: Text(
                                      'Report Bite & Get Recommendation',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade700,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

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
