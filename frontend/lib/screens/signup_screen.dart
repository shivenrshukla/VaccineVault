import 'package:flutter/material.dart';
import '../models/user.dart'; // Make sure User model is imported
import '../services/auth_service.dart';
import '../utils/validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // --- Controllers for all form fields ---
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController(); // NEW: Controller for Address Line 2
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose(); // NEW: Dispose new controller
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    return Validators.validateConfirmPassword(value, _passwordController.text);
  }

  // --- NEW: Function to show the date picker ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Default to 18 years ago
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B5FBF), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Color(0xFF2D3748), // Body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Format the date as YYYY-MM-DD
      _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Create a User object from the form controllers
      final newUser = User(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        dateOfBirth: _dobController.text,
        addressPart1: _address1Controller.text,
        // UPDATED: Pass addressPart2, sending null if it's empty
        addressPart2: _address2Controller.text.isNotEmpty ? _address2Controller.text : null,
        city: _cityController.text,
        state: _stateController.text,
        pinCode: _pincodeController.text,
        phoneNumber: _phoneController.text,
      );

      try {
        await _authService.register(newUser);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
           setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8B5FBF), Color(0xFFB794F6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                             const Text(
                               'Create Account',
                               style: TextStyle(
                                 fontSize: 28,
                                 fontWeight: FontWeight.bold,
                                 color: Color(0xFF2D3748),
                               ),
                             ),
                            const SizedBox(height: 20),
                            _buildTextField(controller: _usernameController, validator: Validators.validateName, hint: 'Username', icon: Icons.person_outlined),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _emailController, validator: Validators.validateEmail, hint: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                             _buildTextField(controller: _phoneController, validator: Validators.validatePhoneNumber, hint: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                            const SizedBox(height: 16),
                            // UPDATED: Date of Birth field now uses the date picker
                            _buildTextField(controller: _dobController, validator: Validators.validateDate, hint: 'Date of Birth', icon: Icons.cake_outlined, readOnly: true, onTap: () => _selectDate(context)),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _address1Controller, validator: Validators.validateAddress, hint: 'Address Line 1', icon: Icons.home_outlined),
                            const SizedBox(height: 16),
                            // NEW: Added Address Line 2 text field
                            _buildTextField(controller: _address2Controller, validator: (value) => null, hint: 'Address Line 2 (Optional)', icon: Icons.add_road_outlined),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _cityController, validator: Validators.validateCity, hint: 'City', icon: Icons.location_city),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _stateController, validator: Validators.validateState, hint: 'State', icon: Icons.map_outlined),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _pincodeController, validator: Validators.validatePinCode, hint: 'PIN Code', icon: Icons.pin_drop_outlined, keyboardType: TextInputType.number),
                            const SizedBox(height: 16),
                            _buildPasswordField(controller: _passwordController, validator: Validators.validatePassword, hint: 'Password', obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                            const SizedBox(height: 16),
                            _buildPasswordField(controller: _confirmPasswordController, validator: _validateConfirmPassword, hint: 'Confirm Password', obscure: _obscureConfirmPassword, onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                            const SizedBox(height: 30),
                            _buildGradientButton(),
                            const SizedBox(height: 16),
                             Center(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Already have an account?', style: TextStyle(color: Color(0xFF8B5FBF), fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 20),
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
      ),
    );
  }

  // UPDATED: Helper widget now supports readOnly and onTap for the date picker
  Widget _buildTextField({required TextEditingController controller, required String? Function(String?) validator, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, bool readOnly = false, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(12)),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF8B5FBF)),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required String? Function(String?) validator, required String hint, required bool obscure, required VoidCallback onToggle}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(12)),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF8B5FBF)),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF9CA3AF)),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGradientButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8B5FBF), Color(0xFF6B46C1)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color.fromARGB(77, 139, 95, 191), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signup,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}

