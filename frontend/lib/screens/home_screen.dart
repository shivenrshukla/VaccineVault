// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  HomeScreen({super.key});

  void _logout(BuildContext context) {
    _authService.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/getting-started',
      (route) => false,
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
              Color(0xFF8B5FBF), // Top purple color
              Color(0xFFB794F6), // Middle purple color
              Color(0xFFD6BCFA), // Lighter middle color
              Color(0xFFFFB3BA), // Pinkish bottom color
            ],
            stops: [0.0, 0.4, 0.7, 1.0], // Controls the gradient spread
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Header Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '👋 Hi Rayyan!', // Placeholder name
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    CircleAvatar(
                      // UPDATED HERE
                      backgroundColor: Color.fromARGB(
                        77,
                        255,
                        255,
                        255,
                      ), // Colors.white.withOpacity(0.3)
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Main Content - List of Cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildInfoCard(
                        title: 'Vaccine Schedule',
                        icon: Icons.calendar_today,
                        color: const Color(0xFF6B46C1),
                      ),
                      _buildInfoCard(
                        title: 'Vaccine Records',
                        icon: Icons.assignment_turned_in,
                        color: const Color(0xFF553C9A),
                      ),
                      _buildInfoCard(
                        title: 'Knowledge Base',
                        icon: Icons.info,
                        color: const Color(0xFF8B5FBF),
                      ),
                      _buildInfoCard(
                        title: 'Chatbot',
                        icon: Icons.chat,
                        color: const Color(0xFFB794F6),
                      ),
                      _buildInfoCard(
                        title: 'Vaccine Centres near me',
                        icon: Icons.location_on,
                        color: const Color(0xFF9F7AEA),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom Navigation Bar
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
        onTap: (index) {
          // Placeholder for navigation logic
          if (index == 3) {
            _logout(context);
          }
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // UPDATED HERE
            color: const Color.fromARGB(
              13,
              0,
              0,
              0,
            ), // Colors.black.withOpacity(0.05)
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Icon(icon, size: 40, color: color),
        ],
      ),
    );
  }
}
