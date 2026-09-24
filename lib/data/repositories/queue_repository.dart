import 'package:flutter/foundation.dart';
import '../models/queue_entry.dart';
import '../services/supabase_service.dart';
import '../../core/utils/helpers.dart';

/// Queue CRUD operations — Supabase with in-memory fallback
class QueueRepository {
  final List<QueueEntry> _entries = [];
  bool _loaded = false;
  String _lastLoadedDateKey = '';
  final Map<String, int> _counters = {}; // department -> sequence

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
    return queue.where((e) => e.department == department).toList();
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

  /// Get next queue number for a department
  String getNextQueueNumber(String department) {
    final today = DateHelper.todayKey();
    final key = '${department}_$today';
    _counters[key] = (_counters[key] ?? 0) + 1;
    return QueueNumberGenerator.generate(department, _counters[key]!);
  }

  /// Update a queue entry's status
  Future<QueueEntry> updateEntry(QueueEntry entry) async {
    if (isSupabase) {
      try {
        await SupabaseService.client
            .from('queue_entries')
            .update(entry.toSupabaseJson())
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
    // Use patient's pre-assigned room and doctor from check-in
    final updated = next.copyWith(
      status: 'serving',
      calledAt: DateTime.now(),
    );
    return updateEntry(updated);
  }

  /// Call a specific patient entry into a consultation room
  Future<QueueEntry> callEntry(String entryId, {String? roomNumber, String? doctor}) async {
    final idx = _entries.indexWhere((e) => e.id == entryId);
    if (idx < 0) throw Exception('Entry not found');
    final updated = _entries[idx].copyWith(
      status: 'serving',
      assignedRoom: roomNumber ?? _entries[idx].assignedRoom,
      assignedDoctor: doctor ?? _entries[idx].assignedDoctor,
      calledAt: DateTime.now(),
    );
    return updateEntry(updated);
  }

  /// Mark a patient as completed
  Future<QueueEntry> markComplete(String entryId) async {
    final idx = _entries.indexWhere((e) => e.id == entryId);
    if (idx < 0) throw Exception('Entry not found');
    final updated = _entries[idx].copyWith(
      status: 'completed',
      completedAt: DateTime.now(),
    );
    return updateEntry(updated);
  }

  /// Skip a patient
  Future<QueueEntry> skipEntry(String entryId) async {
    final idx = _entries.indexWhere((e) => e.id == entryId);
    if (idx < 0) throw Exception('Entry not found');
    final updated = _entries[idx].copyWith(status: 'skipped');
    return updateEntry(updated);
  }

  /// Put a patient on hold
  Future<QueueEntry> holdEntry(String entryId) async {
    final idx = _entries.indexWhere((e) => e.id == entryId);
    if (idx < 0) throw Exception('Entry not found');
    final updated = _entries[idx].copyWith(status: 'on_hold');
    return updateEntry(updated);
  }

  /// Resume a patient from hold back to waiting
  Future<QueueEntry> resumeEntry(String entryId) async {
    final idx = _entries.indexWhere((e) => e.id == entryId);
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
    _counters.removeWhere((key, _) => key.endsWith('_$today'));
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
            todayEntries.add(QueueEntry.fromJson(Map<String, dynamic>.from(j as Map)));
          } catch (rowErr) {
            debugPrint('Notice: error parsing queue entry row: $rowErr');
          }
        }

        // Keep past cached entries and replace today's entries
        _entries.removeWhere((e) => e.dateKey == today);
        _entries.addAll(todayEntries);

        // Reset and rebuild counters ONLY for today
        _counters.removeWhere((key, _) => !key.endsWith('_$today'));
        for (final entry in todayEntries) {
          final key = '${entry.department}_$today';
          final num = int.tryParse(
                  entry.queueNumber.split('-').last) ??
              0;
          if ((_counters[key] ?? 0) < num) {
            _counters[key] = num;
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

  /// Listen for realtime queue changes
  void listenToChanges(VoidCallback onChanged) {
    if (!isSupabase) return;
    SupabaseService.client
        .from('queue_entries')
        .stream(primaryKey: ['id']).listen((_) async {
      _loaded = false;
      await _loadFromStorage();
      onChanged();
    });
  }
}
