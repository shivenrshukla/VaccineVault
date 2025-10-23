import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = false;

  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final profileData = await ApiService.getProfile();
      
      setState(() {
        _usernameController.text = profileData['username'] ?? '';
        _emailController.text = profileData['email'] ?? '';
        _dobController.text = profileData['dateOfBirth'] ?? '';
        _phoneController.text = profileData['phoneNumber'] ?? '';
        _genderController.text = profileData['gender'] ?? '';
        _address1Controller.text = profileData['addressPart1'] ?? '';
        _address2Controller.text = profileData['addressPart2'] ?? '';
        _cityController.text = profileData['city'] ?? '';
        _stateController.text = profileData['state'] ?? '';
        _pincodeController.text = profileData['pinCode'] ?? '';
        _passwordController.text = '••••••••'; // Placeholder for security
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userData = {
      'username': _usernameController.text,
      'email': _emailController.text,
      'dateOfBirth': _dobController.text,
      'phoneNumber': _phoneController.text,
      'gender': _genderController.text,
      'addressPart1': _address1Controller.text,
      'addressPart2': _address2Controller.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'pinCode': _pincodeController.text,
    };
    
    // Note: Password is not sent here. Handle password change separately.

    try {
      final success = await ApiService.updateProfile(userData);
      
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Profile updated successfully!' : 'Failed to update profile',
            ),
            backgroundColor: success ? const Color(0xFF9B59D0) : Colors.red,
          ),
        );
      }

      if (success) _loadProfile();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: theme.colorScheme.onPrimary),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Enhanced Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: theme.colorScheme.onPrimary,
                                size: 28,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              'My Profile',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Profile Avatar
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.onPrimary, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.3),
                            child: Text(
                              _usernameController.text.isNotEmpty
                                  ? _usernameController.text[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // White card container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with greeting and edit icon
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: _isEditing
                                            ? Colors.grey.shade300
                                            : theme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _isEditing ? Icons.close : Icons.edit,
                                          color: _isEditing
                                              ? Colors.black87
                                              : theme.colorScheme.onPrimary,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isEditing = !_isEditing;
                                            // Reload profile data if canceling edit
                                            if (!_isEditing) _loadProfile();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Personal Information
                                _buildSectionHeader('Personal Information'),
                                const SizedBox(height: 16),

                                _buildTextField(
                                  controller: _usernameController,
                                  label: 'Username',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 16),

                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),

                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  obscureText: true,
                                  // Disable password field always unless it's a "change password" flow
                                  forceDisabled: true, 
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _dobController,
                                        label: 'Date of Birth',
                                        icon: Icons.calendar_today_outlined,
                                        onTap: _isEditing ? _selectDate : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _genderController,
                                        label: 'Gender',
                                        icon: Icons.wc_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Contact Information
                                _buildSectionHeader('Contact Information'),
                                const SizedBox(height: 16),

                                _buildTextField(
                                  controller: _phoneController,
                                  label: 'Phone Number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 24),

                                // Address Information
                                _buildSectionHeader('Address'),
                                const SizedBox(height: 16),

                                _buildTextField(
                                  controller: _address1Controller,
                                  label: 'Address Line 1',
                                  icon: Icons.home_outlined,
                                ),
                                const SizedBox(height: 16),

                                _buildTextField(
                                  controller: _address2Controller,
                                  label: 'Address Line 2 (Optional)',
                                  icon: Icons.home_outlined,
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _cityController,
                                        label: 'City',
                                        icon: Icons.location_city_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _stateController,
                                        label: 'State',
                                        icon: Icons.map_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                _buildTextField(
                                  controller: _pincodeController,
                                  label: 'Pincode',
                                  icon: Icons.pin_drop_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 32),

                                // Action Buttons
                                if (_isEditing)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              _isEditing = false;
                                            });
                                            _loadProfile(); // Revert changes
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            side: BorderSide(
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: theme.primaryColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton(
                                          onPressed: _saveProfile,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                theme.primaryColor,
                                            foregroundColor: theme.colorScheme.onPrimary,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 2,
                                          ),
                                          child: const Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        fontSize: 18
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    bool forceDisabled = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final bool isEnabled = _isEditing && !forceDisabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: isEnabled,
          keyboardType: keyboardType,
          readOnly: onTap != null,
          onTap: onTap,
          style: TextStyle(
            color: isEnabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 15,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: isEnabled ? theme.primaryColor : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: isEnabled ? theme.cardColor : theme.dividerColor.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (label != 'Address Line 2 (Optional)' &&
                (value == null || value.isEmpty)) {
              return 'Please enter $label';
            }
            if (label == 'Email' && value != null && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    return '$greeting, ${_usernameController.text.split(' ')[0]}';
  }
}
