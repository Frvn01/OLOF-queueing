import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/queue_entry.dart';
import '../../providers/admin_provider.dart';
import '../../providers/queue_provider.dart';

class AdminQueueScreen extends StatefulWidget {
  const AdminQueueScreen({super.key});

  @override
  State<AdminQueueScreen> createState() => _AdminQueueScreenState();
}

class _AdminQueueScreenState extends State<AdminQueueScreen> {
  String _selectedDeptFilter = 'ALL'; // 'ALL', 'ENT', 'EYES'
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final queueProv = context.watch<QueueProvider>();
    final adminProv = context.watch<AdminProvider>();
    final allQueue = queueProv.todayQueue;

    // Filter queue if searching
    final displayedQueue = _searchQuery.isEmpty
        ? allQueue
        : allQueue.where((e) {
            final q = _searchQuery.toLowerCase();
            return e.patientName.toLowerCase().contains(q) ||
                e.queueNumber.toLowerCase().contains(q) ||
                e.purpose.toLowerCase().contains(q);
          }).toList();

    return Column(
      children: [
        // ── Top Control Bar ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              // Search Field
              SizedBox(
                width: 280,
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search patient or queue #...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
              const SizedBox(width: 16),

              // Department Segmented Filters
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ALL', label: Text('All Rooms')),
                  ButtonSegment(value: AppConstants.deptEnt, label: Text('Room 1 (ENT)')),
                  ButtonSegment(value: AppConstants.deptEyes, label: Text('Room 2 (EYES)')),
                ],
                selected: {_selectedDeptFilter},
                onSelectionChanged: (set) => setState(() => _selectedDeptFilter = set.first),
              ),

              const Spacer(),

              // Reset Daily Queue Button
              OutlinedButton.icon(
                onPressed: () => _confirmResetDailyQueue(context, queueProv),
                icon: const Icon(Icons.restart_alt_rounded, size: 18, color: AppColors.error),
                label: const Text(
                  'Reset Daily Queue',
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),

        // ── Room-by-Room Columns (Serving, Next, Others) ─────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedDeptFilter == 'ALL' || _selectedDeptFilter == AppConstants.deptEnt)
                  Expanded(
                    child: _buildRoomColumn(
                      context: context,
                      roomName: 'Room 1',
                      doctorName: AppConstants.departmentDoctors[AppConstants.deptEnt]!,
                      department: AppConstants.deptEnt,
                      queue: displayedQueue,
                      adminProv: adminProv,
                      queueProv: queueProv,
                      accentColor: AppColors.entPrimary,
                    ),
                  ),
                if (_selectedDeptFilter == 'ALL') const SizedBox(width: 18),
                if (_selectedDeptFilter == 'ALL' || _selectedDeptFilter == AppConstants.deptEyes)
                  Expanded(
                    child: _buildRoomColumn(
                      context: context,
                      roomName: 'Room 2',
                      doctorName: AppConstants.departmentDoctors[AppConstants.deptEyes]!,
                      department: AppConstants.deptEyes,
                      queue: displayedQueue,
                      adminProv: adminProv,
                      queueProv: queueProv,
                      accentColor: AppColors.eyesPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomColumn({
    required BuildContext context,
    required String roomName,
    required String doctorName,
    required String department,
    required List<QueueEntry> queue,
    required AdminProvider adminProv,
    required QueueProvider queueProv,
    required Color accentColor,
  }) {
    final servingEntry = adminProv.getDoctorServing(queue, doctorName, department);
    final nextEntry = adminProv.getDoctorNext(queue, doctorName, department);
    final othersWaiting = adminProv.getDoctorOtherWaiting(queue, doctorName, department);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Room Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: accentColor.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            roomName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              department,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        doctorName,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Queue counter badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(servingEntry != null ? 1 : 0) + (nextEntry != null ? 1 : 0) + othersWaiting.length} Total',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── 1. CURRENTLY SERVING ──────────────────────────────
                _buildSectionHeader('CURRENTLY SERVING', Icons.record_voice_over_rounded, AppColors.success),
                const SizedBox(height: 8),
                if (servingEntry != null)
                  _buildServingCard(servingEntry, queueProv)
                else
                  _buildEmptyStateBox('Doctor is currently available. No patient in room.'),

                const SizedBox(height: 20),

                // ── 2. WHO\'S NEXT ────────────────────────────────────
                _buildSectionHeader("WHO'S NEXT (NEXT IN LINE)", Icons.arrow_circle_right_rounded, const Color(0xFFF59E0B)),
                const SizedBox(height: 8),
                if (nextEntry != null)
                  _buildNextPatientCard(nextEntry, queueProv, doctorName)
                else
                  _buildEmptyStateBox('No patient waiting next in line.'),

                const SizedBox(height: 20),

                // ── 3. WHO ARE THE OTHERS (WAITING LIST) ──────────────
                _buildSectionHeader(
                  'WHO ARE THE OTHERS (${othersWaiting.length} WAITING)',
                  Icons.format_list_numbered_rounded,
                  Colors.blueGrey,
                ),
                const SizedBox(height: 8),
                if (othersWaiting.isNotEmpty)
                  ...othersWaiting.map((e) => _buildOtherPatientTile(e, queueProv, doctorName))
                else
                  _buildEmptyStateBox('No other patients waiting.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildServingCard(QueueEntry entry, QueueProvider queueProv) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.queueNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.fiber_manual_record, size: 10, color: AppColors.success),
                  SizedBox(width: 4),
                  Text(
                    'Inside Room',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.patientName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            'Purpose: ${entry.purpose}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _showReassignDialog(context, entry),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Reassign', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => queueProv.markComplete(entry.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextPatientCard(QueueEntry entry, QueueProvider queueProv, String doctorName) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.queueNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const Text(
                'Ready to Enter',
                style: TextStyle(
                  color: Color(0xFFD97706),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.patientName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            'Purpose: ${entry.purpose}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _showReassignDialog(context, entry),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Reassign', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final room = entry.department == AppConstants.deptEnt ? 'Room 1' : 'Room 2';
                  queueProv.reassignDoctorAndRoom(entry.id, doctor: doctorName, room: room);
                  queueProv.callNext(entry.department);
                },
                icon: const Icon(Icons.volume_up_rounded, size: 14),
                label: const Text('Call In', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherPatientTile(QueueEntry entry, QueueProvider queueProv, String doctorName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              entry.queueNumber,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.patientName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.purpose,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 18),
            onSelected: (action) {
              if (action == 'reassign') {
                _showReassignDialog(context, entry);
              } else if (action == 'skip') {
                queueProv.skipEntry(entry.id);
              } else if (action == 'hold') {
                queueProv.holdEntry(entry.id);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'reassign',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Reassign Doctor / Room', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'hold',
                child: Row(
                  children: [
                    Icon(Icons.pause_circle_outline_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Put on Hold', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'skip',
                child: Row(
                  children: [
                    Icon(Icons.skip_next_rounded, size: 16),
                    SizedBox(width: 8),
                    Text('Skip Patient', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReassignDialog(BuildContext context, QueueEntry entry) {
    String selectedDoctor = entry.assignedDoctor ?? AppConstants.departmentDoctors[AppConstants.deptEnt]!;
    String selectedRoom = entry.assignedRoom ?? 'Room 1';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Reassign ${entry.queueNumber} - ${entry.patientName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedDoctor,
                decoration: const InputDecoration(labelText: 'Assign to Doctor'),
                items: [
                  DropdownMenuItem(
                    value: AppConstants.departmentDoctors[AppConstants.deptEnt]!,
                    child: Text('Dr. Engr. Ranulfo Ramos (ENT)'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.departmentDoctors[AppConstants.deptEyes]!,
                    child: Text('Dr. Ranulfo Ramos Jr. (EYES)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedDoctor = val;
                      selectedRoom = val.contains('Junior') || val.contains('Jr.') ? 'Room 2' : 'Room 1';
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedRoom,
                decoration: const InputDecoration(labelText: 'Consultation Room'),
                items: const [
                  DropdownMenuItem(value: 'Room 1', child: Text('Room 1')),
                  DropdownMenuItem(value: 'Room 2', child: Text('Room 2')),
                  DropdownMenuItem(value: 'Room 3', child: Text('Room 3 (Procedure)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedRoom = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<QueueProvider>().reassignDoctorAndRoom(
                      entry.id,
                      doctor: selectedDoctor,
                      room: selectedRoom,
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reassigned ${entry.patientName} to $selectedDoctor ($selectedRoom)'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Save Reassignment'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetDailyQueue(BuildContext context, QueueProvider queueProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Reset Daily Queue?'),
          ],
        ),
        content: const Text(
          'This will reset the daily counter sequence for today back to 001. All existing records remain archived in visit history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              queueProv.resetDailyQueue();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Daily queue reset successfully! Next tickets start at 001.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Reset Queue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
