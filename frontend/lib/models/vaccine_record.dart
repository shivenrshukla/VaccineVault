// lib/models/vaccine_record.dart

// Enum to help categorize vaccines
enum VaccineCategory { completed, scheduled, pendingUnscheduled }

// lib/models/vaccine_record.dart

// ... You may have other classes here like VaccineRecord ...

// This model now holds the richer data from our backend
class CertificateStub {
  final int id;
  final String originalFileName;
  final DateTime createdAt;
  final String vaccineName;
  final String userName;
  final bool isForFamilyMember;

  CertificateStub({
    required this.id,
    required this.originalFileName,
    required this.createdAt,
    required this.vaccineName,
    required this.userName,
    required this.isForFamilyMember,
  });

  // Factory constructor to parse the JSON from the backend
  factory CertificateStub.fromJson(Map<String, dynamic> json) {
    return CertificateStub(
      id: json['id'],
      originalFileName: json['originalFileName'] ?? 'no_name_found.err',
      createdAt: DateTime.parse(json['createdAt']),
      vaccineName: json['vaccineName'] ?? 'Unknown Vaccine',
      userName: json['userName'] ?? 'Unknown User',
      isForFamilyMember: json['isForFamilyMember'] ?? false,
    );
  }
}

class VaccineRecord {
  final int id;
  final String name;
  final String? diseaseProtectedAgainst;
  final String status;
  final String? nextDueDate;
  final String? lastDoseDate;
  final int completedDoses;
  final int? totalDoses;
  final List<CertificateStub> certificates;

  VaccineRecord({
    required this.id,
    required this.name,
    this.diseaseProtectedAgainst,
    required this.status,
    this.nextDueDate,
    this.lastDoseDate,
    required this.completedDoses,
    this.totalDoses,
    required this.certificates,
  });

  bool get isCompleted => status == 'completed';
  bool get isPending => status != 'completed';

  VaccineCategory get category {
    if (isCompleted) {
      return VaccineCategory.completed;
    }
    // Check for null and parsing
    try {
      if (isPending &&
          nextDueDate != null &&
          DateTime.parse(nextDueDate!).isAfter(DateTime.now())) {
        return VaccineCategory.scheduled;
      }
    } catch (e) {
      // Ignore invalid date formats
    }
    return VaccineCategory.pendingUnscheduled;
  }

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
        certificates:
            certificates, // ✅ FIX 1: Use 'certificates' not 'certList'
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

    // ✅ FIX 2: Add the logic to parse the certificates list
    var certList = (json['certificates'] as List? ?? [])
        .map((certJson) => CertificateStub.fromJson(certJson))
        .toList();

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
      certificates: certList, // ✅ FIX 2: Pass the list here
    );
  }
}
