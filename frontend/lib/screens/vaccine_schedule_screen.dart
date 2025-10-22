import 'package:flutter/material.dart';

class VaccineScheduleScreen extends StatelessWidget {
  const VaccineScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccine Schedule'),
        backgroundColor: const Color(0xFF6B46C1), // Matching card color
      ),
      body: const Center(
        child: Text(
          'Vaccine Schedule Details Here',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
