import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/doctor.dart';
import '../data/models/clinic_room.dart';
import '../data/services/supabase_service.dart';
import '../core/constants/app_constants.dart';

/// Provider for managing clinic doctors and consultation rooms
class ClinicProvider extends ChangeNotifier {
  static const _uuid = Uuid();

  final List<Doctor> _doctors = [];
  final List<ClinicRoom> _rooms = [];
  bool _initialized = false;

  List<Doctor> get doctors => List.unmodifiable(_doctors);
  List<ClinicRoom> get rooms => List.unmodifiable(_rooms);

  bool get isSupabase => SupabaseService.isConfigured;

  ClinicProvider() {
    _initDefaults();
  }

  void _initDefaults() {
    if (_initialized) return;

    // Load initial default doctors from AppConstants
    _doctors.addAll([
      Doctor(
        id: 'doc-ent-default',
        name: AppConstants.departmentDoctors[AppConstants.deptEnt] ??
            'Dr. DR. LORENZO VERA CRUZ',
        department: AppConstants.deptEnt,
        room: 'ENT ROOM 1',
      ),
      Doctor(
        id: 'doc-ent-2-default',
        name: 'Dr. DR. JOSHUA PEREZ',
        department: AppConstants.deptEnt,
        room: 'ENT ROOM 2',
      ),
      Doctor(
        id: 'doc-eyes-1-default',
        name: 'Dr. DR. IAN J. DAGUMAN',
        department: AppConstants.deptEyes,
        room: 'OPHTHA ROOM 1',
      ),
      Doctor(
        id: 'doc-eyes-2-default',
        name: 'Dr. DR. AMELIA REYES VERA CRUZ',
        department: AppConstants.deptEyes,
        room: 'OPHTHA ROOM 2',
      ),
      Doctor(
        id: 'doc-eyes-3-default',
        name: 'Dr. DR. ANTHONY ROBERT PATRICK LIM',
        department: AppConstants.deptEyes,
        room: 'OPHTHA ROOM 3',
      ),
      Doctor(
        id: 'doc-eyes-3b-default',
        name: 'Dr. DR. ROEL VILLANUEVA',
        department: AppConstants.deptEyes,
        room: 'OPHTHA ROOM 3',
      ),
      Doctor(
        id: 'doc-eyes-4-default',
        name: 'Dr. DR. CLEMENS LEE SABITSANA',
        department: AppConstants.deptEyes,
        room: 'OPHTHA ROOM 4',
      ),
      Doctor(
        id: 'doc-eyes-4b-default',
        name: 'Dr. DR. FRANCIS MARIE LINGAD',
        department: AppConstants.deptEyes,
        room: 'OPHTHA ROOM 4',
      ),
      Doctor(
        id: 'doc-eyes-4c-default',
        name: 'Dr. DR. MARGARITA JUSTINE BONDOC',
        department: AppConstants.deptEyes,
        room: 'OPHTHA ROOM 4',
      ),
      Doctor(
        id: 'doc-eyes-4d-default',
        name: 'Dr. DR. ARAMIS B TORREFRANCA',
        department: AppConstants.deptEyes,
        room: 'OPHTHA ROOM 4',
      ),
    ]);

    // Load initial default rooms matching Supabase clinic_rooms
    _rooms.addAll([
      ClinicRoom(id: 'room-ent-1', name: 'ENT ROOM 1', department: AppConstants.deptEnt),
      ClinicRoom(id: 'room-ent-2', name: 'ENT ROOM 2', department: AppConstants.deptEnt),
      ClinicRoom(id: 'room-ophtha-1', name: 'OPHTHA ROOM 1', department: AppConstants.deptEyes),
      ClinicRoom(id: 'room-ophtha-2', name: 'OPHTHA ROOM 2', department: AppConstants.deptEyes),
      ClinicRoom(id: 'room-ophtha-3', name: 'OPHTHA ROOM 3', department: AppConstants.deptEyes),
      ClinicRoom(id: 'room-ophtha-4', name: 'OPHTHA ROOM 4', department: AppConstants.deptEyes),
    ]);

    _initialized = true;

    // Async attempt to load from Supabase if configured
    if (isSupabase) {
      _loadFromSupabase();
    }
  }

