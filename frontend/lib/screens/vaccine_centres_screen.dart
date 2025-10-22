import 'package:flutter/material.dart';

class VaccineCentresScreen extends StatelessWidget {
  const VaccineCentresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccine Centres'),
        backgroundColor: const Color(0xFF9F7AEA), // Matching card color
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text('Map of Nearby Centres Here', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
