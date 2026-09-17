import 'dart:convert';
import 'dart:io';
import '../../core/constants/api_config.dart';

/// Service responsible for communicating with the clinic's local server room PC
/// (FastAPI backend at e.g. 192.168.100.17:8080).
///
/// Used for storing large binary assets:
/// - Patient webcam & registration photos
/// - Doctor/Nurse clinical canvas drawings (Eye, Ear, Nose, Throat)
/// - Lab attachments, imaging, and diagnostic PDF reports
class LocalStorageApiService {
  static final LocalStorageApiService instance = LocalStorageApiService._();
  LocalStorageApiService._();

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 4);

  /// Checks if the local storage server is online and responding.
  Future<Map<String, dynamic>?> checkHealth() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/health');
      final request = await _client.getUrl(uri).timeout(const Duration(seconds: 3));
      final response = await request.close().timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Quick boolean check if the server room PC is reachable.
  Future<bool> isAvailable() async {
    final health = await checkHealth();
    return health != null &&
        (health['status'] == 'ok' || health['status'] == 'healthy');
  }

  /// Uploads a photo file (e.g. webcam capture or profile photo) to the local server.
  ///
  /// Returns the server response containing `url`, `filename`, `file_id`, etc.
  Future<Map<String, dynamic>> uploadPhoto({
    required File file,
    String? patientId,
  }) async {
    return _uploadMultipartFile(
      file: file,
      category: 'photos',
      patientId: patientId,
    );
  }

  /// Uploads an attachment or lab report to the local server.
  Future<Map<String, dynamic>> uploadAttachment({
    required File file,
    String? patientId,
    String? notes,
  }) async {
    return _uploadMultipartFile(
      file: file,
      category: 'attachments',
      patientId: patientId,
      notes: notes,
    );
  }

  /// Saves a base64-encoded clinical canvas drawing (Eye, Ear, Nose, or Throat)
  /// directly to the server room PC without consuming Supabase storage.
  ///
  /// [organType] should be 'eye', 'ear', 'nose', or 'throat'.
  /// [base64Png] is the PNG data URL or raw base64 string.
  Future<Map<String, dynamic>> saveClinicalDrawing({
    required String patientId,
    required String organType,
    required String base64Png,
    String? notes,
    String? doctorId,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/drawings/save');
      final request = await _client.postUrl(uri).timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.json;

      final payload = jsonEncode({
        'patient_id': patientId,
        'organ_type': organType,
        'drawing_base64': base64Png,
        'notes': notes ?? '',
        'doctor_id': doctorId ?? '',
      });

      request.write(payload);
      final response = await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        throw Exception('Server error (${response.statusCode}): $responseBody');
      }
    } catch (e) {
      throw Exception('Failed to save clinical drawing to local server: $e');
    }
  }

  /// Fetches all files, drawings, and attachments stored locally for a given patient.
  Future<Map<String, dynamic>> getPatientFiles(String patientId) async {
    try {
      final encodedId = Uri.encodeComponent(patientId);
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/files/patient/$encodedId');
      final request = await _client.getUrl(uri).timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return jsonDecode(body) as Map<String, dynamic>;
      } else {
        throw Exception('Server returned ${response.statusCode}: $body');
      }
    } catch (e) {
      throw Exception('Failed to retrieve patient files: $e');
    }
  }

  /// Deletes a file from the local server room storage.
  Future<bool> deleteFile({
    required String category,
    required String filename,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/files/$category/$filename');
      final request = await _client.deleteUrl(uri).timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Helper to perform multipart/form-data upload using standard `dart:io`.
  Future<Map<String, dynamic>> _uploadMultipartFile({
    required File file,
    required String category,
    String? patientId,
    String? notes,
  }) async {
    final queryParams = <String, String>{
      'category': category,
    };
    if (patientId != null && patientId.isNotEmpty) {
      queryParams['patient_id'] = patientId;
    }
    if (notes != null && notes.isNotEmpty) {
      queryParams['notes'] = notes;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/files/upload').replace(
      queryParameters: queryParams,
    );

    final boundary = '----WebKitFormBoundary${DateTime.now().millisecondsSinceEpoch}';
    final request = await _client.postUrl(uri).timeout(const Duration(seconds: 30));

    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );

    final fileName = file.path.split(Platform.isWindows ? r'\' : '/').last;
    final fileBytes = await file.readAsBytes();

    // Build multipart body
    final header = '--$boundary\r\n'
        'Content-Disposition: form-data; name="file"; filename="$fileName"\r\n'
        'Content-Type: ${_lookupMime(fileName)}\r\n\r\n';
    final footer = '\r\n--$boundary--\r\n';

    request.add(utf8.encode(header));
    request.add(fileBytes);
    request.add(utf8.encode(footer));

    final response = await request.close().timeout(const Duration(seconds: 30));
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    } else {
      throw Exception('Upload failed (${response.statusCode}): $body');
    }
  }

  String _lookupMime(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
