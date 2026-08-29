import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/queue_provider.dart';
import '../../data/models/queue_entry.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../shared/widgets/tutorial_dialog.dart';
import '../../providers/theme_provider.dart';

/// Secretary Dashboard — Queue management
class SecretaryScreen extends StatefulWidget {
  const SecretaryScreen({super.key});

  @override
  State<SecretaryScreen> createState() => _SecretaryScreenState();
}

class _SecretaryScreenState extends State<SecretaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedRoom = 'Room 1';

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
                  'Secretary Station',
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Doctor Queue & Room Calling',
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
          // Room selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceMid : AppColors.lightSurfaceMid,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRoom,
                dropdownColor: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
                items: ['Room 1', 'Room 2', 'Room 3']
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRoom = v!),
              ),
            ),
          ),
          const SizedBox(width: 2),
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
          // Tutorial Button
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.cyanCalm, size: 20),
            tooltip: 'Secretary Guide',
            onPressed: () => _showSecretaryTutorial(context),
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

  void _showSecretaryTutorial(BuildContext context) {
    TutorialDialog.show(
      context,
      title: 'Secretary Station Guide',
      steps: [
        TutorialItem(
          title: '1. Select Consultation Room',
          description:
              'Choose your assigned doctor\'s room from the dropdown at the top right (Room 1, 2, or 3).',
          icon: Icons.meeting_room_rounded,
          color: AppColors.primary,
        ),
        TutorialItem(
          title: '2. Switch Departments',
          description:
              'Toggle between the ENT and EYES tabs to manage their respective waiting queues and view real-time statistics.',
          icon: Icons.tab_rounded,
          color: AppColors.cyanCalm,
        ),
        TutorialItem(
          title: '3. Call Next Patient',
          description:
              'Click "Call Next Patient" to notify the patient. The TV display in the lobby instantly highlights the number and plays a chime alert!',
          icon: Icons.campaign_rounded,
          color: AppColors.warning,
        ),
        TutorialItem(
          title: '4. Hold, Skip, or Complete',
          description:
              'If a patient is temporarily away, tap Hold to pause their turn, or Skip to move to the next. Tap "Mark Complete" once consultation is finished.',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
      ],
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

    return Consumer<QueueProvider>(
      builder: (context, provider, _) {
        final nowServing = provider.getNowServing(department);
        final waiting = provider.getWaiting(department);
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
              // Stats Row
              _buildStatsRow(context, stats, color, isDark, isCompact),
              const SizedBox(height: 18),

              // Now Serving
              _buildNowServing(context, department, nowServing, color, isDark, isCompact),
              const SizedBox(height: 18),

              // Call Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: waiting.isNotEmpty
                      ? () => _callNext(department)
                      : null,
                  icon: const Icon(Icons.campaign_rounded, size: 22),
                  label: Text(
                    waiting.isNotEmpty
                        ? 'Call Next Patient (${waiting.first.queueNumber})'
                        : 'No Patients Waiting in Queue',
                    style: TextStyle(
                      fontSize: isCompact ? 15.5 : 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Waiting List
              Text(
                'Waiting Queue (${waiting.length})',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 10),
              if (waiting.isEmpty)
                _buildEmptyState('No patients waiting in queue', Icons.hourglass_empty_rounded, isDark)
              else
                ...waiting.map(
                    (e) => _buildQueueCard(context, e, department, color, isDark)),

              const SizedBox(height: 22),

              // Completed List
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
    Color color,
    bool isDark,
    bool isCompact,
  ) {
    return Row(
      children: [
        _buildStatTile(
            'Waiting', stats['waiting'] ?? 0, AppColors.warning, isDark, isCompact),
        SizedBox(width: isCompact ? 6 : 10),
        _buildStatTile(
            'Serving', stats['serving'] ?? 0, AppColors.nowServing, isDark, isCompact),
        SizedBox(width: isCompact ? 6 : 10),
        _buildStatTile(
            'Done', stats['completed'] ?? 0, AppColors.success, isDark, isCompact),
        SizedBox(width: isCompact ? 6 : 10),
        _buildStatTile(
            'On Hold', stats['onHold'] ?? 0, AppColors.onHold, isDark, isCompact),
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
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: isCompact ? 20 : 24,
                fontWeight: FontWeight.w900,
                color: color,
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
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 18 : 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: entry != null
              ? AppColors.nowServing
              : borderColor,
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
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.nowServing,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NOW SERVING',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.surfaceDarkest,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.queueNumber,
                  style: TextStyle(
                    fontSize: isCompact ? 42 : 48,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.nowServing : const Color(0xFFB45309),
                  ),
                ),
                Text(
                  entry.patientName.toUpperCase(),
                  style: TextStyle(
                    fontSize: isCompact ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.assignedRoom ?? "—"} • ${entry.purpose}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _markComplete(entry.id),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Mark Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(180, 46),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Icon(Icons.person_off_rounded,
                    size: 34, color: subtitleColor),
                const SizedBox(height: 8),
                Text(
                  'No patient currently called',
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isOnHold
              ? AppColors.onHold
              : borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
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
                Text(
                  entry.patientName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.purpose,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (entry.isOnHold)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
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
          // Actions
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
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                )
              else
                IconButton(
                  onPressed: () => _holdEntry(entry.id),
                  icon: const Icon(Icons.pause_rounded),
                  tooltip: 'Hold',
                  color: AppColors.onHold,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              IconButton(
                onPressed: () => _skipEntry(entry.id),
                icon: const Icon(Icons.skip_next_rounded),
                tooltip: 'Skip',
                color: AppColors.warning,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
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
          const Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.success),
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
              entry.patientName,
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

  Future<void> _callNext(String department) async {
    await context
        .read<QueueProvider>()
        .callNext(department, _selectedRoom);
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
}