  Future<void> _loadFromSupabase() async {
    try {
      final docRes = await SupabaseService.client
          .from('clinic_doctors')
          .select()
          .order('name');
      final fetchedDocs = (docRes as List).map((j) => Doctor.fromJson(j)).toList();
      if (fetchedDocs.isNotEmpty) {
        _doctors.clear();
        _doctors.addAll(fetchedDocs);
      }

      final roomRes = await SupabaseService.client
          .from('clinic_rooms')
          .select()
          .order('name');
      final fetchedRooms =
          (roomRes as List).map((j) => ClinicRoom.fromJson(j)).toList();
      if (fetchedRooms.isNotEmpty) {
        _rooms.clear();
        _rooms.addAll(fetchedRooms);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('ClinicProvider: Using in-memory doctors/rooms ($e)');
    }
  }

  /// Get doctors filtered by department ('ALL', 'ENT', 'EYES')
  List<Doctor> getDoctors({String? department}) {
    if (department == null || department.isEmpty || department.toUpperCase() == 'ALL') {
      return List.unmodifiable(_doctors.where((d) => d.isActive));
    }
    final dept = department.toUpperCase();
    return List.unmodifiable(_doctors.where((d) =>
        d.isActive && (d.department.toUpperCase() == dept || d.department.toUpperCase() == 'BOTH')));
  }

  /// Get rooms filtered by department ('ALL', 'ENT', 'EYES')
  List<ClinicRoom> getRooms({String? department}) {
    if (department == null || department.isEmpty || department.toUpperCase() == 'ALL') {
      return List.unmodifiable(_rooms.where((r) => r.isActive));
    }
    final dept = department.toUpperCase();
    return List.unmodifiable(_rooms.where((r) =>
        r.isActive && (r.department.toUpperCase() == dept || r.department.toUpperCase() == 'BOTH')));
  }

  /// Find doctor assigned to a specific room
  Doctor? getDoctorForRoom(String? roomName) {
    if (roomName == null || roomName.trim().isEmpty) return null;
    try {
      final cleanRoom = roomName.trim().toLowerCase();
      return _doctors.firstWhere(
        (d) => d.isActive && d.room != null && d.room!.trim().toLowerCase() == cleanRoom,
      );
    } catch (_) {
      return null;
    }
  }

  /// Add a doctor one-by-one
  Future<Doctor> addDoctor({
    required String name,
    required String department,
    String? room,
  }) async {
    final cleanName = name.trim();
    final newDoctor = Doctor(
      id: _uuid.v4(),
      name: cleanName.startsWith('Dr.') ? cleanName : 'Dr. $cleanName',
      department: department.toUpperCase(),
      room: room?.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    _doctors.add(newDoctor);
    notifyListeners();

    if (isSupabase) {
      try {
        await SupabaseService.client.from('clinic_doctors').insert(newDoctor.toJson());
      } catch (e) {
        debugPrint('Supabase insert doctor error: $e');
      }
    }

    return newDoctor;
  }

  /// Remove a doctor
  Future<void> removeDoctor(String id) async {
    _doctors.removeWhere((d) => d.id == id);
    notifyListeners();

    if (isSupabase) {
      try {
        await SupabaseService.client.from('clinic_doctors').delete().eq('id', id);
      } catch (e) {
        debugPrint('Supabase delete doctor error: $e');
      }
    }
  }

  /// Update an existing doctor's profile/details
  Future<void> updateDoctor(Doctor updated) async {
    final idx = _doctors.indexWhere((d) => d.id == updated.id || d.name.toLowerCase() == updated.name.toLowerCase());
    if (idx != -1) {
      _doctors[idx] = updated;
    } else {
      _doctors.add(updated);
    }
    notifyListeners();

    if (isSupabase) {
      try {
        await SupabaseService.client.from('clinic_doctors').upsert(updated.toJson());
      } catch (e) {
        debugPrint('Supabase upsert doctor error: $e');
      }
    }
  }

  /// Toggle doctor active status
  Future<void> toggleDoctorStatus(String id) async {
    final idx = _doctors.indexWhere((d) => d.id == id);
    if (idx != -1) {
      final doc = _doctors[idx];
      final updated = doc.copyWith(isActive: !doc.isActive);
      _doctors[idx] = updated;
      notifyListeners();

      if (isSupabase) {
        try {
          await SupabaseService.client
              .from('clinic_doctors')
              .update({'is_active': updated.isActive}).eq('id', id);
        } catch (e) {
          debugPrint('Supabase toggle doctor error: $e');
        }
      }
    }
  }

  /// Add a room one-by-one
  Future<ClinicRoom> addRoom({
    required String name,
    required String department,
  }) async {
    final cleanName = name.trim();
    final newRoom = ClinicRoom(
      id: _uuid.v4(),
      name: cleanName,
      department: department.toUpperCase(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    _rooms.add(newRoom);
    notifyListeners();

    if (isSupabase) {
      try {
        await SupabaseService.client.from('clinic_rooms').insert(newRoom.toJson());
      } catch (e) {
        debugPrint('Supabase insert room error: $e');
      }
    }

    return newRoom;
  }

  /// Remove a room
  Future<void> removeRoom(String id) async {
    _rooms.removeWhere((r) => r.id == id);
    notifyListeners();

    if (isSupabase) {
      try {
        await SupabaseService.client.from('clinic_rooms').delete().eq('id', id);
      } catch (e) {
        debugPrint('Supabase delete room error: $e');
      }
    }
  }
}
