import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
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

  /// Unique secret embedded in the staff QR code (UUID v4)
  final String qrSecret;

  /// 4-digit PIN for Windows desktop fallback login
  final String pin4;

  const StaffUser({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    this.assignedRoom,
    this.isActive = true,
    required this.qrSecret,
    this.pin4 = '',
  });

  StaffUser copyWith({
    String? name,
    String? role,
    String? department,
    String? assignedRoom,
    bool? isActive,
    String? qrSecret,
    String? pin4,
  }) {
    return StaffUser(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      assignedRoom: assignedRoom ?? this.assignedRoom,
      isActive: isActive ?? this.isActive,
      qrSecret: qrSecret ?? this.qrSecret,
      pin4: pin4 ?? this.pin4,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'department': department,
        'assignedRoom': assignedRoom,
        'isActive': isActive,
        'qrSecret': qrSecret,
        'pin4': pin4,
      };

  factory StaffUser.fromJson(Map<String, dynamic> json) => StaffUser(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        department: json['department'] as String,
        assignedRoom: json['assignedRoom'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        qrSecret: json['qrSecret'] as String? ?? const Uuid().v4(),
        pin4: json['pin4'] as String? ?? '0000',
      );

  /// The QR payload that gets embedded in the code
  String get qrPayload => jsonEncode({
        'type': 'olof_staff',
        'id': id,
        'secret': qrSecret,
        'role': role,
        'name': name,
        'department': department,
        'room': assignedRoom ?? '',
      });
}

/// Default hardcoded staff (used on first run and to guarantee department coverage)
List<StaffUser> _defaultStaff() {
  return [
    const StaffUser(
      id: 'super-admin-1',
      name: 'Super Administrator',
      role: 'super_admin',
      department: 'ALL',
      assignedRoom: 'All Stations (Master Key)',
      qrSecret: 'olof-super-admin-master-key-2026',
    ),
    const StaffUser(
      id: 'rec-1',
      name: 'Reception Front Desk',
      role: 'receptionist',
      department: 'ALL',
      assignedRoom: 'Triage / Front Desk',
      qrSecret: 'olof-reception-desk-2026',
    ),
    const StaffUser(
      id: 'nurse-1',
      name: 'Nurse Station Lead',
      role: 'nurse',
      department: 'ALL',
      assignedRoom: 'Clinical Kiosk',
      qrSecret: 'olof-nurse-station-2026',
    ),
    const StaffUser(
      id: 'doc-ent-1',
      name: 'Dr. DR. LORENZO VERA CRUZ',
      role: 'doctor',
      department: 'ENT',
      assignedRoom: 'ENT ROOM 1',
      qrSecret: 'olof-doc-ent-vera-cruz-2026',
    ),
    const StaffUser(
      id: 'doc-eye-1',
      name: 'Dr. DR. IAN J. DAGUMAN',
      role: 'doctor',
      department: 'EYES',
      assignedRoom: 'OPHTHA ROOM 1',
      qrSecret: 'olof-doc-eye-daguman-2026',
    ),
    const StaffUser(
      id: 'ophtha-1',
      name: 'Ophtha Station Staff',
      role: 'ophtha',
      department: 'EYES',
      assignedRoom: 'Ophtha Clinic',
      qrSecret: 'olof-ophtha-station-2026',
    ),
    const StaffUser(
      id: 'admin-1',
      name: 'OLOF Clinic Administrator',
      role: 'admin',
      department: 'ALL',
      assignedRoom: 'Admin PC',
      qrSecret: 'olof-admin-pc-2026',
    ),
  ];
}

const _kStaffPrefsKey = 'olof_staff_list_v2';

/// State management for Admin Desktop Workspace
class AdminProvider extends ChangeNotifier {
  final QueueRepository _queueRepo = QueueRepository();
  final PatientRepository _patientRepo = PatientRepository();

  int _selectedNavigationIndex = 0;
  Map<String, dynamic> _storageStats = {};
  bool _isLoadingStorage = false;
  String? _lastBackupPath;
  bool _staffLoaded = false;

  final List<StaffUser> _staffList = [];

  int get selectedNavigationIndex => _selectedNavigationIndex;
  Map<String, dynamic> get storageStats => _storageStats;
  bool get isLoadingStorage => _isLoadingStorage;
  String? get lastBackupPath => _lastBackupPath;
  List<StaffUser> get staffList => List.unmodifiable(_staffList);
  bool get staffLoaded => _staffLoaded;

  void setNavigationIndex(int index) {
    _selectedNavigationIndex = index;
    notifyListeners();
  }

  // ── Persistence ──────────────────────────────────────

  /// Load staff from SharedPreferences; seed defaults on first run
  Future<void> loadStaff() async {
    if (_staffLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStaffPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _staffList.clear();
        _staffList.addAll(
          decoded.map((e) => StaffUser.fromJson(e as Map<String, dynamic>)),
        );
      } else {
        // First run — seed defaults and persist them
        _staffList.clear();
        _staffList.addAll(_defaultStaff());
      }
      _ensureEssentialStaff();
      await _persistStaff();
    } catch (e) {
      debugPrint('Error loading staff: $e');
      if (_staffList.isEmpty) {
        _staffList.addAll(_defaultStaff());
      }
      _ensureEssentialStaff();
    }
    _staffLoaded = true;
    notifyListeners();
  }

  void _ensureEssentialStaff() {
    for (final def in _defaultStaff()) {
      final exists = _staffList.any((s) => s.id == def.id);
      if (!exists) {
        _staffList.add(def);
      }
    }
  }

  Future<void> _persistStaff() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_staffList.map((s) => s.toJson()).toList());
      await prefs.setString(_kStaffPrefsKey, encoded);
    } catch (e) {
      debugPrint('Error persisting staff: $e');
    }
  }

  // ── Storage Stats ─────────────────────────────────────

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

  // ── Staff CRUD ────────────────────────────────────────

  /// Add new staff member and persist
  Future<void> addStaff(StaffUser staff) async {
    _staffList.add(staff);
    await _persistStaff();
    notifyListeners();
  }

  /// Update existing staff member and persist
  Future<void> updateStaff(StaffUser staff) async {
    final idx = _staffList.indexWhere((s) => s.id == staff.id);
    if (idx != -1) {
      _staffList[idx] = staff;
      await _persistStaff();
      notifyListeners();
    }
  }

  /// Toggle active state of a staff member and persist
  Future<void> toggleStaffActive(String staffId) async {
    final idx = _staffList.indexWhere((s) => s.id == staffId);
    if (idx != -1) {
      _staffList[idx] = _staffList[idx].copyWith(
        isActive: !_staffList[idx].isActive,
      );
      await _persistStaff();
      notifyListeners();
    }
  }

  /// Delete a staff member and persist
  Future<void> deleteStaff(String staffId) async {
    _staffList.removeWhere((s) => s.id == staffId);
    await _persistStaff();
    notifyListeners();
  }

  // ── QR / PIN Auth Helpers ─────────────────────────────

  /// Resolve a staff member from a scanned QR payload string.
  /// Supports:
  /// - Direct shorthand string: 'OLOF_SUPER_ADMIN', 'SUPER_ADMIN', 'OLOF_RECEPTIONIST', etc.
  /// - JSON payload: {"type":"olof_staff","id":...,"secret":...}
  StaffUser? resolveQrPayload(String raw) {
    final trimmed = raw.trim();

    // 1. Shorthand Super Admin matching
    final upper = trimmed.toUpperCase();
    if (upper == 'OLOF_SUPER_ADMIN' ||
        upper == 'SUPER_ADMIN' ||
        upper == 'SUPERADMIN' ||
        upper == 'OLOF_ADMIN_MASTER') {
      return _staffList.firstWhere(
        (s) => s.role == 'super_admin' || s.id == 'super-admin-1',
        orElse: () => _defaultStaff().firstWhere((s) => s.id == 'super-admin-1'),
      );
    }

    // 2. Shorthand quick-role matching
    if (upper == 'OLOF_RECEPTIONIST' || upper == 'RECEPTIONIST') {
      return _staffList.firstWhere((s) => s.role == 'receptionist', orElse: () => _defaultStaff()[1]);
    }
    if (upper == 'OLOF_NURSE' || upper == 'NURSE') {
      return _staffList.firstWhere((s) => s.role == 'nurse', orElse: () => _defaultStaff()[2]);
    }
    if (upper == 'OLOF_DOCTOR' || upper == 'DOCTOR') {
      return _staffList.firstWhere((s) => s.role == 'doctor', orElse: () => _defaultStaff()[3]);
    }
    if (upper == 'OLOF_OPHTHA' || upper == 'OPHTHA' || upper == 'OPTHA') {
      return _staffList.firstWhere((s) => s.role == 'ophtha', orElse: () => _defaultStaff()[5]);
    }

    // 3. JSON standard OLOF staff QR payload
    try {
      final Map<String, dynamic> data = jsonDecode(trimmed) as Map<String, dynamic>;
      final type = data['type']?.toString();
      final id = data['id']?.toString();
      final secret = data['secret']?.toString();
      final role = data['role']?.toString().toLowerCase();

      if (role == 'super_admin' || role == 'superadmin' || id == 'super-admin-1' || type == 'super_admin') {
        return _staffList.firstWhere(
          (s) => s.role == 'super_admin' || s.id == 'super-admin-1',
          orElse: () => _defaultStaff().firstWhere((s) => s.id == 'super-admin-1'),
        );
      }

      if (type != 'olof_staff' && type != 'olof_badge') return null;

      if (id != null) {
        // First check locally registered staff by ID or secret
        final found = _staffList.cast<StaffUser?>().firstWhere(
          (s) => s != null && (s.id == id || (secret != null && s.qrSecret == secret)) && s.isActive,
          orElse: () => null,
        );
        if (found != null) return found;

        // If not registered in local staffList (e.g. Supabase doctor with generated QR), create StaffUser on the fly
        if (role != null) {
          final doctorName = data['name']?.toString() ?? 'Doctor';
          final dept = data['department']?.toString() ?? (role == 'doctor' ? 'ENT' : 'ALL');
          final assigned = data['assignedRoom']?.toString() ?? data['room']?.toString() ?? (dept == 'EYES' ? 'OPHTHA ROOM 1' : 'ENT ROOM 1');
          return StaffUser(
            id: id,
            name: doctorName,
            role: role,
            department: dept,
            assignedRoom: assigned,
            qrSecret: secret ?? 'olof-$role-$id',
            pin4: '',
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Route path for a given staff role.
  /// Returns null for 'super_admin' to signal department selection modal.
  static String? routeForRole(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return null;
      case 'doctor':
        return '/doctor';
      case 'nurse':
        return '/nurse';
      case 'receptionist':
        return '/receptionist';
      case 'secretary':
      case 'ophtha':
      case 'optha':
        return '/secretary';
      case 'admin':
        return '/admin';
      default:
        return null;
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
