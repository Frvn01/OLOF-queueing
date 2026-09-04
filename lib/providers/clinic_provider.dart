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
            'Dr. Engr. Ranulfo Ramos',
        department: AppConstants.deptEnt,
        room: 'Room 1',
      ),
      Doctor(
        id: 'doc-eyes-default',
        name: AppConstants.departmentDoctors[AppConstants.deptEyes] ??
            'Dr. Ranulfo Ramos Jr.',
        department: AppConstants.deptEyes,
        room: 'Room 2',
      ),
    ]);

    // Load initial default rooms from AppConstants
    _rooms.addAll([
      ClinicRoom(id: 'room-1', name: 'Room 1', department: 'BOTH'),
      ClinicRoom(id: 'room-2', name: 'Room 2', department: 'BOTH'),
      ClinicRoom(id: 'room-3', name: 'Room 3', department: 'BOTH'),
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
