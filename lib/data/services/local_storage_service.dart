import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service to store clinical diagrams, patient photos, and database backups
/// locally on the Clinic PC to avoid exhausting Supabase Cloud Storage quotas.
class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance ??= LocalStorageService._();

  LocalStorageService._();

  Directory? _baseDir;

  /// Initialize local storage directory
  Future<Directory> get baseDirectory async {
    if (_baseDir != null) return _baseDir!;
    if (kIsWeb) {
      throw UnsupportedError('Local file storage is not supported on web browsers.');
    }
    final docDir = await getApplicationDocumentsDirectory();
    final clinicDir = Directory('${docDir.path}/OLOF_Clinic_Storage');
    if (!await clinicDir.exists()) {
      await clinicDir.create(recursive: true);
    }
    _baseDir = clinicDir;
    return _baseDir!;
  }

  /// Save diagram image bytes locally on the Clinic PC.
  /// Returns the local file path.
  Future<String> saveDiagramLocally({
    required String examinationUuid,
    required String viewName,
    required Uint8List bytes,
  }) async {
    if (kIsWeb) {
      // Fallback for Web: inline base64 Data URI
      return 'data:image/png;base64,${base64Encode(bytes)}';
    }

    try {
      final base = await baseDirectory;
      final diagramsDir = Directory('${base.path}/diagrams/$examinationUuid');
      if (!await diagramsDir.exists()) {
        await diagramsDir.create(recursive: true);
      }
      final file = File('${diagramsDir.path}/view_$viewName.png');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Error saving diagram locally: $e');
      // Fallback to data URI
      return 'data:image/png;base64,${base64Encode(bytes)}';
    }
  }

  /// Save patient photo locally on the Clinic PC.
  /// Returns the local file path.
  Future<String> savePhotoLocally({
    required String patientId,
    required Uint8List bytes,
    String ext = 'jpg',
  }) async {
    if (kIsWeb) {
      return 'data:image/$ext;base64,${base64Encode(bytes)}';
    }

    try {
      final base = await baseDirectory;
      final photosDir = Directory('${base.path}/photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final file = File('${photosDir.path}/patient_$patientId.$ext');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Error saving photo locally: $e');
      return 'data:image/$ext;base64,${base64Encode(bytes)}';
    }
  }

  /// Save staff QR badge PNG locally on Clinic PC.
  /// Returns the local file path.
  Future<String> saveStaffBadgeLocally({
    required String staffId,
    required String staffName,
    required Uint8List bytes,
  }) async {
    if (kIsWeb) {
      return 'data:image/png;base64,${base64Encode(bytes)}';
    }

    try {
      final base = await baseDirectory;
      final badgesDir = Directory('${base.path}/staff_badges');
      if (!await badgesDir.exists()) {
        await badgesDir.create(recursive: true);
      }
      final cleanName = staffName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${badgesDir.path}/badge_${cleanName}_$staffId.png');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Error saving staff badge locally: $e');
      return '';
    }
  }

  /// Get storage usage statistics on Clinic PC
  Future<Map<String, dynamic>> getStorageUsage() async {
    if (kIsWeb) {
      return {
        'totalFiles': 0,
        'sizeBytes': 0,
        'formattedSize': '0 MB (Web)',
        'location': 'Browser In-Memory/IndexedDB',
      };
    }

    try {
      final base = await baseDirectory;
      int totalFiles = 0;
      int totalBytes = 0;

      if (await base.exists()) {
        await for (final entity in base.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalFiles++;
            totalBytes += await entity.length();
          }
        }
      }

      final mb = (totalBytes / (1024 * 1024)).toStringAsFixed(2);
      return {
        'totalFiles': totalFiles,
        'sizeBytes': totalBytes,
        'formattedSize': '$mb MB',
        'location': base.path,
      };
    } catch (e) {
      return {
        'totalFiles': 0,
        'sizeBytes': 0,
        'formattedSize': 'Unknown',
        'location': 'Error loading location',
      };
    }
  }

  /// Export clinic backup to local JSON file
  Future<String> exportBackupFile({
    required List<Map<String, dynamic>> patients,
    required List<Map<String, dynamic>> queueEntries,
    required List<Map<String, dynamic>> examinations,
  }) async {
    final base = await baseDirectory;
    final backupsDir = Directory('${base.path}/backups');
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${backupsDir.path}/olof_backup_$timestamp.json');

    final data = {
      'clinic': 'Our Lady of Fatima Eye Ear Nose Throat Center',
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'patients': patients,
      'queue_entries': queueEntries,
      'examinations': examinations,
    };

    await file.writeAsString(jsonEncode(data), flush: true);
    return file.path;
  }
}
