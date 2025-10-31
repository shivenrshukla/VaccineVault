// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

import 'vaccine_schedule_screen.dart';
import 'vaccine_records_screen.dart';
import 'knowledge_base_screen.dart';
import 'vaccine_centres_screen.dart';
import 'profile_page.dart';
import 'travel_vaccines_screen.dart';
import 'my_certificates_screen.dart'; // ✅ NEW IMPORT

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              // Top Header Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '👋 Hi Rayyan!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                      child: const CircleAvatar(
                        backgroundColor: Color.fromARGB(77, 255, 255, 255),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
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

                      // ✅ NEW CARD ADDED
                      _buildInfoCard(
                        context: context,
                        title: 'My Certificates',
                        icon: Icons.file_copy,
                        color: const Color(0xFF8B5FBF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MyCertificatesScreen(),
                            ),
                          );
                        },
                      ),

                      _buildInfoCard(
                        context: context,
                        title: 'Knowledge Base',
                        icon: Icons.info,
                        color: const Color(0xFFB794F6), // Changed color
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
                        title: 'Travel Vaccines',
                        icon: Icons.flight_takeoff,
                        color: const Color(0xFFD6BCFA), // Changed color
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TravelVaccinesScreen(),
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
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
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
