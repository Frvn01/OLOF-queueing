import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/patient.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/queue_provider.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  String _searchQuery = '';
  String _filterChip = 'all'; // 'all', 'assigned', 'first_time', 'today_queue'
  bool _isGridView = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().loadPatients();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorProv = context.watch<DoctorProvider>();
    final queueProv = context.watch<QueueProvider>();
    final allPatients = doctorProv.patients;
    final todayQueue = queueProv.todayQueue;

    const themeColor = AppColors.doctorPrimary;

    // Apply filter & search
    final filtered = allPatients.where((p) {
      // 1. Filter Chip
      if (_filterChip == 'assigned') {
        if (p.assignedDoctor != null && p.assignedDoctor!.isNotEmpty) {
          if (p.assignedDoctor != doctorProv.activeDoctor) return false;
        }
      } else if (_filterChip == 'first_time') {
        if (!p.isFirstTime) return false;
      } else if (_filterChip == 'today_queue') {
        final inQueue = todayQueue.any((q) => q.patientId == p.id);
        if (!inQueue) return false;
      }

      // 2. Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = p.fullName.toLowerCase();
        final no = p.patientNo.toLowerCase();
        final phone = p.contactNumber.toLowerCase();
        final complaint = (p.chiefComplaint ?? '').toLowerCase();
        if (!name.contains(q) && !no.contains(q) && !phone.contains(q) && !complaint.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.people_alt_rounded, size: 22),
            const SizedBox(width: 8),
            Text(
              'Patients Directory (${allPatients.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          // Grid / List toggle
          IconButton(
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            tooltip: 'Refresh Patients from Reception',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              doctorProv.loadPatients(forceRefresh: true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing patient database...')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Controls ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search patients by name, PT-#, phone, or symptom...',
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
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Patients (${allPatients.length})', themeColor),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'assigned',
                        'Assigned to Me (${doctorProv.getAssignedPatients().length})',
                        themeColor,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'first_time',
                        'First-Time Patients (${allPatients.where((p) => p.isFirstTime).length})',
                        themeColor,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'today_queue',
                        'In Today\'s Queue (${todayQueue.length})',
                        themeColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Patient Cards (Grid or List) ──────────────────────────
          Expanded(
            child: doctorProv.isLoadingPatients
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No patients found matching "$_searchQuery"'
                                  : 'No patients found in this category',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => doctorProv.loadPatients(forceRefresh: true),
                              icon: const Icon(Icons.sync_rounded),
                              label: const Text('Check for reception uploads'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => doctorProv.loadPatients(forceRefresh: true),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 700;
                            final crossAxisCount = constraints.maxWidth >= 1000
                                ? 3
                                : (isWide ? 2 : 1);

                            if (_isGridView && isWide) {
                              return GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  mainAxisExtent: 215,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) => _buildPatientCard(
                                  context,
                                  filtered[i],
                                  themeColor,
                                  todayQueue,
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildPatientCard(
                                  context,
                                  filtered[i],
                                  themeColor,
                                  todayQueue,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color themeColor) {
    final isSelected = _filterChip == key;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : null,
      ),
      selectedColor: themeColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _filterChip = key),
    );
  }

  Widget _buildPatientCard(
    BuildContext context,
    Patient patient,
    Color themeColor,
    List todayQueue,
  ) {
    final inQueue = todayQueue.any((q) => q.patientId == patient.id);
    final initials = (patient.firstName.isNotEmpty ? patient.firstName[0] : '') +
        (patient.lastName.isNotEmpty ? patient.lastName[0] : '');

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: inQueue ? themeColor.withValues(alpha: 0.4) : Theme.of(context).dividerColor.withValues(alpha: 0.15),
          width: inQueue ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Name, Queue / First time tag
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: themeColor.withValues(alpha: 0.15),
                  child: Text(
                    initials.toUpperCase(),
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            patient.patientNo,
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${patient.age} yrs • ${patient.sex}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (inQueue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'IN QUEUE',
                      style: TextStyle(
                        color: themeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (patient.isFirstTime)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Chief complaint / reason
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      patient.chiefComplaint?.isNotEmpty == true
                          ? patient.chiefComplaint!
                          : 'General Checkup & Consultation',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.room_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      patient.assignedRoom ?? 'Room 1',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        context.push('/doctor/patients/${patient.id}');
                      },
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('View Record', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        context.push('/doctor/consultation/${patient.id}');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: themeColor,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Consult', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
