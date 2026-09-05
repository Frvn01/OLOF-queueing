import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../data/models/patient.dart';
import '../data/models/visit_record.dart';
import '../data/repositories/patient_repository.dart';
import '../core/utils/helpers.dart';

/// State management for patient data
class PatientProvider extends ChangeNotifier {
  final PatientRepository _repo = PatientRepository();

  List<Patient> _patients = [];
  List<Patient> _searchResults = [];
  Patient? _selectedPatient;
  List<VisitRecord> _selectedPatientVisits = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Patient> get patients => _patients;
  List<Patient> get searchResults => _searchResults;
  Patient? get selectedPatient => _selectedPatient;
  List<VisitRecord> get selectedPatientVisits => _selectedPatientVisits;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  /// Initialize and load patients
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    _patients = await _repo.getPatients();
    _isLoading = false;
    notifyListeners();

    // Listen for realtime changes
    _repo.listenToChanges(() async {
      _patients = await _repo.getPatients();
      notifyListeners();
    });
  }

  /// Search patients
  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = await _repo.searchPatients(query);
    }
    notifyListeners();
  }

  /// Select a patient for viewing
  Future<void> selectPatient(String patientId) async {
    _selectedPatient = await _repo.getPatient(patientId);
    if (_selectedPatient != null) {
      _selectedPatientVisits =
          await _repo.getVisitHistory(patientId);
    }
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedPatient = null;
    _selectedPatientVisits = [];
    notifyListeners();
  }

  /// Register a new patient
  Future<Patient> registerPatient({
    required String firstName,
    required String lastName,
    String? middleName,
    required DateTime birthday,
    required String sex,
    required String civilStatus,
    required String address,
    required String contactNumber,
    String? occupation,
    String? referredBy,
    String? photoUrl,
    String? chiefComplaint,
    String? historyOfPresentIllness,
    String? pastMedicalHistory,
    bool isFirstTime = true,
    String? assignedDoctor,
    String? assignedRoom,
  }) async {
    final patient = Patient(
      id: IdGenerator.generateUuid(),
      patientNo: _repo.generatePatientId(),
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      birthday: birthday,
      sex: sex,
      civilStatus: civilStatus,
      address: address,
      contactNumber: contactNumber,
      occupation: occupation,
      referredBy: referredBy,
      photoUrl: photoUrl,
      chiefComplaint: chiefComplaint,
      historyOfPresentIllness: historyOfPresentIllness,
      pastMedicalHistory: pastMedicalHistory,
      isFirstTime: isFirstTime,
      assignedDoctor: assignedDoctor,
      assignedRoom: assignedRoom,
    );

    final saved = await _repo.addPatient(patient);
    _patients = await _repo.getPatients();
    notifyListeners();
    return saved;
  }

  /// Update an existing patient
  Future<Patient> updatePatient(Patient patient) async {
    final saved = await _repo.updatePatient(patient);
    _patients = await _repo.getPatients();
    if (_selectedPatient?.id == patient.id) {
      _selectedPatient = saved;
    }
    notifyListeners();
    return saved;
  }

  /// Delete a patient by ID
  Future<void> deletePatient(String patientId) async {
    await _repo.deletePatient(patientId);
    _patients = await _repo.getPatients();
    if (_selectedPatient?.id == patientId) {
      _selectedPatient = null;
      _selectedPatientVisits = [];
    }
    notifyListeners();
  }

  /// Get patient by ID
  Future<Patient?> getPatientById(String id) async {
    return _repo.getPatient(id);
  }

  /// Get patient by patient number (for QR lookup)
  Future<Patient?> getPatientByNo(String patientNo) async {
    return _repo.getPatientByNo(patientNo);
  }

  /// Add a visit record
  Future<void> addVisitRecord(VisitRecord record) async {
    await _repo.addVisitRecord(record);
    if (_selectedPatient?.id == record.patientId) {
      _selectedPatientVisits =
          await _repo.getVisitHistory(record.patientId);
    }
    notifyListeners();
  }

  /// Upload a profile photo and update the patient's photo_url
  Future<String?> uploadPatientPhoto(
    String patientId,
    Uint8List bytes,
    String fileName,
  ) async {
    final url = await _repo.uploadPhoto(patientId, bytes, fileName);
    if (url != null) {
      final patient = await _repo.getPatient(patientId);
      if (patient != null) {
        final updated = patient.copyWith(photoUrl: url);
        await _repo.updatePatient(updated);
        if (_selectedPatient?.id == patientId) {
          _selectedPatient = updated;
        }
        _patients = await _repo.getPatients();
        notifyListeners();
      }
    }
    return url;
  }
}
