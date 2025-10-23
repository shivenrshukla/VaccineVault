import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class VaccineCentresScreen extends StatefulWidget {
  const VaccineCentresScreen({super.key});

  @override
  State<VaccineCentresScreen> createState() => _VaccineCentresScreenState();
}

class _VaccineCentresScreenState extends State<VaccineCentresScreen> {
  bool _isLoading = true;
  String? _error;
  
  // User data
  String? _userPinCode;
  String? _userAddress;
  double? _userLat;
  double? _userLng;
  
  // Vaccination centers
  List<VaccinationCenter> _centers = [];
  
  final AuthService _authService = AuthService();
  static const String apiBaseUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      await _fetchUserProfile();
      
      if (_userPinCode != null) {
        await _fetchVaccinationCenters();
      } else {
        setState(() {
          _error = 'Pin code not found in your profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    final token = await _authService.getToken();
    
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _userPinCode = data['pinCode']?.toString();
          
          // Build complete address for accurate geocoding
          final addressParts = <String>[];
          if (data['addressPart1'] != null) addressParts.add(data['addressPart1']);
          if (data['addressPart2'] != null && data['addressPart2'].toString().isNotEmpty) {
            addressParts.add(data['addressPart2']);
          }
          if (data['city'] != null) addressParts.add(data['city']);
          if (data['state'] != null) addressParts.add(data['state']);
          if (data['pinCode'] != null) addressParts.add(data['pinCode'].toString());
          
          _userAddress = addressParts.join(', ');
          
          print('✅ User Address: $_userAddress');
        });
      } else if (response.statusCode == 401) {
        await _authService.logout();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      throw Exception('Failed to load user profile: $e');
    }
  }

  Future<void> _fetchVaccinationCenters() async {
    final token = await _authService.getToken();
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      // Build URI with query parameters properly
      final queryParams = <String, String>{
        'pinCode': _userPinCode!,
      };

      // Add userAddress if available for accurate distance calculation
      if (_userAddress != null && _userAddress!.isNotEmpty) {
        queryParams['userAddress'] = _userAddress!;
      }

      final uri = Uri.parse('$apiBaseUrl/api/find/find-centers')
          .replace(queryParameters: queryParams);

      print('🔍 Fetching centers from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract search location (pincode-based location)
        final searchLocation = data['searchLocation'];
        if (searchLocation != null) {
          _userLat = (searchLocation['lat'] as num?)?.toDouble();
          _userLng = (searchLocation['lng'] as num?)?.toDouble();
        }

        // Extract actual user location if geocoded
        final userLocation = data['userLocation'];
        if (userLocation != null) {
          _userLat = (userLocation['lat'] as num?)?.toDouble();
          _userLng = (userLocation['lng'] as num?)?.toDouble();
          print('✅ User geocoded location: $_userLat, $_userLng');
        }
        
        setState(() {
          final centersData = data['foundCenters'] as List;
          _centers = centersData
              .map((center) => VaccinationCenter.fromJson(center))
              .toList();
          
          _isLoading = false;
        });
        
        print('✅ Found ${_centers.length} vaccination centers');
        
        // Log distance calculation method used
        if (_centers.isNotEmpty && _centers.first.distanceSource != null) {
          print('📍 Distance calculated using: ${_centers.first.distanceSource}');
        }
      } else if (response.statusCode == 401) {
        await _authService.logout();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to load centers');
      }
    } catch (e) {
      print('Error fetching vaccination centers: $e');
      throw Exception('Failed to load vaccination centers: $e');
    }
  }

  void _showCenterDetails(VaccinationCenter center, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5FBF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Color(0xFF8B5FBF),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'Center #${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildInfoRow(Icons.location_on, 'Address', center.address),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone, 'Contact', center.contact),
            const Divider(height: 24),
            // ✅ Hardcoded distance display
            _buildInfoRow(Icons.directions, 'Distance', '2 km'),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF8B5FBF)),
                      foregroundColor: const Color(0xFF8B5FBF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening directions...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5FBF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF8B5FBF)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF2D3748),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B5FBF),
              Color(0xFFB794F6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vaccination Centers',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (!_isLoading && _userPinCode != null)
                            Text(
                              'Near $_userPinCode',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _isLoading ? null : _initialize,
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF8B5FBF)),
            SizedBox(height: 16),
            Text(
              'Finding vaccination centers...',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initialize,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5FBF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Location header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5FBF).withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF8B5FBF).withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5FBF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Location',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B5FBF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userAddress ?? 'Pin Code: $_userPinCode',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_centers.length} Found',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Centers list
        Expanded(
          child: _centers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No vaccination centers found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _centers.length,
                  itemBuilder: (context, index) {
                    final center = _centers[index];
                    return _buildCenterCard(center, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCenterCard(VaccinationCenter center, int index) {
    return GestureDetector(
      onTap: () => _showCenterDetails(center, index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF8B5FBF).withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5FBF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    center.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          center.address,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.directions_walk, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      // ✅ Hardcoded distance to 2 km
                      Text(
                        '2 km',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF8B5FBF),
            ),
          ],
        ),
      ),
    );
  }
}

// Model class (simplified since distance is hardcoded)
class VaccinationCenter {
  final String name;
  final String address;
  final String contact;
  final String distance;
  final double? distanceValue;
  final String? distanceSource;
  final Map<String, double?>? coordinates;

  VaccinationCenter({
    required this.name,
    required this.address,
    required this.contact,
    required this.distance,
    this.distanceValue,
    this.distanceSource,
    this.coordinates,
  });

  factory VaccinationCenter.fromJson(Map<String, dynamic> json) {
    return VaccinationCenter(
      name: json['name'] ?? 'Unknown Center',
      address: json['address'] ?? 'Address not available',
      contact: json['contact'] ?? 'Not Available',
      // ✅ Distance is ignored from API, hardcoded to 2 km
      distance: '2 km',
      distanceValue: 2.0, // Hardcoded value
      distanceSource: json['distanceSource'],
      coordinates: json['coordinates'] != null
          ? {
              'lat': json['coordinates']['lat']?.toDouble(),
              'lng': json['coordinates']['lng']?.toDouble(),
            }
          : null,
    );
  }
}
