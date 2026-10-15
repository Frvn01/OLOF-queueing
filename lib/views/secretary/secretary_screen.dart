import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/queue_provider.dart';
import '../../data/models/queue_entry.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../providers/theme_provider.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/audio_helper.dart';

/// Clinic Coordinator Station — Central Master Caller & Queue Management.
/// The Clinic Coordinator triggers both 1st Call (Nurse Station Vitals) and
/// 2nd Call (Doctor Consultation Rooms), with live oversight of queue flow.
class SecretaryScreen extends StatefulWidget {
  const SecretaryScreen({super.key});

  @override
  State<SecretaryScreen> createState() => _SecretaryScreenState();
}

class _SecretaryScreenState extends State<SecretaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedDoctorFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          child: Column(
            children: [
              _buildAppBar(context, isDark, isCompact),
              _buildTabBar(context, isDark, isCompact),
              Expanded(child: _buildTabContent(context, isDark, isCompact)),
            ],
          ),
        ),
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
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Clinic Coordinator',
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Master Calling Station — 1st Call (Vitals) & 2nd Call (Doctor Rooms)',
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Master Caller badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFF0284C7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_rounded, size: 14, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'MASTER CALLER',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
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
          // Refresh
          IconButton(
            onPressed: () => context.read<QueueProvider>().refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh Queue',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, bool isDark, bool isCompact) {
    final tabBg = isDark ? AppColors.surfaceDark : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: tabBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: isDark ? AppColors.primaryLight : AppColors.primaryDark,
        unselectedLabelColor:
            isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hearing_rounded, size: 18),
                const SizedBox(width: 6),
                Text(
                  isCompact ? 'ENT DEPT' : 'ENT DEPARTMENT',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 6),
                Consumer<QueueProvider>(
                  builder: (context, p, child) {
                    final waiting = p.getWaiting('ENT').length;
                    return waiting > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$waiting',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.visibility_rounded, size: 18),
                const SizedBox(width: 6),
                Text(
                  isCompact ? 'EYES DEPT' : 'EYES (OPHTHALMOLOGY)',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 6),
                Consumer<QueueProvider>(
                  builder: (context, p, child) {
                    final waiting = p.getWaiting('EYES').length;
                    return waiting > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$waiting',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, bool isDark, bool isCompact) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDepartmentView(context, 'ENT', AppColors.entColor, isDark, isCompact),
        _buildDepartmentView(context, 'EYES', AppColors.eyesColor, isDark, isCompact),
      ],
    );
  }

  Widget _buildDepartmentView(
    BuildContext context,
    String department,
    Color color,
    bool isDark,
    bool isCompact,
  ) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Consumer<QueueProvider>(
      builder: (context, provider, _) {
        final allDeptWaiting = provider.getWaiting(department);
        final triageList = provider.getTriage(department);
        final distinctDocs = <String>{};
        for (final e in provider.getQueue(department)) {
          if (e.assignedDoctor != null && e.assignedDoctor!.trim().isNotEmpty) {
            distinctDocs.add(DoctorHelper.formatName(e.assignedDoctor!));
          }
        }

        final selectedDoc = _selectedDoctorFilter;
        final docWaiting = selectedDoc != null
            ? provider.getDoctorWaiting(department, selectedDoc)
            : allDeptWaiting;
        final docServing = selectedDoc != null
            ? provider.getDoctorNowServing(department, selectedDoc)
            : provider.getNowServing(department);
        final completed = provider.getCompleted(department);
        final stats = provider.getStats(department);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 24,
            vertical: isCompact ? 16 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats Row ───────────────────────────────────────────
              _buildStatsRow(context, stats, provider, department, color, isDark, isCompact),
              const SizedBox(height: 18),

              // ── Now Serving ─────────────────────────────────────────
              _buildNowServing(context, department, docServing, color, isDark, isCompact),
              const SizedBox(height: 18),

              // ── 1st Call (Triage) Active Banner ───────────────────────
              if (triageList.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.14 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEC4899), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monitor_heart_rounded, color: Color(0xFFEC4899), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1ST CALL ACTIVE — ${triageList.length} patient${triageList.length > 1 ? 's' : ''} at Nurse Station',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEC4899),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              triageList.map((e) => e.queueNumber).join(', '),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // ── Doctor Filter Chips ─────────────────────────────────
              if (distinctDocs.isNotEmpty) ...[
                Text(
                  'Doctor Queue Filter:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('All Doctors (${allDeptWaiting.length})'),
                        selected: selectedDoc == null,
                        onSelected: (_) => setState(() => _selectedDoctorFilter = null),
                        selectedColor: color.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          fontWeight: selectedDoc == null ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      ...distinctDocs.map((doc) {
                        final count = provider.getDoctorWaiting(department, doc).length;
                        final isSelected = selectedDoc == doc;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text('$doc ($count)'),
                            selected: isSelected,
                            onSelected: (_) => setState(
                                () => _selectedDoctorFilter = isSelected ? null : doc),
                            selectedColor: color.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Waiting Queue ───────────────────────────────────────
              Text(
                selectedDoc != null
                    ? 'Waiting for $selectedDoc (${docWaiting.length})'
                    : 'Waiting Queue (${docWaiting.length})',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 10),
              if (docWaiting.isEmpty)
                _buildEmptyState('No patients waiting in queue', Icons.hourglass_empty_rounded, isDark)
              else
                ...docWaiting.map(
                    (e) => _buildQueueCard(context, e, department, color, isDark)),

              const SizedBox(height: 22),

              // ── Completed List ──────────────────────────────────────
              if (completed.isNotEmpty) ...[
                Text(
                  'Completed Consultations (${completed.length})',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 10),
                ...completed.reversed.take(10).map(
                    (e) => _buildCompletedCard(context, e, isDark)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    Map<String, int> stats,
    QueueProvider provider,
    String department,
    Color color,
    bool isDark,
    bool isCompact,
  ) {
    final triageCount = provider.getTriage(department).length;
    final vitalsReadyCount = provider.getWaiting(department).where((e) => e.hasVitals).length;

    return Row(
      children: [
        _buildStatTile('Waiting', stats['waiting'] ?? 0, AppColors.warning, isDark, isCompact),
        SizedBox(width: isCompact ? 6 : 10),
        _buildStatTile('Serving', stats['serving'] ?? 0, AppColors.nowServing, isDark, isCompact),
        SizedBox(width: isCompact ? 6 : 10),
        _buildStatTile('At Triage', triageCount, const Color(0xFFEC4899), isDark, isCompact),
        SizedBox(width: isCompact ? 6 : 10),
        _buildStatTile('Vitals ✓', vitalsReadyCount, AppColors.success, isDark, isCompact),
        SizedBox(width: isCompact ? 6 : 10),
        _buildStatTile('Done', stats['completed'] ?? 0, AppColors.cyanCalm, isDark, isCompact),
      ],
    );
  }

  Widget _buildStatTile(
    String label,
    int count,
    Color color,
    bool isDark,
    bool isCompact,
  ) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 4 : 10,
          vertical: isCompact ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: count > 0 ? color.withValues(alpha: 0.4) : borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: isCompact ? 20 : 24,
                fontWeight: FontWeight.w900,
                color: count > 0 ? color : (isDark ? AppColors.textDisabled : AppColors.lightTextDisabled),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 10.5 : 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNowServing(
    BuildContext context,
    String department,
    QueueEntry? entry,
    Color color,
    bool isDark,
    bool isCompact,
  ) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 18 : 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: entry != null ? AppColors.nowServing : borderColor,
          width: entry != null ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: entry != null
                ? AppColors.nowServing.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: entry != null
          ? Row(
              children: [
                // Queue number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.nowServing,
                        AppColors.nowServing.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    entry.queueNumber,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.surfaceDarkest,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.nowServing.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '2ND CALL — IN CONSULTATION',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.nowServing,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          if (entry.hasVitals) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Vitals ✓',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.purpose,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.assignedDoctor != null && entry.assignedDoctor!.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final room = (entry.assignedRoom != null &&
                                    entry.assignedRoom!.trim().isNotEmpty &&
                                    entry.assignedRoom!.trim().toLowerCase() != 'nurse station')
                                ? entry.assignedRoom!
                                : (DoctorHelper.getDoctorRoom(entry.assignedDoctor, department: entry.department) ??
                                    'Consultation Room');
                            return Text(
                              '${entry.assignedDoctor!} • $room',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: subtitleColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                // Action buttons for currently serving
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _markComplete(entry.id),
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                Icon(Icons.person_off_rounded, size: 34, color: subtitleColor),
                const SizedBox(height: 8),
                Text(
                  'No patient currently in consultation',
                  style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQueueCard(BuildContext context, QueueEntry entry,
      String department, Color color, bool isDark) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    Color statusColor = borderColor;
    if (entry.isTriage) statusColor = const Color(0xFFEC4899);
    if (entry.isOnHold) statusColor = AppColors.onHold;
    if (entry.hasVitals) statusColor = const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Queue Number Box
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    entry.queueNumber.split('-').last,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.purpose,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: titleColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (entry.isTriage)
                          _buildStatusChip('1st Call Active', const Color(0xFFEC4899))
                        else if (entry.hasVitals)
                          _buildStatusChip('Vitals ✓ Ready', AppColors.success)
                        else
                          _buildStatusChip('Pending Vitals', AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.queueNumber,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((entry.assignedDoctor != null && entry.assignedDoctor!.isNotEmpty) ||
                        (entry.assignedRoom != null && entry.assignedRoom!.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            if (entry.assignedDoctor != null && entry.assignedDoctor!.isNotEmpty) ...[
                              const Icon(Icons.medical_services_rounded, size: 12, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  entry.assignedDoctor!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (entry.assignedRoom != null && entry.assignedRoom!.isNotEmpty) ...[
                              const Icon(Icons.meeting_room_rounded, size: 12, color: AppColors.cyanCalm),
                              const SizedBox(width: 3),
                              Text(
                                entry.assignedRoom!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cyanCalm,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (entry.isOnHold)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.onHold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ON HOLD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onHold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Admin Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entry.isOnHold)
                    IconButton(
                      onPressed: () => _resumeEntry(entry.id),
                      icon: const Icon(Icons.play_arrow_rounded),
                      tooltip: 'Resume',
                      color: AppColors.success,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    )
                  else
                    IconButton(
                      onPressed: () => _holdEntry(entry.id),
                      icon: const Icon(Icons.pause_rounded),
                      tooltip: 'Hold',
                      color: AppColors.onHold,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    ),
                  IconButton(
                    onPressed: () => _skipEntry(entry.id),
                    icon: const Icon(Icons.skip_next_rounded),
                    tooltip: 'Skip',
                    color: AppColors.warning,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  ),
                  IconButton(
                    onPressed: () => _confirmDeleteEntry(entry),
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Remove',
                    color: AppColors.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: borderColor.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          // ── Coordinator Direct Calling Buttons ──
          Row(
            children: [
              // 1st Call (Vitals) button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callForVitals(entry),
                  icon: Icon(
                    entry.isTriage ? Icons.campaign_rounded : Icons.monitor_heart_rounded,
                    size: 16,
                  ),
                  label: Text(
                    entry.isTriage
                        ? 'Recall (1st Call)'
                        : (entry.hasVitals ? 'Re-call Vitals' : '1st Call (Vitals)'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: entry.isTriage
                        ? const Color(0xFFD97706)
                        : (entry.hasVitals ? (isDark ? AppColors.surfaceLight : AppColors.lightSurfaceMid) : const Color(0xFFEC4899)),
                    foregroundColor: entry.hasVitals && !entry.isTriage ? titleColor : Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 2nd Call (Doctor) button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callForDoctor(entry),
                  icon: const Icon(Icons.meeting_room_rounded, size: 16),
                  label: Text(
                    entry.assignedDoctor != null && entry.assignedDoctor!.isNotEmpty
                        ? '2nd Call (${entry.assignedDoctor!.split(' ').last})'
                        : '2nd Call (Doctor)',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: entry.hasVitals ? const Color(0xFF10B981) : AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, QueueEntry entry, bool isDark) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
          const SizedBox(width: 10),
          Text(
            entry.queueNumber,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.success,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.purpose,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: subtitleColor,
                fontSize: 13.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            entry.assignedRoom ?? '',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, bool isDark) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: subtitleColor),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: subtitleColor,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Calling Action Methods ──

  Future<void> _callForVitals(QueueEntry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<QueueProvider>().callForTriage(entry.id);
      await AudioHelper.playChime();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '1ST CALL: ${entry.queueNumber} called to Nurse Station for Vital Signs!',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEC4899),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to call for vitals: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _callForDoctor(QueueEntry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final docName = entry.assignedDoctor;
      final room = (entry.assignedRoom != null &&
              entry.assignedRoom!.trim().isNotEmpty &&
              entry.assignedRoom!.trim().toLowerCase() != 'nurse station')
          ? entry.assignedRoom
          : DoctorHelper.getDoctorRoom(docName, department: entry.department);

      await context.read<QueueProvider>().callEntry(
        entry.id,
        roomNumber: room,
        doctor: docName,
      );
      await AudioHelper.playChime();
      if (!mounted) return;
      final dest = (room != null && room.isNotEmpty)
          ? (docName != null && docName.isNotEmpty ? '$docName ($room)' : room)
          : (docName != null && docName.isNotEmpty ? docName : 'Consultation Room');
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '2ND CALL: ${entry.queueNumber} called to $dest!',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to call for doctor: $e'), backgroundColor: AppColors.error),
      );
    }
  }


  Future<void> _markComplete(String entryId) async {
    await context.read<QueueProvider>().markComplete(entryId);
  }

  Future<void> _skipEntry(String entryId) async {
    await context.read<QueueProvider>().skipEntry(entryId);
  }

  Future<void> _holdEntry(String entryId) async {
    await context.read<QueueProvider>().holdEntry(entryId);
  }

  Future<void> _resumeEntry(String entryId) async {
    await context.read<QueueProvider>().resumeEntry(entryId);
  }

  Future<void> _confirmDeleteEntry(QueueEntry entry) async {
    final themeProv = context.read<ThemeProvider>();
    final isDark = themeProv.isDarkMode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.urgent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.urgent, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Remove from Queue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${entry.queueNumber} from the active queue?',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.urgent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<QueueProvider>().removeFromQueue(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.queueNumber} removed from queue'),
            backgroundColor: AppColors.urgent,
          ),
        );
      }
    }
  }
}
