import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_dept_record.dart';
import '../services/supabase_service.dart';
import '../../core/utils/helpers.dart';

/// CRUD for department-scoped patient records (patient_dept_records table).
/// Each patient can have at most one record per department (ENT / EYES).
class PatientDeptRepository {
  // Static in-memory cache shared across all screens & repository instances: key = 'patientId::DEPT'
  static final Map<String, PatientDeptRecord> _cache = {};
  static bool _prefsLoaded = false;
  static const _storageKey = 'local_patient_dept_records_v1';

  static Future<void> _ensureLoaded() async {
    if (_prefsLoaded) return;
    _prefsLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        decoded.forEach((key, val) {
          if (val is Map) {
            _cache[key] =
                PatientDeptRecord.fromJson(Map<String, dynamic>.from(val));
          }
        });
      }
    } catch (e) {
      debugPrint('PatientDeptRepo load error: $e');
    }
  }

  static Future<void> _persistCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{};
      _cache.forEach((k, v) => map[k] = v.toJson());
      await prefs.setString(_storageKey, jsonEncode(map));
    } catch (e) {
      debugPrint('PatientDeptRepo persist error: $e');
    }
  }

  bool get isSupabase => SupabaseService.isConfigured;

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Fetch the dept record for a patient, or null if not yet created.
  Future<PatientDeptRecord?> getRecord(
      String patientId, String department) async {
    await _ensureLoaded();
    final cacheKey = '$patientId::$department';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    if (isSupabase) {
      try {
        final data = await SupabaseService.client
            .from('patient_dept_records')
            .select()
            .eq('patient_id', patientId)
            .eq('department', department)
            .maybeSingle();
        if (data != null) {
          final record =
              PatientDeptRecord.fromJson(Map<String, dynamic>.from(data));
          _cache[cacheKey] = record;
          return record;
        }
      } catch (e) {
        debugPrint('PatientDeptRepo getRecord error: $e');
      }
    }

    return null;
  }

  /// Fetch all dept records for a patient (e.g. to show ENT + EYES tabs).
  Future<List<PatientDeptRecord>> getAllRecords(String patientId) async {
    await _ensureLoaded();
    final results = <PatientDeptRecord>[];

    if (isSupabase) {
      try {
        final data = await SupabaseService.client
            .from('patient_dept_records')
            .select()
            .eq('patient_id', patientId)
            .order('created_at');
        for (final row in data as List) {
          final r =
              PatientDeptRecord.fromJson(Map<String, dynamic>.from(row as Map));
          _cache['${r.patientId}::${r.department}'] = r;
          results.add(r);
        }
      } catch (e) {
        debugPrint('PatientDeptRepo getAllRecords error: $e');
      }
    }

    // Fill from cache for any missing
    for (final r in _cache.values) {
      if (r.patientId == patientId &&
          !results.any((x) => x.department == r.department)) {
        results.add(r);
      }
    }

    return results;
  }

  // ── Write ───────────────────────────────────────────────────────────────────

  /// Insert or update a dept record (upsert on patient_id + department).
  Future<PatientDeptRecord> upsert(PatientDeptRecord record) async {
    await _ensureLoaded();
    final cacheKey = '${record.patientId}::${record.department}';

    if (isSupabase) {
      try {
        final payload = record.toSupabaseJson();
        final result = await SupabaseService.client
            .from('patient_dept_records')
            .upsert(payload,
                onConflict: 'patient_id,department', ignoreDuplicates: false)
            .select()
            .single();
        final saved =
            PatientDeptRecord.fromJson(Map<String, dynamic>.from(result));
        _cache[cacheKey] = saved;
        await _persistCache();
        return saved;
      } catch (e) {
        debugPrint('PatientDeptRepo upsert error: $e');
        // Fallback: try a plain insert, then update if conflict
        try {
          await SupabaseService.client
              .from('patient_dept_records')
              .insert(record.toSupabaseJson());
        } catch (_) {
          try {
            await SupabaseService.client
                .from('patient_dept_records')
                .update(record.toSupabaseJson())
                .eq('patient_id', record.patientId)
                .eq('department', record.department);
          } catch (e2) {
            debugPrint('PatientDeptRepo fallback update error: $e2');
          }
        }
      }
    }

    _cache[cacheKey] = record;
    await _persistCache();
    return record;
  }

  /// Create a brand-new dept record (first consultation for this dept).
  Future<PatientDeptRecord> create({
    required String patientId,
    required String department,
    String? chiefComplaint,
    String? historyOfPresentIllness,
    String? pastMedicalHistory,
    List<PmhCondition>? pmhConditions,
    bool isFirstTime = true,
    String? assignedDoctor,
    String? assignedRoom,
  }) async {
    final record = PatientDeptRecord(
      id: IdGenerator.generateUuid(),
      patientId: patientId,
      department: department,
      chiefComplaint: chiefComplaint,
      historyOfPresentIllness: historyOfPresentIllness,
      pastMedicalHistory: pastMedicalHistory,
      pmhConditions: pmhConditions,
      isFirstTime: isFirstTime,
      assignedDoctor: assignedDoctor,
      assignedRoom: assignedRoom,
    );
    return upsert(record);
  }

  // ── Cache management ────────────────────────────────────────────────────────

  /// Invalidate the cache for a specific patient+dept so next read re-fetches.
  void invalidate(String patientId, String department) {
    _cache.remove('$patientId::$department');
  }

  /// Clear all cached records.
  void clearCache() => _cache.clear();
}
