import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../data/models/doctor.dart';
import '../data/models/doctor_schedule.dart';
import '../data/models/patient.dart';
import '../data/models/queue_entry.dart';
import '../data/models/visit_record.dart';
import '../data/repositories/examination_repository.dart';
import '../data/repositories/patient_repository.dart';
import '../data/repositories/queue_repository.dart';

/// State management for Doctor Mobile / Tablet kiosk module
class DoctorProvider extends ChangeNotifier {
  final PatientRepository _patientRepo = PatientRepository();
  final QueueRepository _queueRepo = QueueRepository();
  final ExaminationRepository _examRepo = ExaminationRepository();

  // Active Doctor Information
  String _activeDoctor = AppConstants.departmentDoctors[AppConstants.deptEnt]!;
  String _activeDepartment = AppConstants.deptEnt;
  String _activeRoom = 'Room 1';
  String? _photoUrl;
  String _doctorEmail = '';
  String _doctorPhone = '';
  String _licenseNumber = '';
  int _yearsOfExperience = 0;
  String _bio = '';

  // Consultation state
  Patient? _currentPatient;
  QueueEntry? _currentQueueEntry;
  List<Map<String, dynamic>> _currentExaminations = [];
  bool _isLoadingConsultation = false;
  String? _consultationError;

  // Dynamic Patients from Receptionist uploads / Supabase
  List<Patient> _patients = [];
  bool _isLoadingPatients = false;
  String? _patientsError;

  // Doctor Schedule state
  DoctorSchedule? _schedule;

  // Cache of doctor profiles
  final Map<String, DoctorSchedule> _savedSchedules = {};

  // Getters
  String get activeDoctor => _activeDoctor;

  /// Helper to format clean doctor name without duplicate "Dr. DR." and proper casing
  static String formatDoctorName(String raw) {
    var s = raw.trim();
    while (RegExp(r'^(dr\.|dr|doctor)\s*', caseSensitive: false).hasMatch(s)) {
      s = s.replaceFirst(RegExp(r'^(dr\.|dr|doctor)\s*', caseSensitive: false), '').trim();
    }
    if (s.isNotEmpty && s == s.toUpperCase()) {
      s = s.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
    }
    return 'Dr. $s';
  }

  /// Formatted name without double "Dr. DR."
  String get formattedDoctorName => formatDoctorName(_activeDoctor);

  String? get photoUrl => _photoUrl;
  String get activeDepartment => _activeDepartment;
  String get activeRoom => _activeRoom;
  String get doctorEmail => _doctorEmail;
  String get doctorPhone => _doctorPhone;
  String get licenseNumber => _licenseNumber;
  int get yearsOfExperience => _yearsOfExperience;
  String get bio => _bio;

  Patient? get currentPatient => _currentPatient;
  QueueEntry? get currentQueueEntry => _currentQueueEntry;
  List<Map<String, dynamic>> get currentExaminations => _currentExaminations;
  bool get isLoadingConsultation => _isLoadingConsultation;
  String? get consultationError => _consultationError;

  List<Patient> get patients => List.unmodifiable(_patients);
  bool get isLoadingPatients => _isLoadingPatients;
  String? get patientsError => _patientsError;

  DoctorSchedule get schedule {
    _schedule ??= _savedSchedules[_activeDoctor] ??
        DoctorSchedule.defaultSchedule(
          doctorId: _activeDoctor,
          doctorName: _activeDoctor,
          room: _activeRoom,
        );
    return _schedule!;
  }

  DoctorProvider() {
    _initProvider();
  }

  void _initProvider() {
    loadPatients();
    loadSchedule();
  }

  /// Set the active doctor profile dynamically
  void selectDoctor({
    required String doctorName,
    required String department,
    String room = 'Room 1',
    String? photoUrl,
    String? email,
    String? phone,
    String? license,
    int? experience,
    String? doctorBio,
  }) {
    _activeDoctor = doctorName;
    _activeDepartment = department;
    _activeRoom = room;
    if (photoUrl != null) _photoUrl = photoUrl;
    if (email != null) _doctorEmail = email;
    if (phone != null) _doctorPhone = phone;
    if (license != null) _licenseNumber = license;
    if (experience != null) _yearsOfExperience = experience;
    if (doctorBio != null) _bio = doctorBio;

    // Switch active schedule
    _schedule = _savedSchedules[_activeDoctor] ??
        DoctorSchedule.defaultSchedule(
          doctorId: _activeDoctor,
          doctorName: _activeDoctor,
          room: _activeRoom,
        );

    notifyListeners();
  }

