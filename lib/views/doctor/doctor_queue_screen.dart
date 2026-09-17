import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/queue_entry.dart';
import '../../data/models/vital_signs.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/queue_provider.dart';

class DoctorQueueScreen extends StatefulWidget {
  const DoctorQueueScreen({super.key});

  @override
  State<DoctorQueueScreen> createState() => _DoctorQueueScreenState();
}

class _DoctorQueueScreenState extends State<DoctorQueueScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorProv = context.watch<DoctorProvider>();
    final queueProv = context.watch<QueueProvider>();
    final allQueue = queueProv.todayQueue;

    final myQueue = allQueue.where((e) =>
        e.department == doctorProv.activeDepartment ||
        (e.assignedDoctor != null && e.assignedDoctor == doctorProv.activeDoctor)
    ).toList();

    final waitingList = myQueue.where((e) => e.isWaiting).toList();
    final inProgressList = myQueue.where((e) => e.isServing).toList();
    final completedList = myQueue.where((e) => e.isCompleted).toList();

    const themeColor = AppColors.doctorPrimary;

    List<QueueEntry> applySearch(List<QueueEntry> list) {
      if (_searchQuery.trim().isEmpty) return list;
      final q = _searchQuery.toLowerCase();
      return list.where((e) =>
          e.patientName.toLowerCase().contains(q) ||
          e.queueNumber.toLowerCase().contains(q) ||
          e.purpose.toLowerCase().contains(q)
      ).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doctor Patient Queue',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${doctorProv.formattedDoctorName} • ${doctorProv.activeRoom}',
              style: TextStyle(fontSize: 12, color: themeColor),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by patient name or queue #...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                    ),
                  ),
                ),
              ),
              // TabBar matching DoctorVisitQueue.jsx filters
              TabBar(
                controller: _tabController,
                indicatorColor: themeColor,
                labelColor: themeColor,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'All (${myQueue.length})'),
                  Tab(text: 'Waiting (${waitingList.length})'),
                  Tab(text: 'In Progress (${inProgressList.length})'),
                  Tab(text: 'Completed (${completedList.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── All Tab ───────────────────────────────────────────────
          _buildQueueListView(
            applySearch(myQueue),
            doctorProv,
            themeColor,
            emptyMessage: 'No patients found in your queue today.',
          ),
          // ── Waiting Tab ───────────────────────────────────────────
          _buildQueueListView(
            applySearch(waitingList),
            doctorProv,
            themeColor,
            emptyMessage: 'No patients currently waiting for consultation.',
          ),
          // ── In Progress Tab ───────────────────────────────────────
          _buildQueueListView(
            applySearch(inProgressList),
            doctorProv,
            themeColor,
            emptyMessage: 'No consultation currently in progress.',
          ),
          // ── Completed Tab ─────────────────────────────────────────
          _buildQueueListView(
            applySearch(completedList),
            doctorProv,
            themeColor,
            emptyMessage: 'No patients completed yet today.',
          ),
        ],
      ),
    );
  }

  Widget _buildQueueListView(
    List<QueueEntry> list,
    DoctorProvider doctorProv,
    Color themeColor, {
    required String emptyMessage,
  }) {
    if (list.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final entry = list[index];
        final isNext = entry.isWaiting && index == 0;
        return _buildEnrichedPatientCard(
          context: context,
          entry: entry,
          isNext: isNext,
          doctorProv: doctorProv,
          themeColor: themeColor,
        );
      },
    );
  }

  Widget _buildEnrichedPatientCard({
    required BuildContext context,
    required QueueEntry entry,
    required bool isNext,
    required DoctorProvider doctorProv,
    required Color themeColor,
  }) {
    final isCompleted = entry.isCompleted;
    final isServing = entry.isServing;

    Color statusColor = const Color(0xFFF59E0B);
    String statusLabel = 'Waiting';
    if (isServing) {
      statusColor = AppColors.doctorPrimary;
      statusLabel = 'In Consultation';
    } else if (isCompleted) {
      statusColor = AppColors.success;
      statusLabel = 'Completed';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isNext
              ? const Color(0xFFF59E0B)
              : (isServing ? themeColor : Theme.of(context).dividerColor.withValues(alpha: 0.2)),
          width: isNext || isServing ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Header: Queue #, Source Badge & Status Badge ────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isNext ? const Color(0xFFF59E0B) : themeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.queueNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.source == 'walkin' ? 'Walk-in Visit' : 'Scheduled',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record, color: statusColor, size: 8),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Patient Info ────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: themeColor.withValues(alpha: 0.12),
                  child: Icon(Icons.person_rounded, color: themeColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Reason: ${entry.purpose}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Assisted By Nurse & Time Row ─────────────────────────
            Row(
              children: [
                const Icon(Icons.person_pin_rounded, size: 14, color: Color(0xFF0D9488)),
                const SizedBox(width: 4),
                Text(
                  'Assisted by: ${entry.assistedBy ?? "Triage Nurse"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0D9488),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Time: ${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),

            // ── Vital Signs Row (from DoctorVisitQueue.jsx) ───────────
            _buildVitalsSummaryRow(entry.vitalSigns),

            const SizedBox(height: 14),

            // ── Action Buttons ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isCompleted) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push(
                        '/doctor/consultation/${entry.patientId}',
                        extra: entry,
                      );
                    },
                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                    label: const Text('View Clinical Record'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ] else if (isServing) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push(
                        '/doctor/consultation/${entry.patientId}',
                        extra: entry,
                      );
                    },
                    icon: const Icon(Icons.medical_services_rounded, size: 16),
                    label: const Text('Continue Consultation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      await doctorProv.callPatient(entry);
                      if (context.mounted) {
                        context.push(
                          '/doctor/consultation/${entry.patientId}',
                          extra: entry,
                        );
                      }
                    },
                    icon: const Icon(Icons.meeting_room_rounded, size: 16),
                    label: const Text('Call into Room & Consult'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isNext ? const Color(0xFFF59E0B) : themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsSummaryRow(VitalSigns? vitals) {
    // If no vitals model attached, show placeholder sample or empty notice
    final bp = vitals?.bloodPressure ?? '120/80';
    final temp = vitals?.temperature != null ? '${vitals!.temperature}°C' : '36.6°C';
    final hr = vitals?.heartRate != null ? '${vitals!.heartRate} bpm' : '76 bpm';
    final rr = vitals?.respiratoryRate != null ? '${vitals!.respiratoryRate}/min' : '18/min';
    final spo2 = vitals?.oxygenSaturation != null ? '${vitals!.oxygenSaturation}%' : '98%';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildVitalBadge(Icons.thermostat_rounded, Colors.orange, temp),
          _buildVitalBadge(Icons.monitor_heart_rounded, Colors.red, bp),
          _buildVitalBadge(Icons.favorite_rounded, Colors.pink, hr),
          _buildVitalBadge(Icons.air_rounded, AppColors.cyanCalm, rr),
          _buildVitalBadge(Icons.water_drop_rounded, const Color(0xFF0D9488), spo2),
        ],
      ),
    );
  }

  Widget _buildVitalBadge(IconData icon, Color color, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
