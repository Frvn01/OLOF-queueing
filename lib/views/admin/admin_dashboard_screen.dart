import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/clinic_provider.dart';
import '../../providers/queue_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueProv = context.watch<QueueProvider>();
    final adminProv = context.watch<AdminProvider>();
    final clinicProv = context.watch<ClinicProvider>();
    final todayQueue = queueProv.todayQueue;

    final entDoctor = clinicProv.getDoctors(department: AppConstants.deptEnt).isNotEmpty
        ? clinicProv.getDoctors(department: AppConstants.deptEnt).first.name
        : AppConstants.departmentDoctors[AppConstants.deptEnt]!;
    final eyesDoctor = clinicProv.getDoctors(department: AppConstants.deptEyes).isNotEmpty
        ? clinicProv.getDoctors(department: AppConstants.deptEyes).first.name
        : AppConstants.departmentDoctors[AppConstants.deptEyes]!;

    final totalQueued = todayQueue.length;
    final servingCount = todayQueue.where((e) => e.isServing).length;
    final waitingCount = todayQueue.where((e) => e.isWaiting || e.isOnHold).length;
    final completedCount = todayQueue.where((e) => e.isCompleted).length;

    final entQueue = todayQueue.where((e) => e.department == AppConstants.deptEnt).toList();
    final eyesQueue = todayQueue.where((e) => e.department == AppConstants.deptEyes).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Metric Cards Row ──────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1000 ? 4 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.8,
                children: [
                  _buildMetricCard(
                    title: 'Total Queued Today',
                    value: '$totalQueued',
                    subtitle: 'All departments',
                    icon: Icons.confirmation_number_rounded,
                    color: AppColors.primary,
                  ),
                  _buildMetricCard(
                    title: 'Serving Now',
                    value: '$servingCount',
                    subtitle: 'Inside doctor rooms',
                    icon: Icons.record_voice_over_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  _buildMetricCard(
                    title: 'Waiting in Line',
                    value: '$waitingCount',
                    subtitle: 'Patients in waiting area',
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  _buildMetricCard(
                    title: 'Completed Today',
                    value: '$completedCount',
                    subtitle: 'Visits concluded',
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // ── Active Doctor Rooms & Departments Row ─────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Rooms Card
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.meeting_room_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 10),
                            const Text(
                              'Consultation Rooms Status',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRoomTile(
                          roomName: 'ENT ROOM 1',
                          doctorName: entDoctor,
                          department: AppConstants.deptEnt,
                          servingEntry: adminProv.getDoctorServing(
                            todayQueue,
                            entDoctor,
                            AppConstants.deptEnt,
                          ),
                          waitingCount: todayQueue
                              .where((e) => (e.isWaiting || e.isOnHold) && e.department == AppConstants.deptEnt)
                              .length,
                        ),
                        const Divider(height: 24),
                        _buildRoomTile(
                          roomName: 'OPHTHA ROOM 1',
                          doctorName: eyesDoctor,
                          department: AppConstants.deptEyes,
                          servingEntry: adminProv.getDoctorServing(
                            todayQueue,
                            eyesDoctor,
                            AppConstants.deptEyes,
                          ),
                          waitingCount: todayQueue
                              .where((e) => (e.isWaiting || e.isOnHold) && e.department == AppConstants.deptEyes)
                              .length,
                        ),
                        const Divider(height: 24),
                        _buildRoomTile(
                          roomName: 'OPHTHA ROOM 2',
                          doctorName: 'Dr. DR. AMELIA REYES VERA CRUZ',
                          department: AppConstants.deptEyes,
                          servingEntry: null,
                          waitingCount: 0,
                          isStandby: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Department Breakdown & Local Storage Info
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Department Breakdown
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.pie_chart_rounded, color: Color(0xFF0D9488), size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Department Split',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _buildDeptBar(
                              name: 'ENT Department',
                              count: entQueue.length,
                              total: totalQueued,
                              color: AppColors.entPrimary,
                            ),
                            const SizedBox(height: 14),
                            _buildDeptBar(
                              name: 'Eyes (Ophthalmology)',
                              count: eyesQueue.length,
                              total: totalQueued,
                              color: AppColors.eyesPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Local Storage & Backup Widget
                    Card(
                      elevation: 0,
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.shield_rounded, color: AppColors.success, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Local PC Storage (Option A)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Drawings and photos are saved directly to this clinic PC. Cloud storage quota: Protected (0% consumed).',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Used on Disk: ${adminProv.storageStats['formattedSize'] ?? 'Scanning...'}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                TextButton.icon(
                                  onPressed: () => adminProv.setNavigationIndex(4),
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                  label: const Text('Manage', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTile({
    required String roomName,
    required String doctorName,
    required String department,
    required dynamic servingEntry,
    required int waitingCount,
    bool isStandby = false,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isStandby
                ? Colors.grey.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isStandby ? Icons.chair_rounded : Icons.person_rounded,
            color: isStandby ? Colors.grey : AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                roomName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                doctorName,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (servingEntry != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record, size: 8, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  'Serving ${servingEntry.queueNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isStandby ? 'Standby' : 'Available',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
        const SizedBox(width: 16),
        Text(
          '$waitingCount waiting',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDeptBar({
    required String name,
    required int count,
    required int total,
    required Color color,
  }) {
    final pct = total > 0 ? (count / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('$count patients (${(pct * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
