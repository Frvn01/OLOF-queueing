import 'package:flutter/foundation.dart';
import '../models/queue_entry.dart';
import '../services/supabase_service.dart';
import '../../core/utils/helpers.dart';

/// Queue CRUD operations — Supabase with in-memory fallback
class QueueRepository {
  List<QueueEntry> _entries = [];
  bool _loaded = false;
  final Map<String, int> _counters = {}; // department -> sequence

  bool get isSupabase => SupabaseService.isConfigured;

  /// Load today's queue
  Future<List<QueueEntry>> getTodayQueue() async {
    if (!_loaded) await _loadFromStorage();
    final today = DateHelper.todayKey();
    return _entries.where((e) => e.dateKey == today).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Get queue for a specific department (today only)
  Future<List<QueueEntry>> getDepartmentQueue(String department) async {
    final queue = await getTodayQueue();
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
            .insert(entry.toJson());
      } catch (e) {
        debugPrint('Supabase queue insert error: $e');
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
            .update(entry.toJson())
            .eq('id', entry.id);
      } catch (e) {
        debugPrint('Supabase queue update error: $e');
      }
    }
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) _entries[idx] = entry;
    return entry;
  }

  /// Call the next patient in a department
  Future<QueueEntry?> callNext(String department, String room) async {
    final waiting = await getWaiting(department);
    final waitingOnly =
        waiting.where((e) => e.isWaiting).toList();
    if (waitingOnly.isEmpty) return null;

    final next = waitingOnly.first;
    final updated = next.copyWith(
      status: 'serving',
      assignedRoom: room,
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

  // ── Storage ──

  Future<void> _loadFromStorage() async {
    if (isSupabase) {
      try {
        final today = DateHelper.todayKey();
        final data = await SupabaseService.client
            .from('queue_entries')
            .select()
            .eq('date_key', today)
            .order('created_at');
        _entries =
            (data as List).map((j) => QueueEntry.fromJson(j)).toList();

        // Rebuild counters
        for (final entry in _entries) {
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
