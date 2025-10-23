import 'package:flutter/material.dart';
// import '../services/auth_service.dart'; // No longer needed here
import 'home_screen.dart';
import 'stats_screen.dart';
import 'notifications_screen.dart';
// SettingsPage is not directly used in the list, but imported for navigation context
// import 'settings_page.dart'; 

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _selectedIndex = 0;
  // final AuthService _authService = AuthService(); // No longer needed here

  // List of pages to be displayed
  // SettingsPage is handled by navigation, not by this IndexedStack
  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Your existing HomeScreen
    StatsScreen(),
    NotificationsScreen(),
  ];

  // --- REMOVED THE _logout FUNCTION ---
  // void _logout(BuildContext context) {
  //   _authService.logout();
  //   Navigator.pushNamedAndRemoveUntil(context, '/settings', (route) => false);
  // }

  void _onItemTapped(int index) {
    if (index == 3) {
      // --- CORRECTED LOGIC ---
      // Index 3 is 'Settings'. Just navigate to the settings page.
      // The SettingsPage itself has the logout button.
      Navigator.pushNamed(context, '/settings');
    } else {
      // For all other indices (0, 1, 2), just switch the tab.
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use IndexedStack to keep the state of the other tabs (Home, Stats, Notifs)
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).cardColor, // Theme-aware
        selectedItemColor: Theme.of(context).primaryColor, // Theme-aware
        unselectedItemColor: Colors.grey.shade400, // Theme-aware
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all 4 items are visible
      ),
    );
  }
}
