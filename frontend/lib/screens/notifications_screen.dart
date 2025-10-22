import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Color(0xFF6B46C1),
      ),
      body: Center(
        child: Text(
          'List of Notifications Here',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
