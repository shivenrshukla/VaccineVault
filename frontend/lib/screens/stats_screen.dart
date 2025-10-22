import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This screen can have its own Scaffold or just be a widget body
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics'),
        backgroundColor: Color(0xFF6B46C1),
      ),
      body: Center(
        child: Text(
          'Statistics and Charts Here',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
