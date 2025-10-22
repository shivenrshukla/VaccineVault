import 'package:flutter/material.dart';

class VaccineRecordsScreen extends StatelessWidget {
  const VaccineRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccine Records'),
        backgroundColor: const Color(0xFF553C9A), // Matching card color
      ),
      body: const Center(
        child: Text(
          'User Vaccine Records List Here',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
