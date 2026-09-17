import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/queue_entry.dart';
import '../data/repositories/queue_repository.dart';
import '../core/utils/helpers.dart';

/// State management for queue operations
class QueueProvider extends ChangeNotifier {
  final QueueRepository _repo = QueueRepository();

  List<QueueEntry> _todayQueue = [];
  final Map<String, List<QueueEntry>> _departmentQueues = {};
  final Map<String, QueueEntry?> _nowServing = {};
  final Map<String, Map<String, int>> _stats = {};
  bool _isLoading = false;

  List<QueueEntry> get todayQueue => _todayQueue;
  bool get isLoading => _isLoading;

  /// Get queue for a department
  List<QueueEntry> getQueue(String department) =>
      _departmentQueues[department] ?? [];

  /// Get waiting entries for a department
  List<QueueEntry> getWaiting(String department) =>
      getQueue(department).where((e) => e.isWaiting).toList();

  /// Get on-hold entries for a department
  List<QueueEntry> getOnHold(String department) =>
      getQueue(department).where((e) => e.isOnHold).toList();

  /// Get completed entries for a department
  List<QueueEntry> getCompleted(String department) =>
      getQueue(department).where((e) => e.isCompleted).toList();

  /// Get currently serving for a department
  QueueEntry? getNowServing(String department) => _nowServing[department];

  /// Get stats for a department
  Map<String, int> getStats(String department) =>
      _stats[department] ?? {};

  /// Initialize and load today's queue
  Future<void> initialize({bool forceRefresh = true}) async {
    _isLoading = true;
    notifyListeners();
    await _refreshAll(forceRefresh: forceRefresh);
    _isLoading = false;
    notifyListeners();

    _startDailyTimer();

    // Listen for realtime changes
    _repo.listenToChanges(() async {
      await _refreshAll(forceRefresh: true);
      notifyListeners();
    });
  }

  /// Add patient to queue
  Future<QueueEntry> addToQueue({
    required String patientId,
    required String patientName,
    String? patientPhoto,
    required String department,
    required String purpose,
    String? doctor,
    String? room,
  }) async {
    final queueNumber = _repo.getNextQueueNumber(department);
    final entry = QueueEntry(
      id: IdGenerator.generateUuid(),
      patientId: patientId,
      patientName: patientName,
      patientPhoto: patientPhoto,
      department: department,
      queueNumber: queueNumber,
      purpose: purpose,
      assignedDoctor: doctor,
      assignedRoom: room,
      dateKey: DateHelper.todayKey(),
    );

    final saved = await _repo.addToQueue(entry);
    await _refreshAll();
    notifyListeners();
    return saved;
  }

  /// Call next patient
  Future<QueueEntry?> callNext(String department) async {
    final entry = await _repo.callNext(department);
    await _refreshAll();
    notifyListeners();
    return entry;
  }

  /// Mark patient as completed
  Future<void> markComplete(String entryId) async {
    await _repo.markComplete(entryId);
    await _refreshAll();
    notifyListeners();
  }

  /// Skip patient
  Future<void> skipEntry(String entryId) async {
    await _repo.skipEntry(entryId);
    await _refreshAll();
    notifyListeners();
  }

  /// Put patient on hold
  Future<void> holdEntry(String entryId) async {
    await _repo.holdEntry(entryId);
    await _refreshAll();
    notifyListeners();
  }

  /// Resume patient from hold
  Future<void> resumeEntry(String entryId) async {
    await _repo.resumeEntry(entryId);
    await _refreshAll();
    notifyListeners();
  }

  /// Remove patient from queue
  Future<void> removeFromQueue(String entryId) async {
    await _repo.removeEntry(entryId);
    await _refreshAll();
    notifyListeners();
  }

  /// Reassign patient to another doctor or room
  Future<void> reassignDoctorAndRoom(String entryId, {String? doctor, String? room}) async {
    await _repo.reassignDoctorAndRoom(entryId, doctor: doctor, room: room);
    await _refreshAll();
    notifyListeners();
  }

  /// Get archived queue entries from past dates
  Future<List<QueueEntry>> getArchivedEntries({
    String? dateKey,
    String? department,
    String? searchQuery,
  }) async {
    return _repo.getArchivedEntries(
      dateKey: dateKey,
      department: department,
      searchQuery: searchQuery,
    );
  }

  /// Get all unique dates in the archive
  Future<List<String>> getArchiveDates() async {
    return _repo.getArchiveDates();
  }

  /// Manually reset today's sequence counter back to zero (001)
  Future<void> resetDailyQueue() async {
    _repo.resetDailyCounters();
    await _refreshAll();
    notifyListeners();
  }

  Timer? _dailyCheckTimer;
  String _activeDateKey = DateHelper.todayKey();

  void _startDailyTimer() {
    _dailyCheckTimer?.cancel();
    _dailyCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final nowKey = DateHelper.todayKey();
      if (nowKey != _activeDateKey) {
        _activeDateKey = nowKey;
        await _refreshAll();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _dailyCheckTimer?.cancel();
    super.dispose();
  }

  /// Refresh all queue data
  Future<void> _refreshAll({bool forceRefresh = false}) async {
    _todayQueue = await _repo.getTodayQueue(forceRefresh: forceRefresh);
    for (final dept in ['ENT', 'EYES']) {
      _departmentQueues[dept] = await _repo.getDepartmentQueue(dept, forceRefresh: forceRefresh);
      _nowServing[dept] = await _repo.getCurrentServing(dept);
      _stats[dept] = await _repo.getStats(dept);
    }
  }

  /// Force refresh
  Future<void> refresh() async {
    await _refreshAll(forceRefresh: true);
    notifyListeners();
  }
}
