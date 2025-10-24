import 'package:flutter/material.dart';
import '../services/family_service.dart';
import '../utils/string_extensions.dart';

class FamilyMemberDetailPage extends StatefulWidget {
  final int memberId;
  final String memberName;
  final bool isAdmin;

  const FamilyMemberDetailPage({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.isAdmin,
  });

  @override
  State<FamilyMemberDetailPage> createState() => _FamilyMemberDetailPageState();
}

class _FamilyMemberDetailPageState extends State<FamilyMemberDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _memberData;
  List<dynamic> _vaccines = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMemberDetails();
  }

  Future<void> _loadMemberDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetches member details and their vaccine list
      final data = await FamilyService.getFamilyMemberVaccines(widget.memberId);
      setState(() {
        _memberData = data['member'];
        _vaccines = data['vaccines'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Family Member'),
        content: Text(
          'Are you sure you want to remove ${widget.memberName} from your family? This will delete all their vaccine records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              try {
                // Calls the service to remove the member
                await FamilyService.removeFamilyMember(widget.memberId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Family member removed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Go back to overview
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // --- ADDED WIDGETS ---

  // Dialog to mark a vaccine as completed
  void _showMarkAsDoneDialog(int vaccineId, String vaccineName) {
    final dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mark '$vaccineName' as completed?"),
            const SizedBox(height: 24),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Date Administered',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                // Date picker logic similar to profile_page.dart
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  dateController.text = "${picked.toLocal()}".split(' ')[0];
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dateController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a date'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context); // Close dialog

              try {
                // --- ASSUMED API CALL ---
                // This assumes a method in your FamilyService
                await FamilyService.markVaccineAsDone(
                  vaccineId,
                  dateController.text,
                );
                // --- END ASSUMED API CALL ---

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vaccine updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _loadMemberDetails(); // Refresh the list
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Widget to build each vaccine card
  Widget _buildVaccineCard(Map<String, dynamic> vaccine, ThemeData theme) {
    final String name = vaccine['name'] ?? 'Unknown Vaccine';
    final String status = vaccine['status'] ?? 'pending';
    final String dueDate = vaccine['dueDate'] ?? 'N/A';
    final String? completedDate = vaccine['completedDate'];
    final int vaccineId = vaccine['id']; // Assuming vaccine has an ID

    final bool isCompleted = status.toLowerCase() == 'completed';

    final Color statusColor = isCompleted ? Colors.green : Colors.orange;
    final IconData statusIcon =
        isCompleted ? Icons.check_circle_outline : Icons.pending_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted
                        ? 'Completed: ${completedDate ?? 'N/A'}'
                        : 'Due: $dueDate',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Show "Mark Done" button only if the vaccine is pending
            if (!isCompleted)
              TextButton(
                onPressed: () => _showMarkAsDoneDialog(vaccineId, name),
                child: const Text('Mark Done'),
              ),
          ],
        ),
      ),
    );
  }

  // --- END ADDED WIDGETS ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: theme.colorScheme.onPrimary,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        widget.memberName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      if (!widget.isAdmin)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: theme.colorScheme.onPrimary,
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteConfirmation();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Remove Member',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox(width: 48), // Placeholder for alignment
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Member Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.onPrimary,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          theme.colorScheme.onPrimary.withOpacity(0.3),
                      child: Text(
                        widget.memberName.isNotEmpty
                            ? widget.memberName[0].toUpperCase()
                            : 'M',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_memberData != null) ...[
                    Text(
                      _memberData!['email'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onPrimary.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cake_outlined,
                          size: 14,
                          color: theme.colorScheme.onPrimary.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _memberData!['dateOfBirth'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ),
                        if (_memberData!['relationshipToAdmin'] != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onPrimary
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              // Capitalize relationship
                              (_memberData!['relationshipToAdmin'] as String)
                                  .capitalize(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // --- ADDED CONTENT AREA ---
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.primaryColor,
                        ),
                      )
                    : _errorMessage.isNotEmpty
                        ? Center(
                            // Error state, similar to family_overview_page
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error Loading Details',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _loadMemberDetails,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _vaccines.isEmpty
                            // Empty state
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.vaccines_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No Vaccines Found',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    Text(
                                      'No vaccines are scheduled for ${widget.memberName}.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            // Success state: Show vaccine list
                            : RefreshIndicator(
                                onRefresh: _loadMemberDetails,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(24.0),
                                  itemCount: _vaccines.length,
                                  itemBuilder: (context, index) {
                                    final vaccine = _vaccines[index];
                                    return _buildVaccineCard(vaccine, theme);
                                  },
                                ),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}