  /// Select doctor from a Doctor model
  void selectDoctorModel(Doctor doctor) {
    selectDoctor(
      doctorName: doctor.name,
      department: doctor.department,
      room: doctor.room ?? (doctor.department == AppConstants.deptEyes ? 'Room 2' : 'Room 1'),
      photoUrl: doctor.photoUrl,
      email: doctor.email,
      phone: doctor.phone,
      license: doctor.licenseNumber,
      experience: doctor.yearsOfExperience,
      doctorBio: doctor.bio,
    );
  }

  /// Update doctor professional profile info
  void updateProfile({
    String? name,
    String? department,
    String? room,
    String? photoUrl,
    String? email,
    String? phone,
    String? license,
    int? experience,
    String? doctorBio,
  }) {
    if (name != null) _activeDoctor = name;
    if (department != null) _activeDepartment = department;
    if (room != null) _activeRoom = room;
    if (photoUrl != null) _photoUrl = photoUrl;
    if (email != null) _doctorEmail = email;
    if (phone != null) _doctorPhone = phone;
    if (license != null) _licenseNumber = license;
    if (experience != null) _yearsOfExperience = experience;
    if (doctorBio != null) _bio = doctorBio;
    notifyListeners();
  }

  /// Convert current active doctor state to Doctor model
  Doctor toDoctorModel() {
    return Doctor(
      id: 'doc-${_activeDoctor.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-')}',
      name: _activeDoctor,
      department: _activeDepartment,
      room: _activeRoom,
      photoUrl: _photoUrl,
      email: _doctorEmail,
      phone: _doctorPhone,
      licenseNumber: _licenseNumber,
      yearsOfExperience: _yearsOfExperience,
      bio: _bio,
      isActive: true,
    );
  }

  // ── Dynamic Patients (from Receptionist / Supabase) ──────────

  /// Load patients from repository (fetched from Supabase / receptionist uploads)
  Future<void> loadPatients({bool forceRefresh = false}) async {
    _isLoadingPatients = true;
    _patientsError = null;
    notifyListeners();

    try {
      final fetched = await _patientRepo.getPatients(forceRefresh: forceRefresh);
      _patients = fetched;
      _isLoadingPatients = false;
      notifyListeners();
    } catch (e) {
      _patientsError = e.toString();
      _isLoadingPatients = false;
      notifyListeners();
    }
  }

  /// Get patients specifically assigned to this doctor or department
  List<Patient> getAssignedPatients() {
    return _patients.where((p) {
      if (p.assignedDoctor != null && p.assignedDoctor!.isNotEmpty) {
        return p.assignedDoctor == _activeDoctor;
      }
      return true; // Include unassigned or all for quick kiosk lookup
    }).toList();
  }

  /// Filter patients by search query
  List<Patient> searchPatients(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _patients;
    return _patients.where((p) {
      return p.fullName.toLowerCase().contains(q) ||
          p.patientNo.toLowerCase().contains(q) ||
          p.contactNumber.toLowerCase().contains(q) ||
          (p.chiefComplaint?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ── Doctor Schedule Management ──────────────────────────────

  /// Load weekly schedule for active doctor
  Future<void> loadSchedule() async {
    _schedule = _savedSchedules[_activeDoctor] ??
        DoctorSchedule.defaultSchedule(
          doctorId: _activeDoctor,
          doctorName: _activeDoctor,
          room: _activeRoom,
        );
    notifyListeners();
  }

  /// Update day schedule in the weekly schedule
  void updateDaySchedule(String dayKey, DaySchedule daySchedule) {
    final currentDays = Map<String, DaySchedule>.from(schedule.days);
    currentDays[dayKey] = daySchedule;
    _schedule = DoctorSchedule(
      doctorId: schedule.doctorId,
      doctorName: schedule.doctorName,
      days: currentDays,
    );
    _savedSchedules[_activeDoctor] = _schedule!;
    notifyListeners();
  }

  /// Save the complete schedule
  Future<void> saveSchedule(DoctorSchedule newSchedule) async {
    _schedule = newSchedule;
    _savedSchedules[_activeDoctor] = newSchedule;
    notifyListeners();
  }

  // ── Queue & Consultation Logic ──────────────────────────────

  /// Filter queue specifically assigned to this doctor / department
  List<QueueEntry> filterAssignedQueue(List<QueueEntry> fullQueue) {
    return fullQueue.where((e) {
      if (e.assignedDoctor != null && e.assignedDoctor!.isNotEmpty) {
        return e.assignedDoctor == _activeDoctor;
      }
      // Fallback: match by department if unassigned
      return e.department == _activeDepartment || _activeDepartment == 'BOTH';
    }).toList();
  }

  /// Get currently serving patient for this doctor
  QueueEntry? getServingPatient(List<QueueEntry> fullQueue) {
    final doctorQueue = filterAssignedQueue(fullQueue);
    try {
      return doctorQueue.firstWhere((e) => e.isServing);
    } catch (_) {
      return null;
    }
  }

  /// Get the immediate next patient in line
  QueueEntry? getNextPatient(List<QueueEntry> fullQueue) {
    final doctorQueue = filterAssignedQueue(fullQueue);
    try {
      return doctorQueue.firstWhere((e) => e.isWaiting);
    } catch (_) {
      return null;
    }
  }

  /// Get the other waiting patients (excluding the next patient)
  List<QueueEntry> getOtherWaitingPatients(List<QueueEntry> fullQueue) {
    final doctorQueue = filterAssignedQueue(fullQueue);
    final waiting = doctorQueue.where((e) => e.isWaiting || e.isOnHold).toList();
    if (waiting.length > 1) {
      return waiting.sublist(1);
    }
    return [];
  }

  /// Get all waiting patients for this doctor
  List<QueueEntry> getAllWaitingPatients(List<QueueEntry> fullQueue) {
    final doctorQueue = filterAssignedQueue(fullQueue);
    return doctorQueue.where((e) => e.isWaiting || e.isOnHold).toList();
  }

  /// Get completed patients for this doctor today
  List<QueueEntry> getCompletedPatients(List<QueueEntry> fullQueue) {
    final doctorQueue = filterAssignedQueue(fullQueue);
    return doctorQueue.where((e) => e.isCompleted).toList();
  }

  /// Load a patient's consultation data (demographics, complaints, nurse exams & drawings)
  Future<void> loadConsultation({
    required String patientId,
    QueueEntry? queueEntry,
  }) async {
    _isLoadingConsultation = true;
    _consultationError = null;
    _currentQueueEntry = queueEntry;
    notifyListeners();

    try {
      // 1. Fetch patient
      final patient = await _patientRepo.getPatient(patientId);
      _currentPatient = patient;

      // 2. Fetch all nurse clinical examinations & drawings
      final exams = await _examRepo.getGroupedExaminations(patientId);
      _currentExaminations = exams;

      _isLoadingConsultation = false;
      notifyListeners();
    } catch (e) {
      _consultationError = e.toString();
      _isLoadingConsultation = false;
      notifyListeners();
    }
  }

  /// Call patient into the doctor's consultation room
  Future<void> callPatient(QueueEntry entry) async {
    await _queueRepo.callEntry(
      entry.id,
      roomNumber: _activeRoom,
      doctor: _activeDoctor,
    );
    _currentQueueEntry = entry.copyWith(
      status: AppConstants.statusServing,
      assignedDoctor: _activeDoctor,
      assignedRoom: _activeRoom,
      calledAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Complete consultation and save visit record
  Future<bool> completeConsultation({
    required String diagnosis,
    required String notes,
    String? prescription,
  }) async {
    if (_currentPatient == null) return false;

    try {
      final visit = VisitRecord(
        id: const Uuid().v4(),
        patientId: _currentPatient!.id,
        department: _activeDepartment,
        purpose: _currentQueueEntry?.purpose ?? 'Consultation',
        chiefComplaint: _currentPatient?.chiefComplaint,
        diagnosis: diagnosis.trim().isNotEmpty ? diagnosis.trim() : null,
        notes: [
          if (notes.trim().isNotEmpty) notes.trim(),
          if (prescription != null && prescription.trim().isNotEmpty)
            'Prescription / Rx: ${prescription.trim()}',
        ].join('\n\n'),
        assignedRoom: _activeRoom,
        queueNumber: _currentQueueEntry?.queueNumber ?? 'CON-000',
        visitDate: DateTime.now(),
      );

      // Save visit record in patient history
      await _patientRepo.addVisitRecord(visit);

      // Mark queue entry completed if present
      if (_currentQueueEntry != null) {
        await _queueRepo.markComplete(_currentQueueEntry!.id);
      }

      // Clear consultation state
      _currentPatient = null;
      _currentQueueEntry = null;
      _currentExaminations = [];
      notifyListeners();
      return true;
    } catch (e) {
      _consultationError = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearConsultation() {
    _currentPatient = null;
    _currentQueueEntry = null;
    _currentExaminations = [];
    _consultationError = null;
    notifyListeners();
  }
}
