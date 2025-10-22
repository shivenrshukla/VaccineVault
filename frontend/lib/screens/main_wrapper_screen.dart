import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'notifications_screen.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  // List of pages to be displayed
  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Your existing HomeScreen
    StatsScreen(),
    NotificationsScreen(),
  ];

  void _logout(BuildContext context) {
    _authService.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/getting-started',
      (route) => false,
    );
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      // Index 3 is 'Settings', which triggers logout
      _logout(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6B46C1),
        unselectedItemColor: const Color(0xFF9CA3AF),
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
