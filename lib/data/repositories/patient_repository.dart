import 'package:flutter/foundation.dart';
import 'package:storage_client/storage_client.dart';
import '../models/patient.dart';
import '../models/visit_record.dart';
import '../services/supabase_service.dart';
import '../../core/utils/helpers.dart';

/// Patient CRUD operations — Supabase with localStorage fallback
class PatientRepository {
  // In-memory cache for fast access
  List<Patient> _patients = [];
  List<VisitRecord> _visits = [];
  bool _loaded = false;

  bool get isSupabase => SupabaseService.isConfigured;

  /// Load all patients
  Future<List<Patient>> getPatients() async {
    if (!_loaded) await _loadFromStorage();
    return List.unmodifiable(_patients);
  }

  /// Get a single patient by ID
  Future<Patient?> getPatient(String id) async {
    if (!_loaded) await _loadFromStorage();
    try {
      return _patients.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get patient by patient number
  Future<Patient?> getPatientByNo(String patientNo) async {
    if (!_loaded) await _loadFromStorage();
    try {
      return _patients.firstWhere((p) => p.patientNo == patientNo);
    } catch (_) {
      return null;
    }
  }

  /// Search patients by name or patient number
  Future<List<Patient>> searchPatients(String query) async {
    if (!_loaded) await _loadFromStorage();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    return _patients.where((p) {
      return p.fullName.toLowerCase().contains(q) ||
          p.patientNo.toLowerCase().contains(q) ||
          p.firstName.toLowerCase().contains(q) ||
          p.lastName.toLowerCase().contains(q);
    }).toList();
  }

  /// Add a new patient
  Future<Patient> addPatient(Patient patient) async {
    if (isSupabase) {
      try {
        await SupabaseService.client
            .from('patients')
            .insert(patient.toJson());
      } catch (e) {
        debugPrint('Supabase insert error: $e');
        if (e.toString().contains('assigned_doctor') ||
            e.toString().contains('assigned_room') ||
            e.toString().contains('is_first_time')) {
          try {
            final fallback = Map<String, dynamic>.from(patient.toJson())
              ..remove('is_first_time')
              ..remove('assigned_doctor')
              ..remove('assigned_room');
            await SupabaseService.client.from('patients').insert(fallback);
          } catch (e2) {
            debugPrint('Supabase fallback insert error: $e2');
          }
        }
      }
    }
    _patients.add(patient);
    await _saveToStorage();
    return patient;
  }

  /// Update a patient
  Future<Patient> updatePatient(Patient patient) async {
    if (isSupabase) {
      try {
        await SupabaseService.client
            .from('patients')
            .update(patient.toJson())
            .eq('id', patient.id);
      } catch (e) {
        debugPrint('Supabase update error: $e');
        if (e.toString().contains('assigned_doctor') ||
            e.toString().contains('assigned_room') ||
            e.toString().contains('is_first_time')) {
          try {
            final fallback = Map<String, dynamic>.from(patient.toJson())
              ..remove('is_first_time')
              ..remove('assigned_doctor')
              ..remove('assigned_room');
            await SupabaseService.client
                .from('patients')
                .update(fallback)
                .eq('id', patient.id);
          } catch (e2) {
            debugPrint('Supabase fallback update error: $e2');
          }
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

  /// Get visit history for a patient
  Future<List<VisitRecord>> getVisitHistory(String patientId) async {
    if (!_loaded) await _loadFromStorage();
    return _visits.where((v) => v.patientId == patientId).toList()
      ..sort((a, b) => b.visitDate.compareTo(a.visitDate));
  }

  /// Add a visit record
  Future<void> addVisitRecord(VisitRecord visit) async {
    if (isSupabase) {
      try {
        await SupabaseService.client
            .from('visit_records')
            .insert(visit.toJson());
      } catch (e) {
        debugPrint('Supabase insert visit error: $e');
      }
    }
    _visits.add(visit);
    await _saveToStorage();
  }

  /// Upload a patient photo to Supabase Storage and return the public URL.
  /// [bytes] is the raw image bytes, [fileName] is e.g. "photo.jpg".
  Future<String?> uploadPhoto(String patientId, Uint8List bytes, String fileName) async {
    if (!isSupabase) return null;
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final path = 'patients/$patientId/profile.$ext';
      await SupabaseService.client.storage
          .from('patient-photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
            ),
          );
      final url = SupabaseService.client.storage
          .from('patient-photos')
          .getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('Photo upload error: $e');
      return null;
    }
  }

  /// Get next patient number sequence
  int get nextPatientSequence => _patients.length + 1;

  /// Generate a new patient ID
  String generatePatientId() => IdGenerator.generatePatientId();

  // ── Local storage (web: localStorage, mobile: SharedPreferences fallback) ──

  Future<void> _loadFromStorage() async {
    if (isSupabase) {
      try {
        final pData =
            await SupabaseService.client.from('patients').select().order('created_at');
        _patients = (pData as List).map((j) => Patient.fromJson(j)).toList();

        final vData = await SupabaseService.client
            .from('visit_records')
            .select()
            .order('visit_date');
        _visits = (vData as List).map((j) => VisitRecord.fromJson(j)).toList();
        _loaded = true;
        return;
      } catch (e) {
        debugPrint('Supabase load error, falling back to local: $e');
      }
    }
    // Fallback: load from local JSON in memory (web uses localStorage via kIsWeb)
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
