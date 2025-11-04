// lib/screens/vaccine_certificate_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/vaccine_record.dart';
import '../services/certificate_service.dart';

// --- NEW IMPORTS ---
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data'; // For Uint8List
// --------------------

class VaccineCertificateScreen extends StatefulWidget {
  final VaccineRecord vaccine;

  const VaccineCertificateScreen({super.key, required this.vaccine});

  @override
  State<VaccineCertificateScreen> createState() =>
      _VaccineCertificateScreenState();
}

class _VaccineCertificateScreenState extends State<VaccineCertificateScreen> {
  final CertificateService _certificateService = CertificateService();

  late List<CertificateStub> _certificates;
  bool _isUploading = false;
  bool _isLoadingFile = false; // For viewing

  @override
  void initState() {
    super.initState();
    // Copy the list from the widget to the state
    _certificates = List<CertificateStub>.from(widget.vaccine.certificates);
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: kIsWeb, // --- KEY CHANGE: Tell picker to get bytes on web
      );

      if (result != null) {
        setState(() => _isUploading = true);

        // --- PLATFORM-AWARE LOGIC ---
        String fileName = result.files.single.name;
        Uint8List? fileBytes = kIsWeb ? result.files.single.bytes : null;
        String? filePath = kIsWeb ? null : result.files.single.path;
        // ------------------------------

        // Call the updated service
        final newCertificate = await _certificateService.uploadCertificate(
          userVaccineId: widget.vaccine.id.toString(),
          fileName: fileName,
          filePath: filePath, // Will be null on web
          fileBytes: fileBytes, // Will be null on mobile
        );

        // Add the new certificate to the list
        setState(() {
          _certificates.add(newCertificate);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ Certificate uploaded for ${widget.vaccine.name}!',
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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

    setState(() => _isLoadingFile = true);
    try {
      await _certificateService.downloadAndOpenFile(
        certificate.id,
        certificate.originalFileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingFile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vaccine.name),
        backgroundColor: const Color(0xFF6B46C1),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Certificates',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload or view documents for ${widget.vaccine.name} (${widget.vaccine.doseDisplay}).',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadFile,
                    icon: _isUploading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.attach_file),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Upload New Certificate',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5FBF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 32),

                // List of uploaded files
                Text(
                  'Uploaded Files',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: _certificates.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.file_copy_outlined,
                                size: 60,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No certificates uploaded yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _certificates.length,
                          itemBuilder: (context, index) {
                            final certificate = _certificates[index];
                            final icon =
                                certificate.originalFileName.endsWith('pdf')
                                ? Icons.picture_as_pdf
                                : Icons.image;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Icon(
                                  icon,
                                  color: const Color(0xFF8B5FBF),
                                  size: 32,
                                ),
                                title: Text(
                                  certificate.originalFileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: const Text('Tap to view'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _viewCertificate(certificate),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_isLoadingFile)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Opening file...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
