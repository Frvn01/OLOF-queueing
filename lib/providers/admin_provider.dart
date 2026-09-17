import 'package:flutter/material.dart';
import '../data/models/queue_entry.dart';
import '../data/repositories/patient_repository.dart';
import '../data/repositories/queue_repository.dart';
import '../data/services/local_storage_service.dart';

/// Clinic staff member model for Admin User Management
class StaffUser {
  final String id;
  final String name;
  final String role; // 'doctor', 'nurse', 'receptionist', 'admin'
  final String department; // 'ENT', 'EYES', 'ALL'
  final String? assignedRoom;
  final bool isActive;

  const StaffUser({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    this.assignedRoom,
    this.isActive = true,
  });

  StaffUser copyWith({
    String? name,
    String? role,
    String? department,
    String? assignedRoom,
    bool? isActive,
  }) {
    return StaffUser(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      assignedRoom: assignedRoom ?? this.assignedRoom,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// State management for Admin Desktop Workspace
class AdminProvider extends ChangeNotifier {
  final QueueRepository _queueRepo = QueueRepository();
  final PatientRepository _patientRepo = PatientRepository();

  int _selectedNavigationIndex = 0;
  Map<String, dynamic> _storageStats = {};
  bool _isLoadingStorage = false;
  String? _lastBackupPath;

  // Active station staff list (Doctors are managed dynamically via ClinicProvider)
  final List<StaffUser> _staffList = [
    const StaffUser(
      id: 'nurse-1',
      name: 'Nurse Station Lead',
      role: 'nurse',
      department: 'ALL',
      assignedRoom: 'Clinical Kiosk',
    ),
    const StaffUser(
      id: 'rec-1',
      name: 'Reception Front Desk',
      role: 'receptionist',
      department: 'ALL',
      assignedRoom: 'Triage / Desk',
    ),
    const StaffUser(
      id: 'admin-1',
      name: 'OLOF Clinic Administrator',
      role: 'admin',
      department: 'ALL',
      assignedRoom: 'Admin PC',
    ),
  ];

  int get selectedNavigationIndex => _selectedNavigationIndex;
  Map<String, dynamic> get storageStats => _storageStats;
  bool get isLoadingStorage => _isLoadingStorage;
  String? get lastBackupPath => _lastBackupPath;
  List<StaffUser> get staffList => List.unmodifiable(_staffList);

  void setNavigationIndex(int index) {
    _selectedNavigationIndex = index;
    notifyListeners();
  }

  /// Refresh storage stats from clinic PC drive
  Future<void> refreshStorageStats() async {
    _isLoadingStorage = true;
    notifyListeners();
    try {
      _storageStats = await LocalStorageService.instance.getStorageUsage();
    } catch (e) {
      debugPrint('Error getting storage stats: $e');
    }
    _isLoadingStorage = false;
    notifyListeners();
  }

  /// Create a local full backup on the clinic PC
  Future<String?> createBackup() async {
    try {
      final patients = await _patientRepo.getPatients();
      final queue = await _queueRepo.getTodayQueue();
      final path = await LocalStorageService.instance.exportBackupFile(
        patients: patients.map((p) => p.toJson()).toList(),
        queueEntries: queue.map((q) => q.toJson()).toList(),
        examinations: [],
      );
      _lastBackupPath = path;
      await refreshStorageStats();
      notifyListeners();
      return path;
    } catch (e) {
      debugPrint('Backup creation error: $e');
      return null;
    }
  }

  /// Add new staff member
  void addStaff(StaffUser staff) {
    _staffList.add(staff);
    notifyListeners();
  }

  /// Update existing staff member
  void updateStaff(StaffUser staff) {
    final idx = _staffList.indexWhere((s) => s.id == staff.id);
    if (idx != -1) {
      _staffList[idx] = staff;
      notifyListeners();
    }
  }

  /// Toggle active state of a staff member
  void toggleStaffActive(String staffId) {
    final idx = _staffList.indexWhere((s) => s.id == staffId);
    if (idx != -1) {
      _staffList[idx] = _staffList[idx].copyWith(
        isActive: !_staffList[idx].isActive,
      );
      notifyListeners();
    }
  }

  // ── Queue Oversight Helpers ──────────────────────────

  /// Get patients assigned to a specific doctor or room
  List<QueueEntry> getQueueForDoctor(List<QueueEntry> queue, String doctorName, String department) {
    return queue.where((e) {
      if (e.assignedDoctor != null && e.assignedDoctor!.isNotEmpty) {
        return e.assignedDoctor == doctorName;
      }
      return e.department == department;
    }).toList();
  }

  /// Get currently serving patient for a doctor
  QueueEntry? getDoctorServing(List<QueueEntry> queue, String doctorName, String department) {
    final docQueue = getQueueForDoctor(queue, doctorName, department);
    try {
      return docQueue.firstWhere((e) => e.isServing);
    } catch (_) {
      return null;
    }
  }

  /// Get the immediate next waiting patient for a doctor
  QueueEntry? getDoctorNext(List<QueueEntry> queue, String doctorName, String department) {
    final docQueue = getQueueForDoctor(queue, doctorName, department);
    try {
      return docQueue.firstWhere((e) => e.isWaiting);
    } catch (_) {
      return null;
    }
  }

  /// Get all other waiting patients (after the next patient)
  List<QueueEntry> getDoctorOtherWaiting(List<QueueEntry> queue, String doctorName, String department) {
    final docQueue = getQueueForDoctor(queue, doctorName, department);
    final waiting = docQueue.where((e) => e.isWaiting || e.isOnHold).toList();
    if (waiting.length > 1) {
      return waiting.sublist(1);
    }
    return [];
  }

  /// Reassign patient to a different doctor or room
  Future<void> reassignPatient(String entryId, {required String newDoctor, required String newRoom}) async {
    await _queueRepo.reassignDoctorAndRoom(entryId, doctor: newDoctor, room: newRoom);
    notifyListeners();
  }
}
