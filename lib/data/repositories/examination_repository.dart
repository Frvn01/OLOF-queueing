import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:storage_client/storage_client.dart';
import '../models/clinical_examination.dart';
import '../services/supabase_service.dart';
import '../services/local_storage_service.dart';

/// Repository for Clinical Examination and Medical Diagrams (Nurse Station)
class ExaminationRepository {
  // In-memory cache for fast access & offline fallback
  final List<ClinicalExamination> _cache = [];
  bool _initialized = false;

  bool get isSupabase => SupabaseService.isConfigured;

  /// Load cached examinations
  Future<void> _ensureLoaded() async {
    if (_initialized) return;
    if (isSupabase) {
      try {
        final res = await SupabaseService.client
            .from('clinical_examinations')
            .select('*')
            .order('created_at', ascending: false);
        _cache.clear();
        for (final row in res) {
          try {
            _cache.add(ClinicalExamination.fromJson(Map<String, dynamic>.from(row)));
          } catch (e) {
            debugPrint('Error parsing examination row: $e');
          }
        }
      } catch (e) {
        debugPrint('Supabase load examinations error: $e');
      }
    }
    _initialized = true;
  }

  /// Get all examinations for a patient
  Future<List<ClinicalExamination>> getExaminationsForPatient(String patientId) async {
    await _ensureLoaded();
    if (isSupabase) {
      try {
        final res = await SupabaseService.client
            .from('clinical_examinations')
            .select('*')
            .eq('patient_id', patientId)
            .order('created_at', ascending: false);
        final list = <ClinicalExamination>[];
        for (final row in res) {
          try {
            list.add(ClinicalExamination.fromJson(Map<String, dynamic>.from(row)));
          } catch (_) {}
        }
        // Update local cache
        _cache.removeWhere((e) => e.patientId == patientId);
        _cache.addAll(list);
        return list;
      } catch (e) {
        debugPrint('Error fetching patient examinations from Supabase: $e');
      }
    }
    return _cache.where((e) => e.patientId == patientId).toList();
  }

  /// Get grouped examinations for a patient (grouped by examination_uuid)
  Future<List<Map<String, dynamic>>> getGroupedExaminations(String patientId) async {
    final list = await getExaminationsForPatient(patientId);
    final Map<String, List<ClinicalExamination>> grouped = {};
    for (final exam in list) {
      grouped.putIfAbsent(exam.examinationUuid, () => []).add(exam);
    }

    final result = <Map<String, dynamic>>[];
    for (final entry in grouped.entries) {
      final items = entry.value;
      if (items.isEmpty) continue;
      // Sort items by viewName (1, 2, 3, drawing)
      items.sort((a, b) => a.viewName.compareTo(b.viewName));
      final primary = items.first;
      result.add({
        'examination_uuid': entry.key,
        'patient_id': primary.patientId,
        'department': primary.department,
        'exam_type': primary.examType,
        'clinical_findings': primary.clinicalFindings ??
            items.firstWhere((i) => (i.clinicalFindings ?? '').isNotEmpty, orElse: () => primary).clinicalFindings,
        'created_at': primary.createdAt,
        'items': items,
        'views_count': items.length,
      });
    }

    // Sort newest first
    result.sort((a, b) => (b['created_at'] as DateTime).compareTo(a['created_at'] as DateTime));
    return result;
  }

  /// Upload diagram PNG image bytes.
  /// Under Option A (Hybrid), it saves locally to Clinic PC storage to save cloud bucket quota.
  Future<String?> uploadDiagramImage({
    required String examinationUuid,
    required String viewName,
    required Uint8List bytes,
  }) async {
    // 1. Always save a copy locally on Clinic PC
    String? localPath;
    try {
      localPath = await LocalStorageService.instance.saveDiagramLocally(
        examinationUuid: examinationUuid,
        viewName: viewName,
        bytes: bytes,
      );
    } catch (e) {
      debugPrint('Local diagram save note: $e');
    }

    if (!isSupabase) {
      return localPath ?? 'data:image/png;base64,${base64Encode(bytes)}';
    }

    try {
      final storagePath = 'examinations/$examinationUuid/view_$viewName.png';
      await SupabaseService.client.storage
          .from('clinical-diagrams')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );

      final publicUrl = SupabaseService.client.storage
          .from('clinical-diagrams')
          .getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase storage upload error (using data URI fallback): $e');
      // If bucket does not exist, exceeds quota or upload fails, fallback to inline base64 so all clients can display it
      return 'data:image/png;base64,${base64Encode(bytes)}';
    }
  }

  /// Save or update a single examination record
  Future<ClinicalExamination> saveExamination(ClinicalExamination exam) async {
    if (isSupabase) {
      try {
        await SupabaseService.client
            .from('clinical_examinations')
            .upsert(exam.toJson());
      } catch (e) {
        debugPrint('Supabase save examination error: $e');
        if (e.toString().contains('queue_entry_id') || e.toString().contains('23503')) {
          try {
            final fallback = Map<String, dynamic>.from(exam.toJson())
              ..remove('queue_entry_id');
            await SupabaseService.client
                .from('clinical_examinations')
                .upsert(fallback);
          } catch (e2) {
            debugPrint('Supabase fallback save examination error: $e2');
          }
        }
      }
    }
    // Update local cache
    final index = _cache.indexWhere((e) => e.id == exam.id);
    if (index >= 0) {
      _cache[index] = exam;
    } else {
      _cache.add(exam);
    }
    return exam;
  }

  /// Save multiple examination views for an exam session
  Future<void> saveExaminationBatch(List<ClinicalExamination> exams) async {
    if (exams.isEmpty) return;
    if (isSupabase) {
      try {
        final rows = exams.map((e) => e.toJson()).toList();
        await SupabaseService.client
            .from('clinical_examinations')
            .upsert(rows);
      } catch (e) {
        debugPrint('Supabase batch save error: $e');
        final isFkErr = e.toString().contains('queue_entry_id') || e.toString().contains('23503');
        // If batch fails, try one by one (stripping queue_entry_id if FK failed)
        for (final exam in exams) {
          try {
            final payload = Map<String, dynamic>.from(exam.toJson());
            if (isFkErr) payload.remove('queue_entry_id');
            await SupabaseService.client
                .from('clinical_examinations')
                .upsert(payload);
          } catch (_) {
            try {
              final stripped = Map<String, dynamic>.from(exam.toJson())
                ..remove('queue_entry_id');
              await SupabaseService.client
                  .from('clinical_examinations')
                  .upsert(stripped);
            } catch (_) {}
          }
        }
      }
    }
    for (final exam in exams) {
      final index = _cache.indexWhere((e) => e.id == exam.id);
      if (index >= 0) {
        _cache[index] = exam;
      } else {
        _cache.add(exam);
      }
    }
  }

  /// Delete all examination records for a given examination UUID
  Future<bool> deleteExaminationGroup(String examinationUuid) async {
    bool success = true;
    if (isSupabase) {
      try {
        await SupabaseService.client
            .from('clinical_examinations')
            .delete()
            .eq('examination_uuid', examinationUuid);
      } catch (e) {
        debugPrint('Supabase delete examination error: $e');
        success = false;
      }
    }
    _cache.removeWhere((e) => e.examinationUuid == examinationUuid);
    return success;
  }

  /// Export PNG image to local filesystem
  Future<String> exportImageToFile(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      return 'saved_web';
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$filename.png';
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    } catch (e) {
      debugPrint('Export to file error: $e');
      return '';
    }
  }
}
