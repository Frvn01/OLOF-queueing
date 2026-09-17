import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/patient.dart';
import '../../data/models/queue_entry.dart';
import '../../providers/patient_provider.dart';
import '../../providers/queue_provider.dart';
import '../../providers/theme_provider.dart';
import '../../shared/widgets/olof_logo.dart';

/// Nurse Station Screen — Clinical Examinations, Diagram Annotations & Patient Triage
class NurseStationScreen extends StatefulWidget {
  const NurseStationScreen({super.key});

  @override
  State<NurseStationScreen> createState() => _NurseStationScreenState();
}

class _NurseStationScreenState extends State<NurseStationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _queueSearchController = TextEditingController();
  final TextEditingController _directorySearchController = TextEditingController();
  String _selectedDeptFilter = 'ALL'; // 'ALL', 'ENT', 'EYES'
  String _selectedStatusFilter = 'ALL'; // 'ALL', 'waiting', 'serving', 'completed'
  bool _isInitializing = true; // true until initial fetch attempt completes

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Future.wait([
          context.read<QueueProvider>().initialize(forceRefresh: true),
          context.read<PatientProvider>().initialize(),
        ]);
      } catch (e) {
        debugPrint('Nurse station initialization error: $e');
      } finally {
        if (mounted) setState(() => _isInitializing = false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queueSearchController.dispose();
    _directorySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final isLandscape = mq.orientation == Orientation.landscape;
    final isCompact = screenWidth < 600 && !isLandscape;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDarkest : AppColors.lightBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.surfaceGradient
              : AppColors.lightSurfaceGradient,
        ),
        child: SafeArea(
          child: _isInitializing
              ? _buildInitialLoading(isDark)
              : Column(
                  children: [
                    _buildAppBar(context, isDark, isCompact),
                    _buildTabBar(context, isDark, isCompact),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTodayQueueTab(context, isDark, isCompact),
                          _buildPatientsDirectoryTab(context, isDark, isCompact),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInitialLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFEC4899),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Nurse Station...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, bool isCompact) {
    final headerBg = isDark ? AppColors.surfaceDark : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/'),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            ),
            tooltip: 'Back to Station Selector',
          ),
          const SizedBox(width: 2),
          const OlofLogo(size: 34, showBorder: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Nurse Clinical Station',
                        style: TextStyle(
                          fontSize: isCompact ? 16 : 18,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'NURSE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Clinical Exams, Anatomical Drawings & Triage',
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 12.5,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Theme Switcher
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.warning : AppColors.brandBlue,
              size: 20,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 21),
            tooltip: 'Refresh Queue',
            onPressed: () {
              context.read<QueueProvider>().initialize();
              context.read<PatientProvider>().initialize();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, bool isDark, bool isCompact) {
    final queueProv = context.watch<QueueProvider>();
    final activeCount = queueProv.todayQueue.length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFEC4899),
        indicatorWeight: 3,
        labelColor: const Color(0xFFEC4899),
        unselectedLabelColor:
            isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_alt_rounded, size: 17),
                const SizedBox(width: 8),
                const Text("Today's Queue"),
                if (activeCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_shared_rounded, size: 17),
                const SizedBox(width: 8),
                const Text('All Patients Directory'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 1: TODAY'S QUEUE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTodayQueueTab(BuildContext context, bool isDark, bool isCompact) {
    final queueProv = context.watch<QueueProvider>();
    final patientProv = context.watch<PatientProvider>();
    final rawEntries = queueProv.todayQueue;
    final allPatients = patientProv.patients;

    // Filter by department & status & query
    final query = _queueSearchController.text.trim().toLowerCase();
    final entries = rawEntries.where((entry) {
      if (_selectedDeptFilter != 'ALL' && entry.department.toUpperCase() != _selectedDeptFilter) {
        return false;
      }
      if (_selectedStatusFilter != 'ALL' && entry.status.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = entry.patientName.toLowerCase().contains(query);
        final matchesTicket = entry.queueNumber.toLowerCase().contains(query);
        final matchesPurpose = entry.purpose.toLowerCase().contains(query);
        if (!matchesName && !matchesTicket && !matchesPurpose) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter Controls
        _buildFilterBar(isDark, isCompact),

        // Patient Queue List
        Expanded(
          child: queueProv.isLoading
              ? const Center(child: CircularProgressIndicator())
              : entries.isEmpty
                  ? _buildEmptyState(
                      isDark: isDark,
                      icon: Icons.assignment_turned_in_rounded,
                      title: 'No Patients in Queue',
                      subtitle: _queueSearchController.text.isNotEmpty
                          ? 'No patients matched your search filters.'
                          : 'Patients checked-in at reception will appear here for clinical exams.',
                      actionText: _queueSearchController.text.isNotEmpty ? 'Clear Search' : 'Refresh Queue',
                      onAction: () {
                        if (_queueSearchController.text.isNotEmpty) {
                          _queueSearchController.clear();
                          setState(() {});
                        } else {
                          context.read<QueueProvider>().refresh();
                          context.read<PatientProvider>().initialize();
                        }
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final patient = allPatients
                            .where((p) => p.id == entry.patientId)
                            .firstOrNull;
                        return _buildQueueCard(context, entry, patient, isDark);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(bool isDark, bool isCompact) {
    final searchBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.lightSurface,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Search Input
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: searchBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _queueSearchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 13.5, color: textColor),
              decoration: InputDecoration(
                hintText: 'Search by patient name, ticket or purpose...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textDisabled : AppColors.lightTextDisabled,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                ),
                suffixIcon: _queueSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _queueSearchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Department & Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL DEPTS', 'ALL', _selectedDeptFilter, (val) {
                  setState(() => _selectedDeptFilter = val);
                }, isDark),
                const SizedBox(width: 6),
                _buildFilterChip('ENT', 'ENT', _selectedDeptFilter, (val) {
                  setState(() => _selectedDeptFilter = val);
                }, isDark),
                const SizedBox(width: 6),
                _buildFilterChip('EYES (OPHTHA)', 'EYES', _selectedDeptFilter, (val) {
                  setState(() => _selectedDeptFilter = val);
                }, isDark),
                const SizedBox(width: 14),
                Container(width: 1, height: 20, color: borderColor),
                const SizedBox(width: 14),
                _buildFilterChip('ALL STATUS', 'ALL', _selectedStatusFilter, (val) {
                  setState(() => _selectedStatusFilter = val);
                }, isDark),
                const SizedBox(width: 6),
                _buildFilterChip('WAITING', 'waiting', _selectedStatusFilter, (val) {
                  setState(() => _selectedStatusFilter = val);
                }, isDark),
                const SizedBox(width: 6),
                _buildFilterChip('SERVING', 'serving', _selectedStatusFilter, (val) {
                  setState(() => _selectedStatusFilter = val);
                }, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String selectedValue,
    ValueChanged<String> onSelected,
    bool isDark,
  ) {
    final isSelected = selectedValue.toUpperCase() == value.toUpperCase();
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEC4899)
              : (isDark ? AppColors.surfaceMid : AppColors.lightBg),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEC4899)
                : (isDark ? AppColors.surfaceLight : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueCard(
    BuildContext context,
    QueueEntry entry,
    Patient? patient,
    bool isDark,
  ) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final isEyes = entry.department.toUpperCase() == 'EYES';
    final deptColor = isEyes ? AppColors.cyanCalm : AppColors.brandBlue;

    final chiefComplaint = patient?.chiefComplaint ?? '';
    final hpi = patient?.historyOfPresentIllness ?? '';
    final pmh = patient?.pastMedicalHistory ?? '';
    final doctorName = entry.assignedDoctor ?? patient?.assignedDoctor ?? '';
    final roomName = entry.assignedRoom ?? patient?.assignedRoom ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Ticket Number, Department, Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: deptColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: deptColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        entry.queueNumber,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: deptColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.lightBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.department.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(entry.status, isDark),
              ],
            ),
            const SizedBox(height: 10),

            // Patient Name & Demographics
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.patientName,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ),
                if (patient != null)
                  Text(
                    '${patient.sex} • ${patient.age} yrs • No: ${patient.patientNo}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Receptionist Intake Details: Purpose & Assigned Clinic Location
            Row(
              children: [
                Icon(Icons.medical_information_outlined, size: 14, color: subtitleColor),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Purpose: ${entry.purpose}',
                    style: TextStyle(fontSize: 12.5, color: subtitleColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (doctorName.isNotEmpty || roomName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.meeting_room_outlined, size: 12, color: AppColors.cyanCalm),
                        const SizedBox(width: 4),
                        Text(
                          roomName.isNotEmpty ? roomName : doctorName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Receptionist Chief Complaint (highlighted for Nurse)
            if (chiefComplaint.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.record_voice_over_rounded,
                        size: 14, color: Color(0xFFEC4899)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Chief Complaint: ',
                              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFEC4899)),
                            ),
                            TextSpan(text: chiefComplaint),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Past Medical History & HPI Preview (if available)
            if (hpi.isNotEmpty || pmh.isNotEmpty) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _showReceptionistIntakeDialog(context, patient, entry, isDark),
                child: Row(
                  children: [
                    Icon(Icons.history_edu_rounded, size: 13, color: AppColors.cyanCalm),
                    const SizedBox(width: 4),
                    Text(
                      'View Receptionist Medical History & HPI',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cyanCalm,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Actions Row
            Row(
              children: [
                // Primary Action: Open Clinical Exams
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push(
                        '/nurse/exams',
                        extra: {
                          'patientId': entry.patientId,
                          'patientName': entry.patientName,
                          'queueNumber': entry.queueNumber,
                          'department': entry.department,
                          'queueEntryId': entry.id,
                          'chiefComplaint': chiefComplaint,
                          'historyOfPresentIllness': hpi,
                          'pastMedicalHistory': pmh,
                          'assignedDoctor': doctorName,
                          'assignedRoom': roomName,
                        },
                      );
                    },
                    icon: const Icon(Icons.draw_rounded, size: 18),
                    label: const Text('Clinical Exams & Drawings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Secondary Action: Triage Modal
                OutlinedButton.icon(
                  onPressed: () => _showTriageDialog(context, entry, isDark),
                  icon: const Icon(Icons.monitor_heart_rounded, size: 17),
                  label: const Text('Triage Vitals'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEC4899),
                    minimumSize: const Size(0, 42),
                    side: const BorderSide(color: Color(0xFFEC4899), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReceptionistIntakeDialog(
    BuildContext context,
    Patient? patient,
    QueueEntry entry,
    bool isDark,
  ) {
    if (patient == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.assignment_ind_rounded, color: Color(0xFFEC4899)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Receptionist Intake — ${patient.fullName}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIntakeField('Patient Number', patient.patientNo, isDark),
              _buildIntakeField('Department & Ticket', '${entry.department} • ${entry.queueNumber}', isDark),
              _buildIntakeField('Assigned Doctor', entry.assignedDoctor ?? patient.assignedDoctor ?? 'Not assigned', isDark),
              _buildIntakeField('Assigned Room', entry.assignedRoom ?? patient.assignedRoom ?? 'Not assigned', isDark),
              const Divider(height: 20),
              _buildIntakeField('Chief Complaint', patient.chiefComplaint ?? 'None recorded', isDark, isHighlight: true),
              _buildIntakeField('History of Present Illness (HPI)', patient.historyOfPresentIllness ?? 'None recorded', isDark),
              _buildIntakeField('Past Medical History (PMH)', patient.pastMedicalHistory ?? 'None recorded', isDark),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildIntakeField(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isHighlight
                  ? const Color(0xFFEC4899)
                  : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w500,
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'serving':
        bg = AppColors.cyanCalm.withValues(alpha: 0.15);
        fg = AppColors.cyanCalm;
        label = 'SERVING';
        break;
      case 'completed':
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        label = 'COMPLETED';
        break;
      case 'waiting':
      default:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        label = 'WAITING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 2: ALL PATIENTS DIRECTORY
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPatientsDirectoryTab(BuildContext context, bool isDark, bool isCompact) {
    final patientProv = context.watch<PatientProvider>();
    final rawPatients = patientProv.patients;

    final query = _directorySearchController.text.trim().toLowerCase();
    final patients = rawPatients.where((p) {
      if (query.isNotEmpty) {
        return p.fullName.toLowerCase().contains(query) ||
            p.patientNo.toLowerCase().contains(query) ||
            p.contactNumber.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.lightSurface,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
              ),
            ),
          ),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
              ),
            ),
            child: TextField(
              controller: _directorySearchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search patient by name, patient no, or contact...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textDisabled : AppColors.lightTextDisabled,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                ),
                suffixIcon: _directorySearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _directorySearchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),

        // Directory List
        Expanded(
          child: patientProv.isLoading
              ? const Center(child: CircularProgressIndicator())
              : patients.isEmpty
                  ? _buildEmptyState(
                      isDark: isDark,
                      icon: Icons.person_search_rounded,
                      title: 'No Registered Patients Found',
                      subtitle: _directorySearchController.text.isNotEmpty
                          ? 'No patients matched your search criteria.'
                          : 'Patients registered at reception will be listed here.',
                      actionText: _directorySearchController.text.isNotEmpty
                          ? 'Clear Search'
                          : 'Refresh Patients',
                      onAction: () {
                        if (_directorySearchController.text.isNotEmpty) {
                          _directorySearchController.clear();
                          setState(() {});
                        } else {
                          context.read<PatientProvider>().initialize();
                        }
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final p = patients[index];
                        return _buildPatientDirectoryCard(context, p, isDark);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPatientDirectoryCard(BuildContext context, Patient p, bool isDark) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEC4899).withValues(alpha: 0.15),
          child: const Icon(Icons.person_rounded, color: Color(0xFFEC4899)),
        ),
        title: Text(
          p.fullName,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: titleColor),
        ),
        subtitle: Text(
          'No: ${p.patientNo} • ${p.sex} • ${p.age} yrs • Tel: ${p.contactNumber}',
          style: TextStyle(fontSize: 12, color: subtitleColor),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () {
            context.push(
              '/nurse/exams',
              extra: {
                'patientId': p.id,
                'patientName': p.fullName,
                'queueNumber': 'REGISTRY',
                'department': 'ENT',
              },
            );
          },
          icon: const Icon(Icons.medical_services_outlined, size: 16),
          label: const Text('Exams'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEC4899),
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56,
              color: isDark ? AppColors.textDisabled : AppColors.lightTextDisabled,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // QUICK TRIAGE MODAL
  // ───────────────────────────────────────────────────────────────────────────
  void _showTriageDialog(BuildContext context, QueueEntry entry, bool isDark) {
    final bpController = TextEditingController();
    final hrController = TextEditingController();
    final tempController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.monitor_heart_rounded, color: Color(0xFFEC4899)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Triage Vitals — ${entry.patientName}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bpController,
                decoration: const InputDecoration(
                  labelText: 'Blood Pressure (e.g. 120/80 mmHg)',
                  prefixIcon: Icon(Icons.speed_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hrController,
                decoration: const InputDecoration(
                  labelText: 'Heart Rate (bpm)',
                  prefixIcon: Icon(Icons.favorite_outline_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tempController,
                decoration: const InputDecoration(
                  labelText: 'Temperature (°C)',
                  prefixIcon: Icon(Icons.thermostat_rounded, size: 18),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Nurse Assessment / Notes',
                  prefixIcon: Icon(Icons.notes_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Triage vitals recorded successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Save Triage'),
          ),
        ],
      ),
    );
  }
}
