import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _biometricMessage = '';
  
  // 1. ADDED: State variable to hold the user's preference
  bool _isBiometricEnabled = false;

  // 2. ADDED: initState to load the preference on screen load
  @override
  void initState() {
    super.initState();
    _checkBiometricPreference();
  }
  
  // 3. ADDED: Function to check the preference from AuthService
  Future<void> _checkBiometricPreference() async {
    final bool enabled = await _authService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.login(
          _emailController.text,
          _passwordController.text,
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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

  Future<void> _loginWithBiometrics() async {
    // The preference check is already done by hiding/showing the button.
    // This function now just checks hardware and authenticates.
    try {
      bool canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        setState(() => _biometricMessage = "Biometric authentication not available on this device");
        return;
      }

      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint or face to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        if (!mounted) return;
        // IMPORTANT: You'll need to fetch the user's credentials
        // from secure storage here and log them in,
        // then navigate.
        // For now, just navigating to home.
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _biometricMessage = "Failed to authenticate");
      }
    } catch (e) {
      setState(() => _biometricMessage = "Error: $e");
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
              // Top section (logo + back arrow)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo.jpeg',
                            width: 350,
                            height: 350,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom section (login form)
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              Container(
                                width: 80,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Digital India',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Email field
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              validator: Validators.validateEmail, // Using validateEmail
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline, color: Color(0xFF8B5FBF)),
                                hintText: 'Email', // Changed hint
                                hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              validator: Validators.validatePassword,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF8B5FBF)),
                                hintText: '••••••',
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Signup link
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/signup'),
                              child: const Text(
                                'Don\'t have an account?',
                                style: TextStyle(color: Color(0xFF8B5FBF), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Login button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF8B5FBF), Color(0xFF6B46C1)]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: const Color.fromARGB(77, 139, 95, 191), blurRadius: 20, offset: const Offset(0, 10)),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // OR divider
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Or', style: TextStyle(color: Color(0xFF9CA3AF)))),
                              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Google button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Google Sign In - Coming Soon!'), behavior: SnackBarBehavior.floating),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2D3748),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Text('G', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)), // Simple 'G'
                              label: const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), // Updated text
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 4. UPDATED: Conditional biometric button
                          if (_isBiometricEnabled) ...[
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFC), // Lighter color
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)), // Border
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _loginWithBiometrics,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent, // Transparent bg
                                  foregroundColor: const Color(0xFF2D3748), // Dark text
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                icon: const Icon(Icons.fingerprint, size: 24, color: Color(0xFF6B46C1)), // Themed icon
                                label: const Text('Login with Biometrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_biometricMessage.isNotEmpty)
                              Center(child: Text(_biometricMessage, style: const TextStyle(color: Colors.red))),
                          ],
                        ],
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
}