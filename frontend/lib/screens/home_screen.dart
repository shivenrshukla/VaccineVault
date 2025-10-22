// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
// REMOVE: AuthService import (it's in the wrapper)

// ADD imports for your new screens
import 'vaccine_schedule_screen.dart';
import 'vaccine_records_screen.dart';
import 'knowledge_base_screen.dart';
import 'chatbot_screen.dart';
import 'vaccine_centres_screen.dart';

class HomeScreen extends StatelessWidget {
  // REMOVE: AuthService instance
  // REMOVE: _logout method

  const HomeScreen({super.key}); // UPDATED constructor

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
              Color(0xFFD6BCFA),
              Color(0xFFFFB3BA),
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Header Section (no change)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '👋 Hi Rayyan!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Color.fromARGB(77, 255, 255, 255),
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
                      // UPDATED: Added onTap handlers
                      _buildInfoCard(
                        context: context,
                        title: 'Vaccine Schedule',
                        icon: Icons.calendar_today,
                        color: const Color(0xFF6B46C1),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const VaccineScheduleScreen(),
                            ),
                          );
                        },
                      ),
                      _buildInfoCard(
                        context: context,
                        title: 'Vaccine Records',
                        icon: Icons.assignment_turned_in,
                        color: const Color(0xFF553C9A),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const VaccineRecordsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildInfoCard(
                        context: context,
                        title: 'Knowledge Base',
                        icon: Icons.info,
                        color: const Color(0xFF8B5FBF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KnowledgeBaseScreen(),
                            ),
                          );
                        },
                      ),
                      _buildInfoCard(
                        context: context,
                        title: 'Chatbot',
                        icon: Icons.chat,
                        color: const Color(0xFFB794F6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatbotScreen(),
                            ),
                          );
                        },
                      ),
                      _buildInfoCard(
                        context: context,
                        title: 'Vaccine Centres near me',
                        icon: Icons.location_on,
                        color: const Color(0xFF9F7AEA),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const VaccineCentresScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // REMOVE the entire bottomNavigationBar property
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap, // UPDATED: Add onTap callback
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        // UPDATED: Wrap with InkWell for ripple effect
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(13, 0, 0, 0),
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
        ),
      ),
    );
  }
}