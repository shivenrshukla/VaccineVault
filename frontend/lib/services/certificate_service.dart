// lib/services/certificate_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_app_file/open_app_file.dart';

// Import your models
import '../models/vaccine_record.dart';
// ✅ IMPORT YOUR NEW AUTH SERVICE
import './auth_service.dart'; // Adjust path if needed

class CertificateService {
  // ⚠️ Make sure this URL is correct for your setup (see note below)
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));

  // ✅ ADD AN INSTANCE OF YOUR AUTH SERVICE
  final AuthService _authService = AuthService();

  CertificateService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // ✅ THIS IS THE FIX
          // Get the real token from your AuthService
          final token = await _authService.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Continue with the request
          return handler.next(options);
        },
      ),
    );
  }

  // This function should now work
  Future<List<CertificateStub>> getAllCertificates() async {
    try {
      final response = await _dio.get('/api/certificates/all');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => CertificateStub.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load certificates');
      }
    } on DioException catch (e) {
      print('Error in getAllCertificates: $e');
      throw Exception('Failed to load certificates: ${e.message}');
    }
  }

  // This function should also work now
  Future<CertificateStub> uploadCertificate({
    required String userVaccineId,
    required String fileName,
    String? filePath, // Null on web
    Uint8List? fileBytes, // Null on mobile
  }) async {
    try {
      FormData formData;

      if (kIsWeb) {
        if (fileBytes == null) throw Exception('File bytes are null on web');
        formData = FormData.fromMap({
          'userVaccineId': userVaccineId,
          'certificate': MultipartFile.fromBytes(fileBytes, filename: fileName),
        });
      } else {
        if (filePath == null) throw Exception('File path is null on mobile');
        formData = FormData.fromMap({
          'userVaccineId': userVaccineId,
          'certificate': await MultipartFile.fromFile(
            filePath,
            filename: fileName,
          ),
        });
      }

      final response = await _dio.post(
        '/api/certificates/upload',
        data: formData,
      );

      if (response.statusCode == 201) {
        return CertificateStub.fromJson(response.data['certificate']);
      } else {
        throw Exception('Failed to upload file');
      }
    } on DioException catch (e) {
      print('Error in uploadCertificate: $e');
      throw Exception('Failed to upload file: ${e.message}');
    }
  }

  Future<void> downloadAndOpenFile(
    int certificateId,
    String originalFileName,
  ) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'File opening is not implemented for web in this example.',
      );
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final savePath = '${directory.path}/$originalFileName';

      await _dio.download(
        '/api/certificates/download/$certificateId',
        savePath,
      );

      final result = await OpenAppFile.open(savePath);
      if (result.type != ResultType.done) {
        throw Exception('Could not open file: ${result.message}');
      }
    } on DioException catch (e) {
      print('Error in downloadAndOpenFile: $e');
      throw Exception('Failed to open file: ${e.message}');
    }
  }
}
