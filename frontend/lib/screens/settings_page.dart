import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaccinevault/providers/theme_provider.dart'; // Ensure this path is correct
import 'package:vaccinevault/services/auth_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // 1. ADDED PLATFORM CHECK IMPORT

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool biometricEnabled = false;
  String selectedLanguage = 'English';

  final AuthService _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  final _dialogFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 2. ADDED CHECK: Don't try to load biometrics on web
    if (!kIsWeb) {
      _loadBiometricPreference();
    }
  }

  Future<void> _loadBiometricPreference() async {
    // ADDED CHECK: Extra safety check for web
    if (kIsWeb) return;

    bool enabled = await _authService.isBiometricEnabled();
    if (mounted) {
      setState(() => biometricEnabled = enabled);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Purple header with back button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: theme.colorScheme.onPrimary),
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Account Section
                        Text(
                          'Account',
                          style: textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          children: [
                            _buildSettingsTile(
                              icon: Icons.person_outline,
                              title: 'Edit Profile',
                              subtitle: 'Change your profile information',
                              onTap: () {
                                Navigator.pushNamed(context, '/profile');
                              },
                            ),
                            _buildDivider(),
                            _buildSettingsTile(
                              icon: Icons.lock_outline,
                              title: 'Change Password',
                              subtitle: 'Update your password',
                              onTap: () {
                                _showChangePasswordDialog();
                              },
                            ),
                            _buildDivider(),
                            _buildSettingsTile(
                              icon: Icons.email_outlined,
                              title: 'Email Preferences',
                              subtitle: 'Manage email notifications',
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Notifications Section
                        Text(
                          'Notifications',
                          style: textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          children: [
                            _buildSwitchTile(
                              icon: Icons.notifications_outlined,
                              title: 'Push Notifications',
                              subtitle: 'Receive vaccine reminders',
                              value: notificationsEnabled,
                              onChanged: (value) {
                                setState(() {
                                  notificationsEnabled = value;
                                });
                              },
                            ),
                            _buildDivider(),
                            _buildSettingsTile(
                              icon: Icons.schedule,
                              title: 'Reminder Time',
                              subtitle: '9:00 AM',
                              onTap: () {
                                _showTimePickerDialog();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Preferences Section
                        Text(
                          'Preferences',
                          style: textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          children: [
                            _buildSettingsTile(
                              icon: Icons.language,
                              title: 'Language',
                              subtitle: selectedLanguage,
                              onTap: () {
                                _showLanguageDialog();
                              },
                            ),
                            _buildDivider(),
                            Consumer<ThemeProvider>(
                              builder: (context, themeProvider, child) {
                                return _buildSwitchTile(
                                  icon: Icons.dark_mode_outlined,
                                  title: 'Dark Mode',
                                  subtitle: 'Enable dark theme',
                                  value: themeProvider.isDarkMode,
                                  onChanged: (value) {
                                    themeProvider.toggleTheme(value);
                                  },
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildSettingsTile(
                              icon: Icons.location_on_outlined,
                              title: 'Location Services',
                              subtitle: 'Find nearby vaccine centers',
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Enabled',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Security Section
                        Text(
                          'Security',
                          style: textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          children: [
                            _buildSwitchTile(
                              icon: Icons.fingerprint,
                              title: 'Biometric Login',
                              subtitle:
                                  'Use fingerprint or face ID for quick login',
                              value: biometricEnabled,
                              onChanged: (value) async {
                                // 3. ADDED PLATFORM CHECK BLOCK
                                if (kIsWeb) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Biometrics are not supported on the web.'),
                                      backgroundColor: Colors.amber,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return; // Stop execution
                                }
                                // END OF PLATFORM CHECK BLOCK

                                if (value) {
                                  // Trying to enable
                                  try {
                                    bool canCheck =
                                        await _localAuth.canCheckBiometrics;
                                    if (!canCheck) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Biometric authentication not available'),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating),
                                      );
                                      return;
                                    }

                                    bool authenticated =
                                        await _localAuth.authenticate(
                                      localizedReason:
                                          'Authenticate to enable biometrics',
                                      options: const AuthenticationOptions(
                                          stickyAuth: true,
                                          biometricOnly: true),
                                    );

                                    if (authenticated) {
                                      setState(() => biometricEnabled = true);
                                      await _authService
                                          .setBiometricEnabled(true);
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating),
                                    );
                                  }
                                } else {
                                  // Disabling
                                  setState(() => biometricEnabled = false);
                                  await _authService
                                      .setBiometricEnabled(false);
                                }
                              },
                            ),
                            _buildDivider(),
                            _buildSettingsTile(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy Policy',
                              subtitle: 'Read our privacy policy',
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // About Section
                        Text(
                          'About',
                          style: textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          children: [
                            _buildSettingsTile(
                              icon: Icons.info_outline,
                              title: 'App Version',
                              subtitle: 'Version 1.0.0',
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildSettingsTile(
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              subtitle: 'Get help with the app',
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildSettingsTile(
                              icon: Icons.rate_review_outlined,
                              title: 'Rate App',
                              subtitle: 'Share your feedback',
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showLogoutDialog();
                            },
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
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

  // --- All helper widgets from V1 are kept as-is ---

  Widget _buildSettingsCard({required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(height: 1, color: Theme.of(context).dividerColor),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('Hindi'),
            _buildLanguageOption('Marathi'),
            _buildLanguageOption('Gujarati'),
            _buildLanguageOption('Bengali'), // Corrected typo
            _buildLanguageOption('Telugu'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return RadioListTile<String>(
      title: Text(language),
      value: language,
      groupValue: selectedLanguage,
      activeColor: Theme.of(context).primaryColor,
      onChanged: (value) {
        setState(() {
          selectedLanguage = value!;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showTimePickerDialog() {
    showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  // Functional Change Password Dialog
  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    bool isLoading = false;
    String? dialogError;

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: _dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dialogError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          dialogError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Cannot be empty' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Cannot be empty';
                        if (value.length < 6)
                          return 'Must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() {
                            dialogError = null;
                          });

                          if (_dialogFormKey.currentState!.validate()) {
                            setDialogState(() {
                              isLoading = true;
                            });

                            try {
                              await _authService.changePassword(
                                _currentPasswordController.text,
                                _newPasswordController.text,
                              );

                              if (!mounted) return;
                              Navigator.pop(context); // Close dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Password changed successfully!'),
                                  backgroundColor: theme.primaryColor,
                                ),
                              );
                            } catch (e) {
                              setDialogState(() {
                                dialogError = e
                                    .toString()
                                    .replaceFirst("Exception: ", "");
                                isLoading = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Functional Logout Dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.logout();

              if (!mounted) return;
              Navigator.pop(context); // Close dialog
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}