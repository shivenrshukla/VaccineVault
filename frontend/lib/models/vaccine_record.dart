// lib/models/vaccine_record.dart

// Enum to help categorize vaccines
enum VaccineCategory { completed, scheduled, pendingUnscheduled }

class VaccineRecord {
  final int id;
  final String name;
  final String? diseaseProtectedAgainst;
  final String status;
  final String? nextDueDate;
  final String? lastDoseDate;
  final int completedDoses;
  final int? totalDoses;

  // ✅ ADD THIS CONSTRUCTOR
  VaccineRecord({
    required this.id,
    required this.name,
    this.diseaseProtectedAgainst,
    required this.status,
    this.nextDueDate,
    this.lastDoseDate,
    required this.completedDoses,
    this.totalDoses,
  });

  bool get isCompleted => status == 'completed';
  bool get isPending => status != 'completed';

  VaccineCategory get category {
    if (isCompleted) {
      return VaccineCategory.completed;
    }
    if (isPending &&
        nextDueDate != null &&
        DateTime.parse(nextDueDate!).isAfter(DateTime.now())) {
      return VaccineCategory.scheduled;
    }
    return VaccineCategory.pendingUnscheduled;
  }

  // ✅ ADD THIS GETTER
  /// Creates a "fake" completed record from a pending one.
  VaccineRecord? get completedPart {
    // If it's pending AND has completed doses, create a fake "completed" version
    if (isPending && completedDoses > 0) {
      return VaccineRecord(
        id: id,
        name: name,
        diseaseProtectedAgainst: diseaseProtectedAgainst,
        status: 'completed', // Fake the status
        nextDueDate: nextDueDate,
        lastDoseDate: lastDoseDate,
        completedDoses: completedDoses,
        totalDoses: totalDoses,
      );
    }
    return null;
  }

  String get doseDisplay {
    // For a "fake" completed part, show only the completed dose count
    if (status == 'completed' && (totalDoses ?? 0) > completedDoses) {
      if (totalDoses != null) {
        return 'Dose $completedDoses of $totalDoses - Taken';
      } else {
        return 'Dose $completedDoses - Taken';
      }
    }

    // --- Original Logic ---
    if (isCompleted) {
      if (totalDoses != null) {
        return 'Dose $completedDoses of $totalDoses - Complete';
      } else {
        return 'Dose $completedDoses - Complete';
      }
    } else {
      final nextDose = completedDoses + 1;
      if (totalDoses != null) {
        return 'Dose $nextDose of $totalDoses';
      } else {
        return 'Dose $nextDose';
      }
    }
  }

  factory VaccineRecord.fromJson(Map<String, dynamic> json) {
    final vaccineInfo = json['Vaccine'] as Map<String, dynamic>?;

    int? totalDoses;
    if (vaccineInfo != null && vaccineInfo['numberOfDoses'] != null) {
      totalDoses = vaccineInfo['numberOfDoses'] as int?;
    }

    return VaccineRecord(
      id: json['id'] as int,
      name: vaccineInfo?['name'] as String? ?? 'Unknown Vaccine',
      diseaseProtectedAgainst:
          vaccineInfo?['diseaseProtectedAgainst'] as String?,
      status: json['status'] as String,
      nextDueDate: json['nextDueDate'] as String?,
      lastDoseDate: json['lastDoseDate'] as String?,
      completedDoses: json['completedDoses'] as int? ?? 0,
      totalDoses: totalDoses,
    );
  }
}
