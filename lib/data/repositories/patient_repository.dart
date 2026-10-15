import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../models/vital_signs.dart';
import '../models/visit_record.dart';
import '../services/supabase_service.dart';
import '../services/local_storage_service.dart';
import '../../core/utils/helpers.dart';

/// Patient CRUD operations — Supabase with localStorage fallback
class PatientRepository {
  // In-memory cache for fast access
  List<Patient> _patients = [];
  List<VisitRecord> _visits = [];
  bool _loaded = false;

  static const _patientVitalsStorageKey = 'cached_patient_vitals_v1';
  static final Map<String, Map<String, dynamic>> _vitalsCache = {};
  static bool _vitalsCacheLoaded = false;

  static const _patientVisitsStorageKey = 'cached_patient_visits_v1';
  static final Map<String, List<Map<String, dynamic>>> _patientVisitsCache = {};
  static bool _patientVisitsLoaded = false;

  static Future<void> _ensureVisitsLoaded() async {
    if (_patientVisitsLoaded) return;
    _patientVisitsLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_patientVisitsStorageKey);
      if (raw != null) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        decoded.forEach((key, val) {
          if (val is List) {
            _patientVisitsCache[key] =
                val.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          }
        });
      }
    } catch (e) {
      debugPrint('PatientRepository visits cache load error: $e');
    }
  }

  static Future<void> _persistVisitsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_patientVisitsStorageKey, jsonEncode(_patientVisitsCache));
    } catch (e) {
      debugPrint('PatientRepository visits persist error: $e');
    }
  }

  static Future<void> _ensureVitalsLoaded() async {
    if (_vitalsCacheLoaded) return;
    _vitalsCacheLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_patientVitalsStorageKey);
      if (raw != null) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        decoded.forEach((key, val) {
          if (val is Map) {
            _vitalsCache[key] = Map<String, dynamic>.from(val);
          }
        });
      }
    } catch (e) {
      debugPrint('PatientRepository vitals cache load error: $e');
    }
  }

  static Future<void> _persistVitalsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_patientVitalsStorageKey, jsonEncode(_vitalsCache));
    } catch (e) {
      debugPrint('PatientRepository vitals persist error: $e');
    }
  }

  bool get isSupabase => SupabaseService.isConfigured;

  /// Load all patients
  Future<List<Patient>> getPatients({bool forceRefresh = false}) async {
    if (!_loaded || forceRefresh) await _loadFromStorage();
    return List.unmodifiable(_patients);
  }

  /// Get a single patient by ID (from in-memory cache)
  Future<Patient?> getPatient(String id) async {
    if (!_loaded) await _loadFromStorage();
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Fetch a single patient by ID directly from Supabase (bypasses stale cache)
  Future<Patient?> fetchPatient(String id) async {
    await _ensureVitalsLoaded();
    if (isSupabase) {
      try {
        final data = await SupabaseService.client
            .from('patients')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (data != null) {
          var p = Patient.fromJson(Map<String, dynamic>.from(data as Map));
          if (p.vitalSigns == null && _vitalsCache.containsKey(id)) {
            p = p.copyWith(vitalSigns: VitalSigns.fromJson(_vitalsCache[id]!));
          } else if (p.vitalSigns != null) {
            _vitalsCache[id] = p.vitalSigns!.toJson();
            _persistVitalsCache();
          }
          final idx = _patients.indexWhere((x) => x.id == id);
          if (idx >= 0) {
            _patients[idx] = p;
          } else {
            _patients.add(p);
          }
          await _saveToStorage();
          return p;
        }
      } catch (e) {
        debugPrint('Supabase fetchPatient error: $e');
      }
    }
    return getPatient(id);
  }

  /// Get patient by patient number
  Future<Patient?> getPatientByNo(String patientNo) async {
    if (!_loaded) await _loadFromStorage();
    final cleanNo = patientNo.trim().toUpperCase();
    if (cleanNo.isEmpty) return null;
    try {
      return _patients.firstWhere(
        (p) => p.patientNo.trim().toUpperCase() == cleanNo,
      );
    } catch (_) {}

    // Fallback: search Supabase directly
    if (isSupabase) {
      try {
        final data = await SupabaseService.client
            .from('patients')
            .select()
            .ilike('patient_no', cleanNo)
            .maybeSingle();
        if (data != null) {
          final p = Patient.fromJson(Map<String, dynamic>.from(data as Map));
          final idx = _patients.indexWhere((x) => x.id == p.id);
          if (idx >= 0) {
            _patients[idx] = p;
          } else {
            _patients.add(p);
          }
          await _saveToStorage();
          return p;
        }
      } catch (e) {
        debugPrint('Supabase getPatientByNo error: $e');
      }
    }
    return null;
  }

  /// Search patients by name, patient number, or phone number
  Future<List<Patient>> searchPatients(String query) async {
    if (!_loaded) await _loadFromStorage();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    // Split words to support multi-token searches like "Juan Cruz" or partial ID
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    bool matchesPatient(Patient p) {
      final name = p.fullName.toLowerCase();
      final pNo = p.patientNo.toLowerCase();
      final fName = p.firstName.toLowerCase();
      final lName = p.lastName.toLowerCase();
      final contact = p.contactNumber.toLowerCase();
      final allText = '$name $pNo $fName $lName $contact';
      return tokens.every((token) => allText.contains(token));
    }

    final localResults = _patients.where(matchesPatient).toList();

    // Also query Supabase if available so newly registered patients on other devices are found
    if (isSupabase) {
      try {
        final data = await SupabaseService.client
            .from('patients')
            .select()
            .or('full_name.ilike.%$q%,patient_no.ilike.%$q%,first_name.ilike.%$q%,last_name.ilike.%$q%,contact_number.ilike.%$q%')
            .limit(25);
        final fetched = (data as List)
            .map((item) => Patient.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        for (final p in fetched) {
          if (!localResults.any((r) => r.id == p.id)) {
            localResults.add(p);
          }
          final idx = _patients.indexWhere((x) => x.id == p.id);
          if (idx >= 0) {
            _patients[idx] = p;
          } else {
            _patients.add(p);
          }
        }
      } catch (e) {
        debugPrint('Supabase searchPatients error: $e');
      }
    }

    return localResults;
  }

  /// Add a new patient
  Future<Patient> addPatient(Patient patient) async {
    if (isSupabase) {
      try {
        await SupabaseService.client
            .from('patients')
            .insert(patient.toSupabaseJson());
      } catch (e) {
        debugPrint('Supabase insert error: $e');
        try {
          final fallback = Map<String, dynamic>.from(patient.toSupabaseJson());
          final errStr = e.toString();
          final match = RegExp(r"Could not find the '([^']+)' column").firstMatch(errStr);
          if (match != null) {
            fallback.remove(match.group(1));
          }
          fallback.remove('vital_signs');
          if (errStr.contains('is_first_time')) fallback.remove('is_first_time');
          if (errStr.contains('assigned_doctor')) fallback.remove('assigned_doctor');
          if (errStr.contains('assigned_room')) fallback.remove('assigned_room');
          if (errStr.contains('chief_complaint')) fallback.remove('chief_complaint');
          if (errStr.contains('history_of_present_illness')) fallback.remove('history_of_present_illness');
          if (errStr.contains('past_medical_history')) fallback.remove('past_medical_history');
          await SupabaseService.client.from('patients').insert(fallback);
        } catch (e2) {
          debugPrint('Supabase fallback insert error: $e2');
        }
      }
    }
    _patients.add(patient);
    await _saveToStorage();
    return patient;
  }

  /// Update a patient
  Future<Patient> updatePatient(Patient patient) async {
    await _ensureVitalsLoaded();
    if (patient.vitalSigns != null) {
      _vitalsCache[patient.id] = patient.vitalSigns!.toJson();
      _persistVitalsCache();
    }

    if (isSupabase) {
      try {
        final payload = Map<String, dynamic>.from(patient.toSupabaseJson());
        if (patient.vitalSigns != null) {
          payload['vital_signs'] = patient.vitalSigns!.toJson();
        }
        await SupabaseService.client
            .from('patients')
            .update(payload)
            .eq('id', patient.id);
      } catch (e) {
        debugPrint('Supabase update error: $e');
        try {
          final fallback = Map<String, dynamic>.from(patient.toSupabaseJson());
          final errStr = e.toString();
          final match = RegExp(r"Could not find the '([^']+)' column").firstMatch(errStr);
          if (match != null) {
            fallback.remove(match.group(1));
          }
          fallback.remove('vital_signs');
          if (errStr.contains('is_first_time')) fallback.remove('is_first_time');
          if (errStr.contains('assigned_doctor')) fallback.remove('assigned_doctor');
          if (errStr.contains('assigned_room')) fallback.remove('assigned_room');
          await SupabaseService.client
              .from('patients')
              .update(fallback)
              .eq('id', patient.id);
        } catch (e2) {
          debugPrint('Supabase fallback update error: $e2');
        }
      }
    }
    final idx = _patients.indexWhere((p) => p.id == patient.id);
    if (idx >= 0) _patients[idx] = patient;
    await _saveToStorage();
    return patient;
  }

  /// Delete a patient record and their visit history
  Future<void> deletePatient(String patientId) async {
    if (isSupabase) {
      try {
        await SupabaseService.client
            .from('patients')
            .delete()
            .eq('id', patientId);
      } catch (e) {
        debugPrint('Supabase delete patient error: $e');
      }
    }
    _patients.removeWhere((p) => p.id == patientId);
    _visits.removeWhere((v) => v.patientId == patientId);
    await _saveToStorage();
  }

  /// Get visit history for a patient (from in-memory cache or local SharedPreferences)
  Future<List<VisitRecord>> getVisitHistory(String patientId) async {
    await _ensureVisitsLoaded();
    if (!_loaded) await _loadFromStorage();
    if (!_visits.any((v) => v.patientId == patientId) &&
        _patientVisitsCache.containsKey(patientId)) {
      final cached = _patientVisitsCache[patientId]!
          .map((j) => VisitRecord.fromJson(j))
          .toList();
      _visits.addAll(cached);
    }
    return _visits.where((v) => v.patientId == patientId).toList()
      ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
  }

  /// Get all visit records across all patients
  Future<List<VisitRecord>> getAllVisitRecords() async {
    await _ensureVisitsLoaded();
    if (!_loaded) await _loadFromStorage();
    return List.unmodifiable(_visits);
  }

  /// Fetch visit history directly from Supabase (fresh, bypasses cache).
  /// Falls back to the local cache if Supabase is not available.
  Future<List<VisitRecord>> fetchVisitHistory(String patientId) async {
    await _ensureVisitsLoaded();
    if (isSupabase) {
      try {
        final data = await SupabaseService.client
            .from('visit_records')
            .select()
            .eq('patient_id', patientId)
            .order('visit_date', ascending: false);
        final fetched =
            (data as List).map((j) => VisitRecord.fromJson(j)).toList();

        // Merge fresh records into local cache so un-synced visits are never wiped
        final existingForPatient =
            _visits.where((v) => v.patientId == patientId).toList();
        final Map<String, VisitRecord> merged = {};
        for (final v in fetched) {
          merged[v.id] = v;
        }
        for (final v in existingForPatient) {
          merged.putIfAbsent(v.id, () => v);
        }
        final result = merged.values.toList()
          ..sort((a, b) => b.visitDate.compareTo(a.visitDate));

        _visits.removeWhere((v) => v.patientId == patientId);
        _visits.addAll(result);

        // Update local SharedPreferences cache
        _patientVisitsCache[patientId] =
            result.map((v) => v.toJson()).toList();
        _persistVisitsCache();

        return result;
      } catch (e) {
        debugPrint('Supabase fetchVisitHistory error: $e');
      }
    }
    // Fallback to cache
    return getVisitHistory(patientId);
  }

  /// Add a visit record
  Future<void> addVisitRecord(VisitRecord visit) async {
    await _ensureVisitsLoaded();
    if (isSupabase) {
      try {
        await SupabaseService.client
            .from('visit_records')
            .insert(visit.toSupabaseJson());
      } catch (e) {
        debugPrint('Supabase insert visit error: $e');
        try {
          final fallback = Map<String, dynamic>.from(visit.toSupabaseJson());
          final errStr = e.toString();
          final match =
              RegExp(r"Could not find the '([^']+)' column").firstMatch(errStr);
          if (match != null) {
            fallback.remove(match.group(1));
          }
          if (errStr.contains('assigned_doctor')) {
            fallback.remove('assigned_doctor');
          }
          if (errStr.contains('assigned_room')) {
            fallback.remove('assigned_room');
          }
          if (errStr.contains('chief_complaint')) {
            fallback.remove('chief_complaint');
          }
          if (errStr.contains('diagnosis')) {
            fallback.remove('diagnosis');
          }
          await SupabaseService.client
              .from('visit_records')
              .insert(fallback);
        } catch (e2) {
          debugPrint('Supabase fallback insert visit error: $e2');
        }
      }
    }
    final existingIdx = _visits.indexWhere((v) => v.id == visit.id);
    if (existingIdx >= 0) {
      _visits[existingIdx] = visit;
    } else {
      _visits.add(visit);
    }

    _patientVisitsCache.putIfAbsent(visit.patientId, () => []);
    _patientVisitsCache[visit.patientId]!
        .removeWhere((v) => v['id'] == visit.id);
    _patientVisitsCache[visit.patientId]!.add(visit.toJson());
    await _persistVisitsCache();
    await _saveToStorage();
  }

  /// Save a patient photo.
  /// Under Option A (Local Storage), saves directly to the Clinic PC hard drive
  /// or returns a data URI, completely bypassing Supabase Cloud Storage.
  Future<String?> uploadPhoto(String patientId, Uint8List bytes, String fileName) async {
    final ext = fileName.split('.').last.toLowerCase();
    try {
      final localPath = await LocalStorageService.instance.savePhotoLocally(
        patientId: patientId,
        bytes: bytes,
        ext: ext,
      );
      debugPrint('Patient photo saved to local Clinic PC storage: $localPath');
      return localPath;
    } catch (e) {
      debugPrint('Local photo save error (fallback to data URI): $e');
      return 'data:image/$ext;base64,${base64Encode(bytes)}';
    }
  }

  /// Get next patient number sequence
  int get nextPatientSequence => _patients.length + 1;

  /// Generate a new patient ID
  String generatePatientId() => IdGenerator.generatePatientId();

  // ── Local storage (web: localStorage, mobile: SharedPreferences fallback) ──

  Future<void> _loadFromStorage() async {
    await _ensureVitalsLoaded();
    if (isSupabase) {
      try {
        final pData =
            await SupabaseService.client.from('patients').select().order('created_at');
        final parsedPatients = <Patient>[];
        for (final j in pData as List) {
          try {
            var patient = Patient.fromJson(Map<String, dynamic>.from(j as Map));
            if (patient.vitalSigns == null && _vitalsCache.containsKey(patient.id)) {
              patient = patient.copyWith(
                vitalSigns: VitalSigns.fromJson(_vitalsCache[patient.id]!),
              );
            } else if (patient.vitalSigns != null) {
              _vitalsCache[patient.id] = patient.vitalSigns!.toJson();
            }
            parsedPatients.add(patient);
          } catch (err) {
            debugPrint('Notice: patient parse error for row: $err');
          }
        }
        _persistVitalsCache();
        _patients = parsedPatients;

        await _ensureVisitsLoaded();
        try {
          final vData = await SupabaseService.client
              .from('visit_records')
              .select()
              .order('visit_date');
          final parsedVisits = <VisitRecord>[];
          for (final j in vData as List) {
            try {
              parsedVisits.add(VisitRecord.fromJson(Map<String, dynamic>.from(j as Map)));
            } catch (vErr) {
              debugPrint('Notice: visit_record parse error: $vErr');
            }
          }
          // Merge with any locally cached visits so offline visits aren't lost
          final Map<String, VisitRecord> merged = {};
          for (final v in parsedVisits) {
            merged[v.id] = v;
          }
          for (final vList in _patientVisitsCache.values) {
            for (final j in vList) {
              try {
                final v = VisitRecord.fromJson(j);
                merged.putIfAbsent(v.id, () => v);
              } catch (_) {}
            }
          }
          _visits = merged.values.toList();
        } catch (vFetchErr) {
          debugPrint('Notice: visit_records fetch: $vFetchErr');
          if (_visits.isEmpty) {
            for (final vList in _patientVisitsCache.values) {
              for (final j in vList) {
                try {
                  _visits.add(VisitRecord.fromJson(j));
                } catch (_) {}
              }
            }
          }
        }

        _loaded = true;
        return;
      } catch (e) {
        debugPrint('Supabase load error, falling back to local: $e');
      }
    }
    // Fallback: load from local JSON / SharedPreferences
    await _ensureVisitsLoaded();
    if (_visits.isEmpty) {
      for (final vList in _patientVisitsCache.values) {
        for (final j in vList) {
          try {
            _visits.add(VisitRecord.fromJson(j));
          } catch (_) {}
        }
      }
    }
    _loaded = true;
  }

  Future<void> _saveToStorage() async {
    // For Supabase mode, data is already persisted via API calls above.
    // For offline fallback, keep in-memory only (or add SharedPreferences).
  }

  /// Sync from Supabase realtime
  void listenToChanges(VoidCallback onChanged) {
    if (!isSupabase) return;
    SupabaseService.client
        .from('patients')
        .stream(primaryKey: ['id']).listen((_) async {
      await _loadFromStorage();
      onChanged();
    });
  }
}
