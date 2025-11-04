// lib/screens/my_certificates_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/vaccine_record.dart'; // For CertificateStub
import '../services/certificate_service.dart';
import 'select_vaccine_screen.dart';
import 'package:intl/intl.dart'; // ✅ ADDED for date formatting

// --- NEW IMPORTS ---
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data'; // For Uint8List
// --------------------

class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({super.key});

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen> {
  final CertificateService _certificateService = CertificateService();
  bool _isLoading = true;
  String? _error;

  List<CertificateStub> _allCertificates = [];
  bool _isUploading = false; // State for upload button

  @override
  void initState() {
    super.initState();
    _loadAllCertificates();
  }

  Future<void> _loadAllCertificates() async {
    try {
      // ✅ Implement the API call
      final certificates = await _certificateService.getAllCertificates();
      if (mounted) {
        setState(() {
          _allCertificates = certificates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load certificates: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      // 1. Pick a file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: kIsWeb, // --- KEY CHANGE: Tell picker to get bytes on web
      );

      if (result == null) {
        return; // User canceled
      }

      // --- PLATFORM-AWARE LOGIC ---
      String fileName = result.files.single.name;
      Uint8List? fileBytes = kIsWeb ? result.files.single.bytes : null;
      String? filePath = kIsWeb ? null : result.files.single.path;
      // ------------------------------

      // 2. Navigate to get the vaccine ID
      if (!mounted) return;
      final int? selectedUserVaccineId = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SelectVaccineScreen()),
      );

      // 3. Check if a vaccine was selected
      if (selectedUserVaccineId == null) return; // User canceled selection

      // 4. Proceed with upload
      setState(() => _isUploading = true);

      final newCertificate = await _certificateService.uploadCertificate(
        userVaccineId: selectedUserVaccineId.toString(),
        fileName: fileName,
        filePath: filePath, // Will be null on web
        fileBytes: fileBytes, // Will be null on mobile
      );

      // 5. Add to local list and show success
      // ✅ Add to the beginning of the list to show newest first
      setState(() {
        _allCertificates.insert(0, newCertificate);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $fileName uploaded!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _viewCertificate(CertificateStub certificate) async {
    // --- WEB CHECK ---
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'File viewing on web opens in a new tab (not implemented).',
          ),
          backgroundColor: Colors.blue,
        ),
      );
      // You would use url_launcher here to open the download URL
      return;
    }
    // -----------------

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
      ),
    );

    try {
      await _certificateService.downloadAndOpenFile(
        certificate.id,
        certificate.originalFileName,
      );
      Navigator.pop(context); // Close loading
    } catch (e) {
      Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: const Color(0xFF6B46C1),
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadFile,
        label: Text(_isUploading ? 'Uploading...' : 'Upload'),
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.attach_file),
        backgroundColor: const Color(0xFF8B5FBF),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    if (_allCertificates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_copy_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No certificates found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the Upload button to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Build a list view of all certificates
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding for FAB
      itemCount: _allCertificates.length,
      itemBuilder: (context, index) {
        final certificate = _allCertificates[index];
        final icon = certificate.originalFileName.endsWith('pdf')
            ? Icons.picture_as_pdf
            : Icons.image;

        // ✅ Format the date
        final String formattedDate = DateFormat.yMMMd().format(
          certificate.createdAt,
        );

        // ✅ Create a more informative subtitle
        String subtitle =
            '${certificate.vaccineName} • ${certificate.userName}';
        if (certificate.isForFamilyMember) {
          subtitle += ' (Family)';
        }
        subtitle += '\nUploaded: $formattedDate';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(icon, color: const Color(0xFF8B5FBF), size: 32),
            title: Text(
              certificate.originalFileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // ✅ Use new subtitle
            subtitle: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true, // Allow subtitle to wrap
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _viewCertificate(certificate),
          ),
        );
      },
    );
  }
}
