import 'package:flutter/material.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot'),
        backgroundColor: const Color(0xFFB794F6), // Matching card color
      ),
      body: const Center(
        child: Text('Chatbot Interface Here', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
