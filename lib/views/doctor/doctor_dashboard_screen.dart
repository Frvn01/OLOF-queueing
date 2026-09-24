import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/models/queue_entry.dart';
import '../../data/models/visit_record.dart';
import '../../data/repositories/patient_repository.dart';
import '../../providers/clinic_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/queue_provider.dart';
import '../../shared/widgets/olof_logo.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const DoctorDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final PatientRepository _patientRepo = PatientRepository();
  List<VisitRecord> _allVisits = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueProvider>().initialize();
      _loadVisits();
    });
  }

  Future<void> _loadVisits() async {
    try {
      final visits = await _patientRepo.getAllVisitRecords();
      if (mounted) {
        setState(() => _allVisits = visits);
      }
    } catch (_) {}
  }

  ImageProvider _getDoctorImageProvider(String path) {
    final provider = AppImageHelper.buildImageProvider(path);
    if (provider != null) return provider;
    return NetworkImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final doctorProv = context.watch<DoctorProvider>();
    final queueProv = context.watch<QueueProvider>();
    final allQueue = queueProv.todayQueue;

    final servingPatient = doctorProv.getServingPatient(allQueue);
    final nextPatient = doctorProv.getNextPatient(allQueue);
    final waitingList = doctorProv.getAllWaitingPatients(allQueue);
    final completedList = doctorProv.getCompletedPatients(allQueue);

    const themeColor = Color(0xFF059669);
    final totalToday = waitingList.length + completedList.length + (servingPatient != null ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const OlofLogo(size: 34, showBorder: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorProv.formattedDoctorName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${doctorProv.activeDepartment} • ${doctorProv.activeRoom}',
                    style: TextStyle(fontSize: 11, color: themeColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch Doctor Profile',
            icon: const Icon(Icons.switch_account_rounded),
            onPressed: () => _showSwitchDoctorDialog(context, doctorProv),
          ),
          IconButton(
            tooltip: 'Refresh Queue Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => queueProv.initialize(forceRefresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => queueProv.initialize(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ── Welcome Banner ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor.withValues(alpha: 0.15),
                    themeColor.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: themeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: themeColor,
                    backgroundImage: (doctorProv.photoUrl != null && doctorProv.photoUrl!.isNotEmpty)
                        ? _getDoctorImageProvider(doctorProv.photoUrl!)
                        : null,
                    child: (doctorProv.photoUrl != null && doctorProv.photoUrl!.isNotEmpty)
                        ? null
                        : const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${doctorProv.formattedDoctorName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${doctorProv.activeDepartment} Specialist • ${doctorProv.activeRoom}',
                          style: TextStyle(fontSize: 12, color: themeColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: AppColors.success, size: 8),
                        SizedBox(width: 6),
                        Text(
                          'ON DUTY',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 4 Stat Cards Grid (from DoctorDashboard.jsx) ─────────
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: "Today's Visits",
                    count: totalToday,
                    subtitle: '${completedList.length} completed',
                    color: AppColors.primary,
                    icon: Icons.calendar_month_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: "Visit Queue",
                    count: waitingList.length,
                    subtitle: 'Patients waiting',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.assignment_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: "Completed Today",
                    count: completedList.length,
                    subtitle: '${waitingList.length} pending',
                    color: AppColors.success,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: "Patients in Directory",
                    count: doctorProv.patients.length,
                    subtitle: 'Reception uploads',
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.people_alt_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── In-Room Serving Patient / Call Next ───────────────────
            if (servingPatient != null)
              _buildActiveConsultationCard(context, servingPatient, doctorProv, themeColor)
            else
              _buildReadyForNextCard(context, nextPatient, doctorProv, queueProv, themeColor),

            const SizedBox(height: 24),

            // ── Today's Appointments / Patient Schedule ─────────────
            _buildTodayScheduleSection(context, allQueue, doctorProv, themeColor),

            const SizedBox(height: 24),

            // ── Weekly Performance / Trends Bar Chart ────────────────
            _buildWeeklyTrendsCard(context, themeColor, allQueue),

            const SizedBox(height: 24),

            // ── Recent Clinical Activity Feed ───────────────────────
            _buildRecentActivityCard(context, completedList, servingPatient, themeColor),

            const SizedBox(height: 20),

            // ── Quick Shortcut to Full Queue ────────────────────────
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.format_list_bulleted_rounded, color: themeColor),
              ),
              title: const Text('Open Doctor Patient Queue', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${waitingList.length} patients currently waiting for consultation'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/doctor/queue'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required int count,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveConsultationCard(
    BuildContext context,
    QueueEntry entry,
    DoctorProvider doctorProv,
    Color themeColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeColor.withValues(alpha: 0.18),
            themeColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record, size: 8, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'IN CONSULTATION • ${entry.queueNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Room: ${doctorProv.activeRoom}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppImageHelper.buildAvatar(
                photoUrl: entry.patientPhoto,
                name: entry.patientName,
                radius: 22,
                backgroundColor: themeColor.withValues(alpha: 0.15),
                foregroundColor: themeColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Purpose: ${entry.purpose}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push(
                  '/doctor/consultation/${entry.patientId}',
                  extra: entry,
                );
              },
              icon: const Icon(Icons.medical_services_rounded),
              label: const Text(
                'Open Clinical Consultation & Diagram',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyForNextCard(
    BuildContext context,
    QueueEntry? nextPatient,
    DoctorProvider doctorProv,
    QueueProvider queueProv,
    Color themeColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_add_alt_1_rounded, color: themeColor, size: 32),
          ),
          const SizedBox(height: 12),
          const Text(
            'Consultation Room is Available',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            nextPatient != null
                ? 'Next patient is ready: ${nextPatient.queueNumber} - ${nextPatient.patientName}'
                : 'No patients currently waiting in line.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          if (nextPatient != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await doctorProv.callPatient(nextPatient);
                  if (context.mounted) {
                    context.push(
                      '/doctor/consultation/${nextPatient.patientId}',
                      extra: nextPatient,
                    );
                  }
                },
                icon: const Icon(Icons.volume_up_rounded),
                label: Text(
                  'Call In: ${nextPatient.queueNumber} (${nextPatient.patientName})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayScheduleSection(
    BuildContext context,
    List<QueueEntry> allQueue,
    DoctorProvider doctorProv,
    Color themeColor,
  ) {
    final myQueue = allQueue.where((e) =>
        e.department == doctorProv.activeDepartment ||
        (e.assignedDoctor != null && e.assignedDoctor == doctorProv.activeDoctor)
    ).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: themeColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Today\'s Schedule',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/doctor/queue'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (myQueue.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, color: Colors.grey.shade400, size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'No appointments or visits scheduled today.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myQueue.take(5).length,
                separatorBuilder: (_, _) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = myQueue[index];
                  final timeStr = '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';
                  final isServing = item.isServing;
                  final isCompleted = item.isCompleted;

                  Color statusColor = const Color(0xFFF59E0B);
                  String statusText = 'Waiting';
                  if (isServing) {
                    statusColor = themeColor;
                    statusText = 'In Room';
                  } else if (isCompleted) {
                    statusColor = AppColors.success;
                    statusText = 'Completed';
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      context.push(
                        '/doctor/consultation/${item.patientId}',
                        extra: item,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.access_time_filled_rounded, size: 14, color: themeColor),
                                const SizedBox(height: 2),
                                Text(
                                  timeStr,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: themeColor),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          AppImageHelper.buildAvatar(
                            photoUrl: item.patientPhoto,
                            name: item.patientName,
                            radius: 16,
                            backgroundColor: themeColor.withValues(alpha: 0.12),
                            foregroundColor: themeColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.patientName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.queueNumber} • ${item.purpose}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendsCard(
    BuildContext context,
    Color themeColor,
    List<QueueEntry> todayQueue,
  ) {
    // Dynamically calculate weekly patient counts from real visit records & live queue
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final counts = <String, int>{for (final d in dayNames) d: 0};

    for (final v in _allVisits) {
      final weekday = v.visitDate.weekday; // 1 = Mon, 7 = Sun
      if (weekday >= 1 && weekday <= 6) {
        final dName = dayNames[weekday - 1];
        counts[dName] = (counts[dName] ?? 0) + 1;
      }
    }

    // Include today's live queue count into today's weekday
    final nowWeekday = DateTime.now().weekday;
    if (nowWeekday >= 1 && nowWeekday <= 6) {
      final todayName = dayNames[nowWeekday - 1];
      counts[todayName] = (counts[todayName] ?? 0) + todayQueue.length;
    }

    final maxVal = counts.values.fold<int>(0, (max, v) => v > max ? v : max);
    final safeMax = maxVal > 0 ? maxVal : 1;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up_rounded, color: themeColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Weekly Patient Load',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  'Live Records',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...dayNames.map((dayName) {
              final count = counts[dayName] ?? 0;
              final pct = count / safeMax;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('$count ${count == 1 ? 'visit' : 'visits'}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(
    BuildContext context,
    List<QueueEntry> completedList,
    QueueEntry? servingPatient,
    Color themeColor,
  ) {
    final activities = <Map<String, String>>[];
    if (servingPatient != null) {
      activities.add({
        'desc': 'Patient ${servingPatient.patientName} (${servingPatient.queueNumber}) entered consultation room',
        'time': 'Just now',
        'type': 'serving',
      });
    }
    for (final c in completedList.take(3)) {
      activities.add({
        'desc': 'Completed consultation for ${c.patientName} (${c.queueNumber})',
        'time': c.completedAt != null
            ? '${c.completedAt!.hour}:${c.completedAt!.minute.toString().padLeft(2, '0')}'
            : 'Today',
        'type': 'completed',
      });
    }
    if (activities.isEmpty) {
      activities.add({
        'desc': 'Doctor session initialized for today',
        'time': '8:00 AM',
        'type': 'info',
      });
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: themeColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recent Clinical Activity',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...activities.map((act) {
              final isComp = act['type'] == 'completed';
              final isServing = act['type'] == 'serving';
              final dotColor = isComp ? AppColors.success : (isServing ? themeColor : Colors.grey);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act['desc']!,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            act['time']!,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSwitchDoctorDialog(BuildContext context, DoctorProvider doctorProv) {
    final clinicProv = context.read<ClinicProvider>();
    final docs = clinicProv.doctors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.switch_account_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Select Active Doctor Profile'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: docs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No doctors configured in clinic database.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final isSelected = doctorProv.activeDoctor == d.name;
                    const color = AppColors.doctorPrimary;

                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      tileColor: isSelected ? color.withValues(alpha: 0.08) : null,
                      leading: CircleAvatar(
                        backgroundColor: color,
                        backgroundImage: (d.photoUrl != null && d.photoUrl!.isNotEmpty)
                            ? _getDoctorImageProvider(d.photoUrl!)
                            : null,
                        child: (d.photoUrl != null && d.photoUrl!.isNotEmpty)
                            ? null
                            : Text(
                                d.name.isNotEmpty ? d.name.substring(0, 1) : 'D',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                      title: Text(DoctorProvider.formatDoctorName(d.name),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${d.department} • ${d.room ?? (d.department == AppConstants.deptEyes ? 'OPHTHA ROOM 1' : 'ENT ROOM 1')}'),
                      selected: isSelected,
                      onTap: () {
                        doctorProv.selectDoctorModel(d);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched to ${DoctorProvider.formatDoctorName(d.name)}'),
                            backgroundColor: color,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
