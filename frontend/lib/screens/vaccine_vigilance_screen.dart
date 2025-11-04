// lib/screens/vaccine_vigilance_screen.dart
import 'package:flutter/material.dart';
// Add url_launcher to your pubspec.yaml file for this to work
import 'package:url_launcher/url_launcher.dart';

class VaccineVigilanceScreen extends StatelessWidget {
  const VaccineVigilanceScreen({super.key});

  // Helper function to launch a URL (for phone or email)
  void _launchUrl(String urlScheme) async {
    final Uri uri = Uri.parse(urlScheme);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Could not launch
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccine Vigilance'),
        backgroundColor: const Color(0xFF4A5568),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Emergency Disclaimer
          _buildEmergencyDisclaimer(),
          const SizedBox(height: 24),

          // 2. What is Vaccine Vigilance?
          _buildSectionHeader(
            context,
            icon: Icons.shield_outlined,
            title: 'What is Vaccine Vigilance?',
          ),
          const SizedBox(height: 12),
          const Text(
            'The Government of India runs a robust surveillance program to monitor Adverse Events Following Immunization (AEFI).',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'An AEFI is "any untoward medical occurrence which follows immunization and which does not necessarily have a causal relationship with the usage of the vaccine."',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'The goal is to ensure all vaccines are safe and to maintain public confidence and trust. Your notification helps the nation monitor vaccine safety.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const Divider(height: 40),

          // 3. How to Notify an Event
          _buildSectionHeader(
            context,
            icon: Icons.call_outlined,
            title: 'How to Notify an Event',
          ),
          const SizedBox(height: 12),
          const Text(
            'As a patient or family member, you can notify your local health authorities. The quickest way is to call your local ANM, ASHA worker, or nearest Public Health Centre (PHC).',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call National Helpline (1075)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5568),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed: () => _launchUrl('tel:1075'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.email_outlined),
            label: const Text('Email AEFI Secretariat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4A5568),
              side: const BorderSide(color: Color(0xFF4A5568)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed: () => _launchUrl('mailto:aefiindia@gmail.com'),
          ),
          const Divider(height: 40),

          // 4. What to Report
          _buildSectionHeader(
            context,
            icon: Icons.checklist_rtl_outlined,
            title: 'What to Report',
          ),
          const SizedBox(height: 12),
          const Text(
            'When you call, try to have this information ready:',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Who:', 'Patient\'s name and age.'),
          _buildInfoRow(context, 'What:', 'Symptoms being experienced.'),
          _buildInfoRow(
            context,
            'When:',
            'Date/time of vaccination and when symptoms began.',
          ),
          _buildInfoRow(
            context,
            'Which:',
            'Name of vaccine(s) received, if known.',
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildEmergencyDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red.shade700),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'If this is a medical emergency, please call 108 or your doctor immediately.\nThis service is for notification only.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: const Color(0xFF4A5568)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
