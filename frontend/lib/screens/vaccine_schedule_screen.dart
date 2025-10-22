import 'package:flutter/material.dart';
import '../models/vaccine_schedule.dart'; // Still need the model
import 'package:intl/intl.dart';

// --- MOCK DATA ---
// Helper to get dates relative to today
final DateTime _today = DateTime.now();
DateTime _getDate(int days) => _today.add(Duration(days: days));

final List<VaccineDose> _mockScheduleData = [
  VaccineDose(
    vaccineName: 'Hepatitis B (HepB)',
    doseInfo: 'Dose 1 of 3',
    recommendedAge: 'Birth',
    status: VaccineStatus.completed,
    administeredDate: DateTime(2023, 10, 20),
    dueDate: DateTime(2023, 10, 20),
  ),
  VaccineDose(
    vaccineName: 'Hepatitis B (HepB)',
    doseInfo: 'Dose 2 of 3',
    recommendedAge: '1-2 Months',
    status: VaccineStatus.completed,
    administeredDate: DateTime(2023, 12, 21),
    dueDate: DateTime(2023, 12, 20),
  ),
  VaccineDose(
    vaccineName: 'DTaP',
    doseInfo: 'Dose 1 of 5',
    recommendedAge: '2 Months',
    status: VaccineStatus.completed,
    administeredDate: DateTime(2023, 12, 21),
    dueDate: DateTime(2023, 12, 20),
  ),
  VaccineDose(
    vaccineName: 'Hib',
    doseInfo: 'Dose 1 of 4',
    recommendedAge: '2 Months',
    status: VaccineStatus.completed,
    administeredDate: DateTime(2023, 12, 21),
    dueDate: DateTime(2023, 12, 20),
  ),
  VaccineDose(
    vaccineName: 'Polio (IPV)',
    doseInfo: 'Dose 1 of 4',
    recommendedAge: '2 Months',
    status: VaccineStatus.completed,
    administeredDate: DateTime(2023, 12, 21),
    dueDate: DateTime(2023, 12, 20),
  ),
  VaccineDose(
    vaccineName: 'PCV13',
    doseInfo: 'Dose 1 of 4',
    recommendedAge: '2 Months',
    status: VaccineStatus.completed,
    administeredDate: DateTime(2023, 12, 21),
    dueDate: DateTime(2023, 12, 20),
  ),
  VaccineDose(
    vaccineName: 'DTaP',
    doseInfo: 'Dose 2 of 5',
    recommendedAge: '4 Months',
    status: VaccineStatus.due,
    dueDate: _getDate(-10), // 10 days ago
  ),
  VaccineDose(
    vaccineName: 'Hib',
    doseInfo: 'Dose 2 of 4',
    recommendedAge: '4 Months',
    status: VaccineStatus.due,
    dueDate: _getDate(-10), // 10 days ago
  ),
  VaccineDose(
    vaccineName: 'DTaP',
    doseInfo: 'Dose 3 of 5',
    recommendedAge: '6 Months',
    status: VaccineStatus.upcoming,
    dueDate: _getDate(50), // 50 days from now
  ),
  VaccineDose(
    vaccineName: 'Hepatitis B (HepB)',
    doseInfo: 'Dose 3 of 3',
    recommendedAge: '6-18 Months',
    status: VaccineStatus.upcoming,
    dueDate: _getDate(60), // 60 days from now
  ),
  VaccineDose(
    vaccineName: 'MMR',
    doseInfo: 'Dose 1 of 2',
    recommendedAge: '12-15 Months',
    status: VaccineStatus.upcoming,
    dueDate: _getDate(180), // 6 months from now
  ),
];
// --- END MOCK DATA ---

class VaccineScheduleScreen extends StatefulWidget {
  const VaccineScheduleScreen({super.key});

  @override
  State<VaccineScheduleScreen> createState() => _VaccineScheduleScreenState();
}

class _VaccineScheduleScreenState extends State<VaccineScheduleScreen> {
  // Use the local mock data
  late List<VaccineDose> _schedule;

  @override
  void initState() {
    super.initState();
    // In a real app, you would fetch this data from your backend here in initState
    _schedule = _getSortedSchedule();
  }

  List<VaccineDose> _getSortedSchedule() {
    // Sort the list to show Due items first, then Upcoming, then Completed
    final sortedList = List<VaccineDose>.from(_mockScheduleData);
    sortedList.sort((a, b) {
      if (a.status == VaccineStatus.due && b.status != VaccineStatus.due) {
        return -1; // a (Due) comes before b
      }
      if (b.status == VaccineStatus.due && a.status != VaccineStatus.due) {
        return 1; // b (Due) comes before a
      }
      // If both are not Due, sort by due date
      return a.dueDate.compareTo(b.dueDate);
    });
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccine Schedule'),
        backgroundColor: const Color(0xFF6B46C1), // Matching card color
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _schedule.length,
        itemBuilder: (context, index) {
          final dose = _schedule[index];
          return _buildScheduleCard(dose);
        },
      ),
    );
  }

  Widget _buildScheduleCard(VaccineDose dose) {
    String formattedDate;
    if (dose.status == VaccineStatus.completed) {
      // Use 'intl' package to format the date
      formattedDate =
          'Administered: ${DateFormat.yMMMd().format(dose.administeredDate!)}';
    } else {
      formattedDate = 'Due: ${DateFormat.yMMMd().format(dose.dueDate)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Status Icon
            Icon(dose.status.icon, color: dose.status.color, size: 40.0),
            const SizedBox(width: 16.0),
            // Vaccine Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose.vaccineName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${dose.doseInfo} • Age: ${dose.recommendedAge}',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: dose.status.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Status Text
            Text(
              dose.status.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: dose.status.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
