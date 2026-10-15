import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/queue_entry.dart';
import '../models/vital_signs.dart';
import '../services/supabase_service.dart';
import '../../core/utils/helpers.dart';

/// Queue CRUD operations — Supabase with in-memory fallback
class QueueRepository {
  static final List<QueueEntry> _entries = [];
  static bool _loaded = false;
  static String _lastLoadedDateKey = '';
  // Counter key format: 'DEPT::DoctorName::YYYY-MM-DD' for per-doctor numbering
  // Fallback key: 'DEPT::_nodoc::YYYY-MM-DD' when no doctor assigned
  static final Map<String, int> _counters = {};

  static const _queueVitalsStorageKey = 'cached_queue_vitals_v1';
  static final Map<String, Map<String, dynamic>> _queueVitalsCache = {};
  static bool _queueVitalsCacheLoaded = false;

  static Future<void> _ensureQueueVitalsLoaded() async {
    if (_queueVitalsCacheLoaded) return;
    _queueVitalsCacheLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueVitalsStorageKey);
      if (raw != null) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        decoded.forEach((key, val) {
          if (val is Map) {
            _queueVitalsCache[key] = Map<String, dynamic>.from(val);
          }
        });
      }
    } catch (e) {
      debugPrint('QueueRepository vitals cache load error: $e');
    }
  }

  static Future<void> _persistQueueVitalsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_queueVitalsStorageKey, jsonEncode(_queueVitalsCache));
    } catch (e) {
      debugPrint('QueueRepository vitals persist error: $e');
    }
  }

  bool get isSupabase => SupabaseService.isConfigured;

  /// Load today's queue (auto-detects new day and resets to 001)
  Future<List<QueueEntry>> getTodayQueue({bool forceRefresh = false}) async {
    final today = DateHelper.todayKey();
    if (!_loaded || _lastLoadedDateKey != today || forceRefresh) {
      await _loadFromStorage();
    }
    return _entries.where((e) => e.dateKey == today).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get queue for a specific department (today only)
  Future<List<QueueEntry>> getDepartmentQueue(String department, {bool forceRefresh = false}) async {
    final queue = await getTodayQueue(forceRefresh: forceRefresh);
    return queue.where((e) => e.department.toUpperCase() == department.toUpperCase()).toList();
  }

  /// Get waiting entries for a department
  Future<List<QueueEntry>> getWaiting(String department) async {
    final queue = await getDepartmentQueue(department);
    return queue.where((e) => e.isWaiting || e.isOnHold).toList();
  }

  /// Get currently serving entry for a department
  Future<QueueEntry?> getCurrentServing(String department) async {
    final queue = await getDepartmentQueue(department);
    try {
      return queue.firstWhere((e) => e.isServing);
    } catch (_) {
      return null;
    }
  }

  /// Add a patient to the queue
  Future<QueueEntry> addToQueue(QueueEntry entry) async {
    if (isSupabase) {
      try {
        await SupabaseService.client
            .from('queue_entries')
            .insert(entry.toSupabaseJson());
      } catch (e) {
        debugPrint('Supabase queue insert error: $e');
        // Resilient fallback: strip any unsupported columns dynamically
        try {
          final payload = Map<String, dynamic>.from(entry.toSupabaseJson());
          final errStr = e.toString();
          final match = RegExp(r"Could not find the '([^']+)' column").firstMatch(errStr);
          if (match != null) {
            payload.remove(match.group(1));
          }
          if (errStr.contains('assigned_doctor')) {
            payload.remove('assigned_doctor');
          }
          if (errStr.contains('assigned_room')) {
            payload.remove('assigned_room');
          }
          await SupabaseService.client
              .from('queue_entries')
              .insert(payload);
        } catch (e2) {
          debugPrint('Supabase queue fallback insert error: $e2');
        }
      }
    }
    _entries.add(entry);
    return entry;
  }

  /// Get next queue number — scoped per-doctor per-day.
  /// Format: 'ENT-001' uses dept prefix + 3-digit doctor sequence.
  /// Falls back to department-only numbering when no doctor is provided.
  String getNextQueueNumber(String department, {String? doctorName}) {
    final today = DateHelper.todayKey();
    final docKey = (doctorName != null && doctorName.isNotEmpty)
        ? DoctorHelper.formatName(doctorName)
        : '_nodoc';
    final counterKey = '$department::$docKey::$today';
    _counters[counterKey] = (_counters[counterKey] ?? 0) + 1;
    final seq = _counters[counterKey]!;
    return QueueNumberGenerator.generate(department, seq);
  }

  /// Get the doctor-scoped sequence number (1-based) for the next patient
  /// of a specific doctor. Used to set doctor_queue_number on the entry.
  int getNextDoctorSequence(String department, String doctorName) {
    final today = DateHelper.todayKey();
    final docKey = DoctorHelper.formatName(doctorName);
    final counterKey = '$department::$docKey::$today';
    // Don't increment — just peek at current +1
    return (_counters[counterKey] ?? 0) + 1;
  }

  /// Get all queue entries for a specific doctor today.
  Future<List<QueueEntry>> getDoctorQueue(
      String department, String doctorName) async {
    final queue = await getDepartmentQueue(department);
    return queue
        .where((e) =>
            e.assignedDoctor != null &&
            DoctorHelper.isSameDoctor(e.assignedDoctor, doctorName))
        .toList();
  }

  /// Call the next waiting patient for a specific doctor
  Future<QueueEntry?> callDoctorNext(
      String department, String doctorName) async {
    final queue = await getDepartmentQueue(department);
    final docWaiting = queue
        .where((e) =>
            e.isWaiting &&
            e.assignedDoctor != null &&
            DoctorHelper.isSameDoctor(e.assignedDoctor, doctorName))
        .toList();
    if (docWaiting.isEmpty) return null;

    final next = docWaiting.first;
    final doctorRoom = (next.assignedRoom != null &&
            next.assignedRoom!.trim().isNotEmpty &&
            next.assignedRoom!.trim().toLowerCase() != 'nurse station')
        ? next.assignedRoom
        : DoctorHelper.getDoctorRoom(doctorName, department: department);
    final updated = next.copyWith(
      status: 'serving',
      assignedRoom: doctorRoom,
      assignedDoctor: doctorName,
      calledAt: DateTime.now(),
    );
    return updateEntry(updated);
  }

  /// Get all currently serving entries for a department (each active doctor may have one)
  Future<List<QueueEntry>> getServingEntries(String department) async {
    final queue = await getDepartmentQueue(department);
    return queue.where((e) => e.isServing).toList();
  }

  /// Update a queue entry's status
  Future<QueueEntry> updateEntry(QueueEntry entry) async {
    await _ensureQueueVitalsLoaded();
    if (entry.vitalSigns != null) {
      _queueVitalsCache[entry.id] = entry.vitalSigns!.toJson();
      _persistQueueVitalsCache();
    }

    if (isSupabase) {
      try {
        final payload = Map<String, dynamic>.from(entry.toSupabaseJson());
        if (entry.vitalSigns != null) {
          payload['vital_signs'] = entry.vitalSigns!.toJson();
        }
        await SupabaseService.client
            .from('queue_entries')
            .update(payload)
            .eq('id', entry.id);
      } catch (e) {
        debugPrint('Supabase queue update error: $e');
        try {
          final payload = Map<String, dynamic>.from(entry.toSupabaseJson());
          final errStr = e.toString();
          final match = RegExp(r"Could not find the '([^']+)' column").firstMatch(errStr);
          if (match != null) {
            payload.remove(match.group(1));
          }
          payload.remove('vital_signs');
          if (errStr.contains('assigned_doctor')) {
            payload.remove('assigned_doctor');
          }
          if (errStr.contains('assigned_room')) {
            payload.remove('assigned_room');
          }
          await SupabaseService.client
              .from('queue_entries')
              .update(payload)
              .eq('id', entry.id);
        } catch (e2) {
          debugPrint('Supabase queue fallback update error: $e2');
        }
      }
    }
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) _entries[idx] = entry;
    return entry;
  }

  /// Call the next patient in a department
  Future<QueueEntry?> callNext(String department) async {
    final waiting = await getWaiting(department);
    final waitingOnly =
        waiting.where((e) => e.isWaiting).toList();
    if (waitingOnly.isEmpty) return null;

    final next = waitingOnly.first;
    // Use patient's pre-assigned room or designated doctor room from check-in
    final doctorRoom = (next.assignedRoom != null &&
            next.assignedRoom!.trim().isNotEmpty &&
            next.assignedRoom!.trim().toLowerCase() != 'nurse station')
        ? next.assignedRoom
        : DoctorHelper.getDoctorRoom(next.assignedDoctor, department: department);
    final updated = next.copyWith(
      status: 'serving',
      assignedRoom: doctorRoom,
      calledAt: DateTime.now(),
    );
    return updateEntry(updated);
  }

  /// Locate an entry in memory, loading from storage or Supabase if not yet present
  Future<int> _findOrFetchEntryIndex(String entryId) async {
    var idx = _entries.indexWhere((e) => e.id == entryId);
    if (idx >= 0) return idx;

    // 1. Try refreshing today's queue from storage
    await getTodayQueue(forceRefresh: true);
    idx = _entries.indexWhere((e) => e.id == entryId);
    if (idx >= 0) return idx;

    // 2. Try fetching directly from Supabase by ID
    if (isSupabase) {
      try {
        final res = await SupabaseService.client
            .from('queue_entries')
            .select()
            .eq('id', entryId)
            .maybeSingle();
        if (res != null) {
          final entry = QueueEntry.fromJson(Map<String, dynamic>.from(res));
          _entries.add(entry);
          return _entries.length - 1;
        }
      } catch (e) {
        debugPrint('Fetch entry error in _findOrFetchEntryIndex: $e');
      }
    }
    return -1;
  }

  /// 1st Call: Call a specific patient entry to Nurse Station for Vital Signs triage
  Future<QueueEntry> callForTriage(String entryId, {String? nurseName}) async {
    final idx = await _findOrFetchEntryIndex(entryId);
    if (idx < 0) throw Exception('Entry not found');
    final updated = _entries[idx].copyWith(
      status: 'triage',
      // Preserve assigned doctor room intact! Do not overwrite with 'Nurse Station'
      assistedBy: nurseName ?? _entries[idx].assistedBy,
      calledAt: DateTime.now(),
    );
    return updateEntry(updated);
  }

  /// Complete triage and return patient to waiting for doctor consultation (2nd call)
  Future<QueueEntry> completeTriage(String entryId, {VitalSigns? vitals, String? assistedBy}) async {
    final idx = await _findOrFetchEntryIndex(entryId);
    if (idx < 0) throw Exception('Entry not found');
    final updated = _entries[idx].copyWith(
      status: 'waiting',
      vitalSigns: vitals ?? _entries[idx].vitalSigns,
      assistedBy: assistedBy ?? _entries[idx].assistedBy,
    );
    return updateEntry(updated);
  }

  /// Call a specific patient entry into a consultation room (2nd Call)
  Future<QueueEntry> callEntry(String entryId, {String? roomNumber, String? doctor}) async {
    final idx = await _findOrFetchEntryIndex(entryId);
    if (idx < 0) throw Exception('Entry not found');
    final current = _entries[idx];
    final assignedDoc = doctor ?? current.assignedDoctor;

    // Resolve designated doctor room — never 'Nurse Station' for 2nd Call
    var resolvedRoom = roomNumber;
    if (resolvedRoom == null ||
        resolvedRoom.trim().isEmpty ||
        resolvedRoom.trim().toLowerCase() == 'nurse station') {
      resolvedRoom = (current.assignedRoom != null &&
              current.assignedRoom!.trim().isNotEmpty &&
              current.assignedRoom!.trim().toLowerCase() != 'nurse station')
          ? current.assignedRoom
          : DoctorHelper.getDoctorRoom(assignedDoc, department: current.department);
    }

    final updated = current.copyWith(
      status: 'serving',
      assignedRoom: resolvedRoom,
      assignedDoctor: assignedDoc,
      calledAt: DateTime.now(),
    );
    return updateEntry(updated);
  }

  /// Mark a patient as completed
  Future<QueueEntry> markComplete(String entryId) async {
    final idx = await _findOrFetchEntryIndex(entryId);
    if (idx < 0) {
      // Direct Supabase update fallback if entry is not in local memory
      if (isSupabase) {
        final now = DateTime.now();
        try {
          await SupabaseService.client
              .from('queue_entries')
              .update({
                'status': 'completed',
                'completed_at': now.toIso8601String(),
              })
              .eq('id', entryId);
          return QueueEntry(
            id: entryId,
            patientId: '',
            patientName: '',
            department: '',
            queueNumber: '',
            purpose: '',
            status: 'completed',
            dateKey: DateHelper.todayKey(),
            completedAt: now,
          );
        } catch (e) {
          debugPrint('Supabase direct markComplete error: $e');
        }
      }
      throw Exception('Entry not found');
    }
    final updated = _entries[idx].copyWith(
      status: 'completed',
      completedAt: DateTime.now(),
    );
    return updateEntry(updated);
  }

  /// Skip a patient
  Future<QueueEntry> skipEntry(String entryId) async {
    final idx = await _findOrFetchEntryIndex(entryId);
    if (idx < 0) throw Exception('Entry not found');
    final updated = _entries[idx].copyWith(status: 'skipped');
    return updateEntry(updated);
  }

  /// Put a patient on hold
  Future<QueueEntry> holdEntry(String entryId) async {
    final idx = await _findOrFetchEntryIndex(entryId);
    if (idx < 0) throw Exception('Entry not found');
    final updated = _entries[idx].copyWith(status: 'on_hold');
    return updateEntry(updated);
  }

  /// Resume a patient from hold back to waiting
  Future<QueueEntry> resumeEntry(String entryId) async {
    final idx = await _findOrFetchEntryIndex(entryId);
    if (idx < 0) throw Exception('Entry not found');
    final updated = _entries[idx].copyWith(status: 'waiting');
    return updateEntry(updated);
  }

  /// Remove a patient from the queue entirely
  Future<void> removeEntry(String entryId) async {
    if (isSupabase) {
      try {
        await SupabaseService.client
            .from('queue_entries')
            .delete()
            .eq('id', entryId);
      } catch (e) {
        debugPrint('Supabase queue delete error: $e');
      }
    }
    _entries.removeWhere((e) => e.id == entryId);
  }

  /// Reassign a queue entry to another doctor or room
  Future<void> reassignDoctorAndRoom(String entryId, {String? doctor, String? room}) async {
    if (isSupabase) {
      try {
        final updates = <String, dynamic>{};
        if (doctor != null) updates['assigned_doctor'] = doctor;
        if (room != null) updates['assigned_room'] = room;
        if (updates.isNotEmpty) {
          await SupabaseService.client
              .from('queue_entries')
              .update(updates)
              .eq('id', entryId);
        }
      } catch (e) {
        debugPrint('Supabase queue reassign error: $e');
      }
    }
    final idx = _entries.indexWhere((e) => e.id == entryId);
    if (idx != -1) {
      _entries[idx] = _entries[idx].copyWith(
        assignedDoctor: doctor ?? _entries[idx].assignedDoctor,
        assignedRoom: room ?? _entries[idx].assignedRoom,
      );
    }
  }

  /// Get queue statistics for today
  Future<Map<String, int>> getStats(String department) async {
    final queue = await getDepartmentQueue(department);
    return {
      'waiting': queue.where((e) => e.isWaiting).length,
      'serving': queue.where((e) => e.isServing).length,
      'completed': queue.where((e) => e.isCompleted).length,
      'skipped': queue.where((e) => e.isSkipped).length,
      'onHold': queue.where((e) => e.isOnHold).length,
      'total': queue.length,
    };
  }

  /// Reset today's sequence counter back to zero (001)
  void resetDailyCounters() {
    final today = DateHelper.todayKey();
    // Remove all counter keys that belong to today (both dept and per-doctor)
    _counters.removeWhere((key, _) =>
        key.endsWith('_$today') || key.contains('::$today'));
  }

  /// Get archived queue entries filtered by date, department, or search query
  Future<List<QueueEntry>> getArchivedEntries({
    String? dateKey,
    String? department,
    String? searchQuery,
  }) async {
    final today = DateHelper.todayKey();
    List<QueueEntry> results = [];

    if (isSupabase) {
      try {
        var query = SupabaseService.client.from('queue_entries').select();

        if (dateKey != null && dateKey.isNotEmpty && dateKey != 'ALL') {
          query = query.eq('date_key', dateKey);
        } else {
          // If no specific date selected or 'ALL', fetch all past dates
          query = query.neq('date_key', today);
        }

        if (department != null && department.isNotEmpty && department != 'ALL') {
          query = query.eq('department', department);
        }

        final data = await query.order('created_at', ascending: false);
        results = (data as List).map((j) => QueueEntry.fromJson(j)).toList();
      } catch (e) {
        debugPrint('Supabase archive fetch error: $e');
        results = _entries.where((e) {
          final matchDate =
              (dateKey != null && dateKey.isNotEmpty && dateKey != 'ALL')
                  ? e.dateKey == dateKey
                  : e.dateKey != today;
          final matchDept =
              (department == null || department.isEmpty || department == 'ALL')
                  ? true
                  : e.department == department;
          return matchDate && matchDept;
        }).toList();
      }
    } else {
      results = _entries.where((e) {
        final matchDate =
            (dateKey != null && dateKey.isNotEmpty && dateKey != 'ALL')
                ? e.dateKey == dateKey
                : e.dateKey != today;
        final matchDept =
            (department == null || department.isEmpty || department == 'ALL')
                ? true
                : e.department == department;
        return matchDate && matchDept;
      }).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      results = results.where((e) {
        return e.patientName.toLowerCase().contains(q) ||
            e.queueNumber.toLowerCase().contains(q) ||
            e.purpose.toLowerCase().contains(q) ||
            (e.assignedDoctor != null &&
                e.assignedDoctor!.toLowerCase().contains(q)) ||
            (e.assignedRoom != null &&
                e.assignedRoom!.toLowerCase().contains(q));
      }).toList();
    }

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  /// Get all unique dates available in the archive
  Future<List<String>> getArchiveDates() async {
    final today = DateHelper.todayKey();
    final Set<String> dates = {};

    if (isSupabase) {
      try {
        final data = await SupabaseService.client
            .from('queue_entries')
            .select('date_key')
            .order('date_key', ascending: false);
        for (final row in data as List) {
          final dk = row['date_key'] as String?;
          if (dk != null && dk.isNotEmpty && dk != today) {
            dates.add(dk);
          }
        }
      } catch (e) {
        debugPrint('Supabase archive dates error: $e');
      }
    }

    for (final e in _entries) {
      if (e.dateKey != today) {
        dates.add(e.dateKey);
      }
    }

    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  // ── Storage ──

  Future<void> _loadFromStorage() async {
    await _ensureQueueVitalsLoaded();
    final today = DateHelper.todayKey();
    _lastLoadedDateKey = today;

    if (isSupabase) {
      try {
        final data = await SupabaseService.client
            .from('queue_entries')
            .select()
            .eq('date_key', today)
            .order('created_at');
        final todayEntries = <QueueEntry>[];
        for (final j in data as List) {
          try {
            var entry = QueueEntry.fromJson(Map<String, dynamic>.from(j as Map));
            if (entry.vitalSigns == null && _queueVitalsCache.containsKey(entry.id)) {
              entry = entry.copyWith(
                vitalSigns: VitalSigns.fromJson(_queueVitalsCache[entry.id]!),
              );
            } else if (entry.vitalSigns != null) {
              _queueVitalsCache[entry.id] = entry.vitalSigns!.toJson();
            }
            todayEntries.add(entry);
          } catch (rowErr) {
            debugPrint('Notice: error parsing queue entry row: $rowErr');
          }
        }
        _persistQueueVitalsCache();

        // Keep past cached entries and replace today's entries
        _entries.removeWhere((e) => e.dateKey == today);
        _entries.addAll(todayEntries);

        // Reset and rebuild counters for today — per-doctor keys
        _counters.removeWhere(
            (key, _) => !key.endsWith('_$today') && !key.contains('::$today'));
        for (final entry in todayEntries) {
          // Per-doctor counter key
          final docKey = (entry.assignedDoctor != null &&
                  entry.assignedDoctor!.isNotEmpty)
              ? DoctorHelper.formatName(entry.assignedDoctor!)
              : '_nodoc';
          final perDoctorKey =
              '${entry.department}::$docKey::$today';
          final rawNum =
              int.tryParse(entry.queueNumber.split('-').last) ?? 0;
          if ((_counters[perDoctorKey] ?? 0) < rawNum) {
            _counters[perDoctorKey] = rawNum;
          }
          // Also keep legacy dept key in sync
          final legacyKey = '${entry.department}_$today';
          if ((_counters[legacyKey] ?? 0) < rawNum) {
            _counters[legacyKey] = rawNum;
          }
        }
        _loaded = true;
        return;
      } catch (e) {
        debugPrint('Supabase queue load error: $e');
      }
    }
    _loaded = true;
  }

  StreamSubscription? _realtimeSubscription;

  /// Listen for realtime queue changes.
  /// Cancels any previously registered subscription before creating a new one
  /// to prevent stale / duplicate stream listeners.
  void listenToChanges(VoidCallback onChanged) {
    if (!isSupabase) return;
    _realtimeSubscription?.cancel();
    _realtimeSubscription = SupabaseService.client
        .from('queue_entries')
        .stream(primaryKey: ['id']).listen((_) async {
      _loaded = false;
      await _loadFromStorage();
      onChanged();
    });
  }

  /// Cancel the realtime subscription
  void cancelListener() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }
}
