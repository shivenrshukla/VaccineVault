import 'package:flutter/material.dart';

// Enum to represent the status of the vaccine dose
enum VaccineStatus { completed, due, upcoming }

class VaccineDose {
  final String vaccineName;
  final String doseInfo; // e.g., "Dose 1 of 3"
  final String recommendedAge;
  final VaccineStatus status;
  final DateTime? administeredDate;
  final DateTime dueDate;

  VaccineDose({
    required this.vaccineName,
    required this.doseInfo,
    required this.recommendedAge,
    required this.status,
    this.administeredDate,
    required this.dueDate,
  });
}

// Helper extension to get colors and icons for each status
extension VaccineStatusExtension on VaccineStatus {
  Color get color {
    switch (this) {
      case VaccineStatus.completed:
        return Colors.green.shade700;
      case VaccineStatus.due:
        return Colors.red.shade700;
      case VaccineStatus.upcoming:
        return Colors.blue.shade700;
    }
  }

  IconData get icon {
    switch (this) {
      case VaccineStatus.completed:
        return Icons.check_circle;
      case VaccineStatus.due:
        return Icons.error;
      case VaccineStatus.upcoming:
        return Icons.schedule;
    }
  }

  String get displayName {
    switch (this) {
      case VaccineStatus.completed:
        return 'Completed';
      case VaccineStatus.due:
        return 'Due';
      case VaccineStatus.upcoming:
        return 'Upcoming';
    }
  }
}
