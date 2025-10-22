import 'package:flutter/material.dart';

class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base'),
        backgroundColor: const Color(0xFF8B5FBF), // Matching card color
      ),
      body: const Center(
        child: Text(
          'Vaccine Info and Articles Here',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
