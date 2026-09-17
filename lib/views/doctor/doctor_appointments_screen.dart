import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/queue_provider.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _statusFilters = [
    'All',
    'Scheduled',
    'Confirmed',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorProv = context.watch<DoctorProvider>();
    final queueProv = context.watch<QueueProvider>();
    final allQueue = queueProv.todayQueue;

    const themeColor = AppColors.doctorPrimary;

    // Derive appointments from queue entries and assigned patients
    final appointments = _deriveAppointments(doctorProv, allQueue);

    // Filter by status & search
    final filtered = appointments.where((apt) {
      if (_selectedStatus != 'All' &&
          apt['status'].toString().toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = apt['patientName'].toString().toLowerCase();
        final phone = apt['phone'].toString().toLowerCase();
        final reason = apt['reason'].toString().toLowerCase();
        if (!name.contains(q) && !phone.contains(q) && !reason.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.handshake_rounded, size: 22),
            const SizedBox(width: 8),
            Text(
              'My Appointments • ${doctorProv.formattedDoctorName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Appointments',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              doctorProv.loadPatients(forceRefresh: true);
              queueProv.initialize(forceRefresh: true);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Controls ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search appointment by patient name, phone, or complaint...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((st) {
                      final isSelected = _selectedStatus == st;
                      final count = st == 'All'
                          ? appointments.length
                          : appointments
                              .where((a) => a['status'].toString().toLowerCase() == st.toLowerCase())
                              .length;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          showCheckmark: false,
                          label: Text('$st ($count)'),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : null,
                          ),
                          selectedColor: themeColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (_) => setState(() => _selectedStatus = st),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Appointments List ─────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No appointments matching "$_searchQuery"'
                              : 'No appointments in this category',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final apt = filtered[i];
                      final status = apt['status'].toString().toLowerCase();
                      final badgeColor = _getStatusBadgeColor(status);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Time Slot Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.access_time_filled_rounded, color: themeColor, size: 20),
                                    const SizedBox(height: 4),
                                    Text(
                                      apt['time'].toString(),
                                      style: TextStyle(
                                        color: themeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      apt['date'].toString(),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Patient Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          apt['patientName'].toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            apt['status'].toString().toUpperCase(),
                                            style: TextStyle(
                                              color: badgeColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Reason: ${apt['reason']}',
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.phone_rounded, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          apt['phone'].toString(),
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.room_rounded, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          apt['room'].toString(),
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Actions
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: () {
                                      final patientId = apt['patientId']?.toString();
                                      if (patientId != null && patientId.isNotEmpty) {
                                        context.push('/doctor/patients/$patientId');
                                      }
                                    },
                                    icon: const Icon(Icons.visibility_rounded, size: 16),
                                    label: const Text('View Record'),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      final patientId = apt['patientId']?.toString();
                                      if (patientId != null && patientId.isNotEmpty) {
                                        context.push('/doctor/consultation/$patientId');
                                      }
                                    },
                                    icon: const Icon(Icons.medical_services_rounded, size: 16),
                                    label: const Text('Consult'),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBadgeColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'completed':
        return AppColors.success;
      case 'in progress':
      case 'serving':
        return AppColors.doctorPrimary;
      case 'scheduled':
        return const Color(0xFF0D9488);
      case 'cancelled':
        return AppColors.error;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  /// Combine live queue records and registered patients into appointment list
  List<Map<String, dynamic>> _deriveAppointments(
    DoctorProvider doctorProv,
    List dynamicQueue,
  ) {
    final list = <Map<String, dynamic>>[];

    // 1. From active Queue
    final myQueue = doctorProv.filterAssignedQueue(doctorProv.filterAssignedQueue([]).isEmpty
        ? doctorProv.filterAssignedQueue(dynamicQueue.cast())
        : dynamicQueue.cast());

    for (final q in myQueue) {
      String status = 'Scheduled';
      if (q.isServing) status = 'In Progress';
      if (q.isCompleted) status = 'Completed';
      if (q.isWaiting) status = 'Confirmed';

      final timeStr = q.calledAt != null
          ? '${q.calledAt!.hour}:${q.calledAt!.minute.toString().padLeft(2, '0')}'
          : 'Today';

      list.add({
        'id': q.id,
        'patientId': q.patientId,
        'patientName': q.patientName,
        'phone': 'Patient #${q.queueNumber}',
        'reason': q.purpose.isNotEmpty ? q.purpose : 'Consultation',
        'room': q.assignedRoom ?? doctorProv.activeRoom,
        'status': status,
        'time': timeStr,
        'date': 'Today',
      });
    }

    // 2. From assigned patients (if not already in queue list)
    for (final p in doctorProv.patients) {
      if (list.any((a) => a['patientId'] == p.id)) continue;
      if (p.assignedDoctor != null && p.assignedDoctor == doctorProv.activeDoctor) {
        list.add({
          'id': p.id,
          'patientId': p.id,
          'patientName': p.fullName,
          'phone': p.contactNumber.isNotEmpty ? p.contactNumber : 'No contact',
          'reason': p.chiefComplaint ?? 'Scheduled Consultation',
          'room': p.assignedRoom ?? doctorProv.activeRoom,
          'status': 'Scheduled',
          'time': 'Scheduled',
          'date': '${p.createdAt.month}/${p.createdAt.day}',
        });
      }
    }

    return list;
  }
}
