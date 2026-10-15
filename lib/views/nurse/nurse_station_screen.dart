import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/models/patient.dart';
import '../../data/models/patient_dept_record.dart';
import '../../data/models/queue_entry.dart';
import '../../data/models/vital_signs.dart';
import '../../data/repositories/patient_dept_repository.dart';
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
                  'Patient Vital Signs & Triage Intake',
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
    final activeCount = queueProv.todayQueue.where((e) => !e.hasVitals && !e.isCompleted).length;

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
    final activeTriagePatients = rawEntries.where((e) => e.isTriage && !e.hasVitals).toList();

    // Filter by department & status & query — patients with complete vitals disappear from nurse intake queue
    final query = _queueSearchController.text.trim().toLowerCase();
    final entries = rawEntries.where((entry) {
      if (entry.hasVitals) return false;
      if (entry.isCompleted) return false;

      if (_selectedDeptFilter != 'ALL' && entry.department.toUpperCase() != _selectedDeptFilter) {
        return false;
      }
      if (_selectedStatusFilter != 'ALL') {
        if (_selectedStatusFilter.toLowerCase() == 'waiting') {
          // If WAITING is selected, include both waiting and 1st call active (triage)
          if (!entry.isWaiting && !entry.isTriage) return false;
        } else if (_selectedStatusFilter.toLowerCase() == 'triage') {
          if (!entry.isTriage) return false;
        } else if (entry.status.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        final matchesName = entry.patientName.toLowerCase().contains(query);
        final matchesTicket = entry.queueNumber.toLowerCase().contains(query);
        final matchesPurpose = entry.purpose.toLowerCase().contains(query);
        if (!matchesName && !matchesTicket && !matchesPurpose) return false;
      }
      return true;
    }).toList();

    // Sort patients called for 1st Call (triage) to the top of the queue!
    entries.sort((a, b) {
      if (a.isTriage && !b.isTriage) return -1;
      if (!a.isTriage && b.isTriage) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });

    return Column(
      children: [
        // Filter Controls
        _buildFilterBar(isDark, isCompact, rawEntries),

        // Prominent 1st Call Active Banner if patients are called to Nurse Station
        if (activeTriagePatients.isNotEmpty)
          _buildActiveTriageBanner(context, activeTriagePatients, allPatients, isDark),

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
                          : 'Patients checked-in at reception will appear here for vital signs triage intake.',
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

  Widget _buildActiveTriageBanner(
    BuildContext context,
    List<QueueEntry> triagePatients,
    List<Patient> allPatients,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEC4899), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_rounded, color: Color(0xFFEC4899), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '1ST CALL ACTIVE — ${triagePatients.length} PATIENT${triagePatients.length > 1 ? 'S' : ''} AT NURSE STATION',
                  style: const TextStyle(
                    color: Color(0xFFEC4899),
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...triagePatients.map((entry) {
            final patient = allPatients.where((p) => p.id == entry.patientId).firstOrNull;
            return Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceMid : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.queueNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.patientName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${entry.department} • ${entry.purpose}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showTriageDialog(context, entry, patient, isDark),
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: const Text('Record Vitals'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark, bool isCompact, List<QueueEntry> rawEntries) {
    final searchBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final triageCount = rawEntries.where((e) => e.isTriage && !e.hasVitals).length;

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
                _buildFilterChip(
                  triageCount > 0 ? '1ST CALL / VITALS ($triageCount)' : '1ST CALL (VITALS)',
                  'triage',
                  _selectedStatusFilter,
                  (val) {
                    setState(() => _selectedStatusFilter = val);
                  },
                  isDark,
                  activeColor: const Color(0xFFEC4899),
                ),
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
    bool isDark, {
    Color? activeColor,
  }) {
    final chipColor = activeColor ?? const Color(0xFFEC4899);
    final isSelected = selectedValue.toUpperCase() == value.toUpperCase();
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor
              : (isDark ? AppColors.surfaceMid : AppColors.lightBg),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? chipColor
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
                AppImageHelper.buildAvatar(
                  photoUrl: entry.patientPhoto ?? patient?.photoUrl,
                  name: entry.patientName,
                  radius: 18,
                  backgroundColor: deptColor.withValues(alpha: 0.15),
                  foregroundColor: deptColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.patientName,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
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

            // Recorded Vitals Preview or Pending Badge
            Builder(
              builder: (context) {
                final vitals = entry.vitalSigns ?? patient?.vitalSigns;
                final hasVitals = vitals != null && vitals.isNotEmpty;
                if (hasVitals) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 5),
                            const Text(
                              'TRIAGE VITALS RECORDED',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (vitals.hasEyeVitals) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.cyanCalm.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'EYE VITALS INCL.',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.cyanCalm,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (vitals.bloodPressure != null && vitals.bloodPressure!.isNotEmpty)
                              _buildVitalChip('BP', vitals.bloodPressure!, isDark),
                            if (vitals.temperature != null)
                              _buildVitalChip('Temp', '${vitals.temperature}°C', isDark),
                            if (vitals.heartRate != null)
                              _buildVitalChip('HR', '${vitals.heartRate} bpm', isDark),
                            if (vitals.oxygenSaturation != null)
                              _buildVitalChip('SpO2', '${vitals.oxygenSaturation}%', isDark),
                            if (vitals.weight != null)
                              _buildVitalChip('Wt', '${vitals.weight} kg', isDark),
                            if ((vitals.visualAcuityOD != null && vitals.visualAcuityOD!.isNotEmpty) ||
                                (vitals.visualAcuityOS != null && vitals.visualAcuityOS!.isNotEmpty))
                              _buildVitalChip('VA', 'OD: ${vitals.visualAcuityOD ?? "-"} | OS: ${vitals.visualAcuityOS ?? "-"}', isDark),
                            if ((vitals.intraocularPressureOD != null && vitals.intraocularPressureOD!.isNotEmpty) ||
                                (vitals.intraocularPressureOS != null && vitals.intraocularPressureOS!.isNotEmpty))
                              _buildVitalChip('IOP', 'OD: ${vitals.intraocularPressureOD ?? "-"} | OS: ${vitals.intraocularPressureOS ?? "-"} mmHg', isDark),
                            if ((vitals.funduscopyOD != null && vitals.funduscopyOD!.isNotEmpty) ||
                                (vitals.funduscopyOS != null && vitals.funduscopyOS!.isNotEmpty))
                              _buildVitalChip('Fundus', 'OD: ${vitals.funduscopyOD ?? "-"} | OS: ${vitals.funduscopyOS ?? "-"}', isDark),
                          ],
                        ),
                      ],
                    ),
                  );
                } else if (entry.isTriage) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEC4899), width: 1.5),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.record_voice_over_rounded, size: 14, color: Color(0xFFEC4899)),
                        SizedBox(width: 6),
                        Text(
                          '1st Call Active: Patient called to Nurse Station',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEC4899),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFF59E0B)),
                        SizedBox(width: 6),
                        Text(
                          'Vital signs pending nurse intake',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 12),

            // Actions Row — 1st Call (Vital Signs) & Intake Recording
            Builder(
              builder: (context) {
                final vitals = entry.vitalSigns ?? patient?.vitalSigns;
                final hasVitals = vitals != null && vitals.isNotEmpty;
                final isTriageCalled = entry.isTriage;

                if (hasVitals) {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showTriageDialog(context, entry, patient, isDark),
                          icon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF10B981)),
                          label: const Text('Update Vital Signs'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Vital signs pending — Nurse records vitals (calling is handled by Clinic Coordinator)
                return Row(
                  children: [
                    if (isTriageCalled) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEC4899), width: 1.2),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monitor_heart_rounded, size: 16, color: Color(0xFFEC4899)),
                            SizedBox(width: 6),
                            Text(
                              'CALLED BY COORDINATOR',
                              style: TextStyle(
                                color: Color(0xFFEC4899),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showTriageDialog(context, entry, patient, isDark),
                        icon: const Icon(Icons.monitor_heart_rounded, size: 18),
                        label: Text(isTriageCalled ? 'Record Vital Signs' : 'Record Vital Signs (Direct / Walk-In)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTriageCalled ? const Color(0xFFEC4899) : const Color(0xFF10B981),
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
                  ],
                );
              },
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
        content: FutureBuilder<PatientDeptRecord?>(
          future: PatientDeptRepository().getRecord(patient.id, entry.department),
          builder: (ctx, snapshot) {
            final deptRecord = snapshot.data;
            final complaint = deptRecord?.chiefComplaint ?? patient.chiefComplaint ?? 'None recorded';
            final hpi = deptRecord?.historyOfPresentIllness ?? patient.historyOfPresentIllness ?? 'None recorded';
            final pmhConditions = (deptRecord != null && deptRecord.effectiveConditions.isNotEmpty)
                ? deptRecord.effectiveConditions
                : patient.pmhConditionsList;
            final fallbackPmh = deptRecord?.pastMedicalHistory ?? patient.pastMedicalHistory ?? 'None recorded';

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIntakeField('Patient Number', patient.patientNo, isDark),
                  _buildIntakeField('Department & Ticket', '${entry.department} • ${entry.queueNumber}', isDark),
                  _buildIntakeField('Assigned Doctor', entry.assignedDoctor ?? patient.assignedDoctor ?? 'Not assigned', isDark),
                  _buildIntakeField('Assigned Room', entry.assignedRoom ?? patient.assignedRoom ?? 'Not assigned', isDark),
                  const Divider(height: 20),
                  _buildIntakeField('Chief Complaint', complaint, isDark, isHighlight: true),
                  _buildIntakeField('History of Present Illness (HPI)', hpi, isDark),
                  if (pmhConditions.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Past Medical History & Medications',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: pmhConditions.map((cond) {
                        final meds = cond.medications.isNotEmpty ? ' (${cond.medications.join(", ")})' : '';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${cond.condition}$meds',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
                    _buildIntakeField('Past Medical History (PMH)', fallbackPmh, isDark),
                  ],
                ],
              ),
            );
          },
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
        leading: AppImageHelper.buildAvatar(
          photoUrl: p.photoUrl,
          name: p.fullName,
          radius: 20,
          backgroundColor: const Color(0xFFEC4899).withValues(alpha: 0.15),
          foregroundColor: const Color(0xFFEC4899),
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
          onPressed: () => _showTriageDialog(context, null, p, isDark),
          icon: const Icon(Icons.monitor_heart_rounded, size: 16),
          label: Text(p.vitalSigns != null && p.vitalSigns!.isNotEmpty ? 'Edit Vitals' : 'Record Vitals'),
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

  Widget _buildVitalChip(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFEC4899)),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // COMPREHENSIVE TRIAGE & VITAL SIGNS MODAL (GENERAL + OPHTHALMIC)
  // ───────────────────────────────────────────────────────────────────────────
  void _showTriageDialog(
    BuildContext context,
    QueueEntry? entry,
    Patient? patient,
    bool isDark,
  ) {
    final patientName = entry?.patientName ?? patient?.fullName ?? 'Patient';
    final dept = entry?.department ?? 'GENERAL';
    final ticket = entry?.queueNumber ?? (patient?.patientNo ?? 'REGISTRY');
    final isEyes = dept.toUpperCase() == 'EYES';
    final isEnt = dept.toUpperCase() == 'ENT';

    final existing = entry?.vitalSigns ?? patient?.vitalSigns;

    // Standard Vitals Controllers
    final bpController = TextEditingController(text: existing?.bloodPressure ?? '');
    final hrController = TextEditingController(text: existing?.heartRate?.toString() ?? '');
    final tempController = TextEditingController(text: existing?.temperature?.toString() ?? '');
    final rrController = TextEditingController(text: existing?.respiratoryRate?.toString() ?? '');
    final spo2Controller = TextEditingController(text: existing?.oxygenSaturation?.toString() ?? '');
    final wtController = TextEditingController(text: existing?.weight?.toString() ?? '');
    final htController = TextEditingController(text: existing?.height?.toString() ?? '');

    // Eye Vitals Controllers
    final vaODController = TextEditingController(text: existing?.visualAcuityOD ?? '');
    final vaOSController = TextEditingController(text: existing?.visualAcuityOS ?? '');
    final iopODController = TextEditingController(text: existing?.intraocularPressureOD ?? '');
    final iopOSController = TextEditingController(text: existing?.intraocularPressureOS ?? '');
    final funduscopyODController = TextEditingController(text: existing?.funduscopyOD ?? '');
    final funduscopyOSController = TextEditingController(text: existing?.funduscopyOS ?? '');
    final eommController = TextEditingController(text: existing?.extraocularMuscleMovement ?? '');

    final notesController = TextEditingController(text: existing?.notes ?? '');

    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dialogBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
          final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
          final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
          final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFFEC4899), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Triage Intake — $patientName',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isEyes
                                  ? AppColors.cyanCalm.withValues(alpha: 0.18)
                                  : isEnt
                                      ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                      : AppColors.brandBlue.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              dept.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isEyes
                                    ? AppColors.cyanCalm
                                    : isEnt
                                        ? const Color(0xFF10B981)
                                        : AppColors.brandBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Ticket: $ticket • Exclusive Nurse Vital Signs Assessment',
                        style: TextStyle(fontSize: 11.5, color: subtitleColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(ctx).size.width < 720
                  ? (MediaQuery.of(ctx).size.width * 0.92).clamp(280.0, 680.0)
                  : 680.0,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEnt) ...[
                      // ── ENT DEPARTMENT VITAL SIGNS (BP, PR, TEMP, O2SAT, WT, Height) ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.10 : 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.hearing_rounded, size: 18, color: Color(0xFF10B981)),
                                const SizedBox(width: 8),
                                const Text(
                                  'ENT DEPARTMENT VITAL SIGNS',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF10B981),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    'ENT INTAKE FORM',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // BP & PR row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDialogInput(
                                    controller: bpController,
                                    label: 'BP (Blood Pressure)',
                                    hint: '120/80',
                                    unit: 'mmHg',
                                    icon: Icons.speed_rounded,
                                    isDark: isDark,
                                    accentColor: const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildDialogInput(
                                    controller: hrController,
                                    label: 'PR (Pulse Rate)',
                                    hint: '75',
                                    unit: 'bpm',
                                    icon: Icons.favorite_outline_rounded,
                                    isDark: isDark,
                                    keyboardType: TextInputType.number,
                                    accentColor: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // TEMP & O2SAT row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDialogInput(
                                    controller: tempController,
                                    label: 'TEMP (Temperature)',
                                    hint: '36.5',
                                    unit: '°C',
                                    icon: Icons.thermostat_rounded,
                                    isDark: isDark,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    accentColor: const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildDialogInput(
                                    controller: spo2Controller,
                                    label: 'O₂SAT (Oxygen Saturation)',
                                    hint: '98',
                                    unit: '%',
                                    icon: Icons.water_drop_rounded,
                                    isDark: isDark,
                                    keyboardType: TextInputType.number,
                                    accentColor: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // WT & Height row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDialogInput(
                                    controller: wtController,
                                    label: 'WT (Weight)',
                                    hint: '65.0',
                                    unit: 'kg',
                                    icon: Icons.scale_rounded,
                                    isDark: isDark,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    accentColor: const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildDialogInput(
                                    controller: htController,
                                    label: 'Height',
                                    hint: '165.0',
                                    unit: 'cm',
                                    icon: Icons.straighten_rounded,
                                    isDark: isDark,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    accentColor: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // ENT quick presets
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: [
                                _buildQuickChip('BP 120/80', () => bpController.text = '120/80', isDark),
                                _buildQuickChip('PR 72', () => hrController.text = '72', isDark),
                                _buildQuickChip('Temp 36.5°C', () => tempController.text = '36.5', isDark),
                                _buildQuickChip('O₂SAT 98%', () => spo2Controller.text = '98', isDark),
                                _buildQuickChip('WT 65 kg', () => wtController.text = '65.0', isDark),
                                _buildQuickChip('Height 165 cm', () => htController.text = '165.0', isDark),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // ── EYES / OPHTHALMOLOGY VITALS & TRIAGE ──
                      // 1. General Baseline Vitals for Eye Intake
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded, size: 16, color: AppColors.cyanCalm),
                          const SizedBox(width: 6),
                          Text(
                            'EYE PATIENT BASELINE VITALS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Grid of baseline vitals
                      Row(
                        children: [
                          Expanded(
                            child: _buildDialogInput(
                              controller: bpController,
                              label: 'BP',
                              hint: '120/80',
                              unit: 'mmHg',
                              icon: Icons.speed_rounded,
                              isDark: isDark,
                              accentColor: AppColors.cyanCalm,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDialogInput(
                              controller: hrController,
                              label: 'PR / HR',
                              hint: '75',
                              unit: 'bpm',
                              icon: Icons.favorite_outline_rounded,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              accentColor: AppColors.cyanCalm,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDialogInput(
                              controller: tempController,
                              label: 'TEMP',
                              hint: '36.5',
                              unit: '°C',
                              icon: Icons.thermostat_rounded,
                              isDark: isDark,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              accentColor: AppColors.cyanCalm,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDialogInput(
                              controller: rrController,
                              label: 'Resp. Rate',
                              hint: '18',
                              unit: 'cpm',
                              icon: Icons.air_rounded,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              accentColor: AppColors.cyanCalm,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDialogInput(
                              controller: spo2Controller,
                              label: 'O₂SAT',
                              hint: '98',
                              unit: '%',
                              icon: Icons.water_drop_rounded,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              accentColor: AppColors.cyanCalm,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDialogInput(
                              controller: wtController,
                              label: 'WT',
                              hint: '65.0',
                              unit: 'kg',
                              icon: Icons.scale_rounded,
                              isDark: isDark,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              accentColor: AppColors.cyanCalm,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDialogInput(
                              controller: htController,
                              label: 'Height',
                              hint: '165.0',
                              unit: 'cm',
                              icon: Icons.straighten_rounded,
                              isDark: isDark,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              accentColor: AppColors.cyanCalm,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildQuickChip('BP 120/80', () => bpController.text = '120/80', isDark),
                          _buildQuickChip('Temp 36.5°C', () => tempController.text = '36.5', isDark),
                          _buildQuickChip('PR 72', () => hrController.text = '72', isDark),
                          _buildQuickChip('O₂SAT 98%', () => spo2Controller.text = '98', isDark),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cyanCalm.withValues(alpha: isDark ? 0.10 : 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.cyanCalm.withValues(alpha: isEyes ? 0.45 : 0.25),
                          width: isEyes ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.visibility_rounded, size: 17, color: AppColors.cyanCalm),
                              const SizedBox(width: 7),
                              Text(
                                'OPHTHALMIC VITAL SIGNS (EYE TRIAGE)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.cyanCalm,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const Spacer(),
                              if (isEyes)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.cyanCalm,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'EYES DEPT REQUIRED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Visual Acuity (VA) Row: OD & OS
                          Text(
                            'Visual Acuity (VA c/-):',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogInput(
                                  controller: vaODController,
                                  label: 'VA OD (Right Eye)',
                                  hint: 'e.g. 20/20, 20/40, CF',
                                  icon: Icons.remove_red_eye_outlined,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDialogInput(
                                  controller: vaOSController,
                                  label: 'VA OS (Left Eye)',
                                  hint: 'e.g. 20/20, 20/30, CF',
                                  icon: Icons.remove_red_eye_outlined,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              _buildQuickChip('Both 20/20', () {
                                vaODController.text = '20/20';
                                vaOSController.text = '20/20';
                              }, isDark),
                              _buildQuickChip('OD 20/25', () => vaODController.text = '20/25', isDark),
                              _buildQuickChip('OD 20/40', () => vaODController.text = '20/40', isDark),
                              _buildQuickChip('OS 20/25', () => vaOSController.text = '20/25', isDark),
                              _buildQuickChip('OS 20/40', () => vaOSController.text = '20/40', isDark),
                              _buildQuickChip('CF (Counting Fingers)', () => vaODController.text = 'CF', isDark),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Intraocular Pressure (IOP) Row: OD & OS
                          Text(
                            'Intraocular Pressure (IOP in mmHg):',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogInput(
                                  controller: iopODController,
                                  label: 'IOP OD (Right Eye)',
                                  hint: 'e.g. 15',
                                  unit: 'mmHg',
                                  icon: Icons.compress_rounded,
                                  isDark: isDark,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDialogInput(
                                  controller: iopOSController,
                                  label: 'IOP OS (Left Eye)',
                                  hint: 'e.g. 15',
                                  unit: 'mmHg',
                                  icon: Icons.compress_rounded,
                                  isDark: isDark,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              _buildQuickChip('Both 15 mmHg (Normal)', () {
                                iopODController.text = '15';
                                iopOSController.text = '15';
                              }, isDark),
                              _buildQuickChip('OD 14 / OS 16', () {
                                iopODController.text = '14';
                                iopOSController.text = '16';
                              }, isDark),
                              _buildQuickChip('Borderline 21', () => iopODController.text = '21', isDark),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Funduscopy Row: OD & OS
                          Text(
                            'Funduscopy / Retina Examination:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogInput(
                                  controller: funduscopyODController,
                                  label: 'Funduscopy OD (Right)',
                                  hint: 'e.g. Normal disc, CDR 0.3',
                                  icon: Icons.blur_circular_rounded,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDialogInput(
                                  controller: funduscopyOSController,
                                  label: 'Funduscopy OS (Left)',
                                  hint: 'e.g. Normal disc, CDR 0.3',
                                  icon: Icons.blur_circular_rounded,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              _buildQuickChip('Normal disc (CDR 0.3)', () {
                                funduscopyODController.text = 'Normal disc, CDR 0.3';
                                funduscopyOSController.text = 'Normal disc, CDR 0.3';
                              }, isDark),
                              _buildQuickChip('Clear fundus', () {
                                funduscopyODController.text = 'Clear fundus';
                                funduscopyOSController.text = 'Clear fundus';
                              }, isDark),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Extraocular Muscle Movement (EOMM)
                          _buildDialogInput(
                            controller: eommController,
                            label: 'Extraocular Muscle Movement (EOMM)',
                            hint: 'e.g. Full range intact, no limitation in cardinal gazes',
                            icon: Icons.open_with_rounded,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 5,
                            children: [
                              _buildQuickChip('Full range intact', () => eommController.text = 'Full range intact', isDark),
                              _buildQuickChip('No limitation', () => eommController.text = 'No limitation', isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ], // end else (EYES section)

                    const SizedBox(height: 14),

                    // ── 3. NURSE INTAKE NOTES ───────────────────────────────
                    Text(
                      'Nurse Assessment & Observations:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: TextStyle(fontSize: 13, color: titleColor),
                      decoration: InputDecoration(
                        hintText: 'Enter clinical observations, triage notes, or patient remarks...',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.textDisabled : AppColors.lightTextDisabled,
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : AppColors.lightBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final patientProv = context.read<PatientProvider>();
                        final queueProv = context.read<QueueProvider>();
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(ctx);

                        setDialogState(() => isSaving = true);
                        try {
                          final newVitals = VitalSigns(
                            bloodPressure: bpController.text.trim().isNotEmpty
                                ? bpController.text.trim()
                                : null,
                            heartRate: int.tryParse(hrController.text.trim()),
                            temperature: double.tryParse(tempController.text.trim()),
                            respiratoryRate: int.tryParse(rrController.text.trim()),
                            oxygenSaturation: int.tryParse(spo2Controller.text.trim()),
                            weight: double.tryParse(wtController.text.trim()),
                            height: double.tryParse(htController.text.trim()),
                            visualAcuityOD: vaODController.text.trim().isNotEmpty
                                ? vaODController.text.trim()
                                : null,
                            visualAcuityOS: vaOSController.text.trim().isNotEmpty
                                ? vaOSController.text.trim()
                                : null,
                            intraocularPressureOD: iopODController.text.trim().isNotEmpty
                                ? iopODController.text.trim()
                                : null,
                            intraocularPressureOS: iopOSController.text.trim().isNotEmpty
                                ? iopOSController.text.trim()
                                : null,
                            funduscopyOD: funduscopyODController.text.trim().isNotEmpty
                                ? funduscopyODController.text.trim()
                                : null,
                            funduscopyOS: funduscopyOSController.text.trim().isNotEmpty
                                ? funduscopyOSController.text.trim()
                                : null,
                            extraocularMuscleMovement: eommController.text.trim().isNotEmpty
                                ? eommController.text.trim()
                                : null,
                            notes: notesController.text.trim().isNotEmpty
                                ? notesController.text.trim()
                                : null,
                          );

                          // Update PatientProvider
                          Patient? targetPatient = patient;
                          if (targetPatient == null && entry != null) {
                            targetPatient = patientProv
                                .patients
                                .where((p) => p.id == entry.patientId)
                                .firstOrNull;
                            targetPatient ??=
                                await patientProv.getPatientById(entry.patientId);
                          }
                          if (targetPatient != null) {
                            final updated = targetPatient.copyWith(vitalSigns: newVitals);
                            await patientProv.updatePatient(updated);
                          }

                          // Update QueueProvider
                          if (entry != null) {
                            await queueProv.updateEntryVitals(entry.id, newVitals);
                            if (entry.isTriage) {
                              await queueProv.completeTriage(entry.id, vitals: newVitals);
                            }
                          } else if (targetPatient != null) {
                            final todayEntry = queueProv.todayQueue
                                .where((e) => e.patientId == targetPatient!.id && !e.isCompleted)
                                .firstOrNull;
                            if (todayEntry != null) {
                              await queueProv.updateEntryVitals(todayEntry.id, newVitals);
                              if (todayEntry.isTriage) {
                                await queueProv.completeTriage(todayEntry.id, vitals: newVitals);
                              }
                            }
                          }

                          if (!mounted) return;
                          navigator.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Vital signs saved successfully for $patientName'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error saving vitals: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(isSaving ? 'Saving Vitals...' : 'Save Vital Signs'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? unit,
    TextInputType keyboardType = TextInputType.text,
    Color? accentColor, // optional department accent (ENT=green, EYES=cyan, default=pink)
  }) {
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final iconColor = accentColor ?? const Color(0xFFEC4899);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13, color: textColor),
      decoration: InputDecoration(
        labelText: unit != null ? '$label ($unit)' : label,
        labelStyle: TextStyle(
          fontSize: 11.5,
          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 11.5,
          color: isDark ? AppColors.textDisabled : AppColors.lightTextDisabled,
        ),
        prefixIcon: Icon(icon, size: 16, color: iconColor),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.lightBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: iconColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}
