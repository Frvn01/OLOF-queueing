import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/patient_provider.dart';
import '../../providers/queue_provider.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../shared/widgets/tutorial_dialog.dart';
import '../../providers/theme_provider.dart';

import '../../data/models/patient.dart';
import '../../data/models/queue_entry.dart';
import '../../shared/widgets/queue_ticket_print.dart';

/// Receptionist Dashboard — main hub for registration and check-in
class ReceptionistScreen extends StatefulWidget {
  const ReceptionistScreen({super.key});

  @override
  State<ReceptionistScreen> createState() => _ReceptionistScreenState();
}

class _ReceptionistScreenState extends State<ReceptionistScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDeptFilter = 'ALL'; // 'ALL', 'ENT', 'EYES', 'TODAY_QUEUE'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().initialize();
      context.read<QueueProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 16 : 24,
                    vertical: isLandscape ? 10 : (isCompact ? 16 : 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions
                      _buildQuickActions(context, isDark, isCompact),
                      SizedBox(height: isLandscape ? 14 : 22),

                      // Search
                      _buildSearchSection(context, isDark, isCompact),
                      SizedBox(height: isLandscape ? 14 : 22),

                      // Today's Stats
                      _buildTodayStats(context, isDark, isCompact),
                      SizedBox(height: isLandscape ? 14 : 22),

                      // Recent Registrations
                      _buildPatientDirectorySection(context, isDark),
                    ],
                  ),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          const OlofLogo(size: 36, showBorder: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Receptionist Station',
                  style: TextStyle(
                    fontSize: isCompact ? 16.5 : 18,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Registration & Patient Check-in',
                  style: TextStyle(
                    fontSize: isCompact ? 11.5 : 12.5,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Queue Archive Button
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: AppColors.cyanCalm),
            tooltip: 'Queue Archive & Patient History',
            onPressed: () => context.push('/archive'),
          ),
          // Tutorial Button
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.cyanCalm),
            tooltip: 'Receptionist Guide',
            onPressed: () => _showReceptionistTutorial(context),
          ),
          // Theme Switcher
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.warning : AppColors.brandBlue,
            ),
            tooltip: isDark
                ? 'Switch to Eye-Comfort Light'
                : 'Switch to Eye-Comfort Dark',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 4),
            // Today's date badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceMid : AppColors.lightSurfaceMid,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: isDark ? AppColors.textSecondary : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatToday(),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReceptionistTutorial(BuildContext context) {
    TutorialDialog.show(
      context,
      title: 'Receptionist Station Guide',
      steps: [
        TutorialItem(
          title: '1. Registering New Patients',
          description:
              'Tap "New Patient Registration" to open the multi-step form. Fill in the required patient details, birthdate, and complaints.',
          icon: Icons.person_add_rounded,
          color: AppColors.primary,
        ),
        TutorialItem(
          title: '2. QR Code Generation',
          description:
              'Once registered, the patient receives a unique OLOF QR Code ID. You can print it or let the patient photograph it on their phone.',
          icon: Icons.qr_code_2_rounded,
          color: AppColors.cyanCalm,
        ),
        TutorialItem(
          title: '3. Quick Check-In for Returning Patients',
          description:
              'Returning patients simply scan their QR code or you can search them by name to immediately assign their department (ENT/EYES) and issue a queue number.',
          icon: Icons.login_rounded,
          color: AppColors.warning,
        ),
        TutorialItem(
          title: '4. Real-Time Sync to Secretary & TV',
          description:
              'As soon as a queue number is issued, it appears on the doctor secretary\'s station and the waiting lobby TV projection with a chime alert.',
          icon: Icons.tv_rounded,
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark, bool isCompact) {
    final actions = [
      _QuickAction(
        icon: Icons.person_add_rounded,
        label: 'New Patient Registration',
        sublabel: 'Paperless intake & QR ID card',
        gradient: AppColors.primaryGradient,
        onTap: () => context.go('/receptionist/register'),
      ),
      _QuickAction(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Scan QR Check-in',
        sublabel: 'Instant lookup & queue ticket',
        gradient: AppColors.entGradient,
        onTap: () => context.go('/receptionist/checkin'),
      ),
      _QuickAction(
        icon: Icons.archive_outlined,
        label: 'Queue Archive',
        sublabel: 'Past patients by date & purpose',
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => context.push('/archive'),
      ),
    ];

    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 900) {
      return Row(
        children: [
          Expanded(child: _buildActionCard(context, actions[0], isDark)),
          const SizedBox(width: 14),
          Expanded(child: _buildActionCard(context, actions[1], isDark)),
          const SizedBox(width: 14),
          Expanded(child: _buildActionCard(context, actions[2], isDark)),
        ],
      );
    } else if (screenWidth >= 600) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildActionCard(context, actions[0], isDark)),
              const SizedBox(width: 14),
              Expanded(child: _buildActionCard(context, actions[1], isDark)),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionCard(context, actions[2], isDark),
        ],
      );
    }

    return Column(
      children: [
        _buildActionCard(context, actions[0], isDark),
        const SizedBox(height: 12),
        _buildActionCard(context, actions[1], isDark),
        const SizedBox(height: 12),
        _buildActionCard(context, actions[2], isDark),
      ],
    );
  }

  Widget _buildActionCard(
      BuildContext context, _QuickAction action, bool isDark) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: action.gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (action.gradient as LinearGradient)
                        .colors
                        .first
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(action.icon, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.sublabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: subtitleColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context, bool isDark, bool isCompact) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Consumer<PatientProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Registered Patients',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      setState(() {});
                      provider.search(v);
                    },
                    onSubmitted: (v) => provider.search(v),
                    textInputAction: TextInputAction.search,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by patient name, ID, or phone...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                provider.search('');
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear_rounded),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: provider.isSearching
                      ? null
                      : () => provider.search(_searchController.text),
                  icon: provider.isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search_rounded, size: 18),
                  label: Text(provider.isSearching ? 'Searching...' : 'Search'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 18,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (provider.isSearching) ...[
              const SizedBox(height: 10),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Searching patients...',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (provider.searchQuery.trim().isNotEmpty && provider.searchResults.isEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_off_rounded,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No registered patient found matching "${provider.searchQuery}".',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/receptionist/register'),
                      child: const Text('Register New', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ] else if (provider.searchResults.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: provider.searchResults.length,
                  separatorBuilder: (context, index) => Divider(
                    color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final patient = provider.searchResults[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          patient.firstName.isNotEmpty
                              ? patient.firstName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        patient.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          fontSize: 14.5,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${patient.patientNo} • ${patient.sex}, ${patient.age} yrs',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => context.go(
                                '/receptionist/patient/${patient.id}'),
                            icon: const Icon(Icons.info_outline_rounded, size: 20),
                            tooltip: 'View Record',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => context.go(
                                '/receptionist/checkin?patientId=${patient.id}'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Check In', style: TextStyle(fontSize: 12.5)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTodayStats(BuildContext context, bool isDark, bool isCompact) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return Consumer<QueueProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Queue Overview",
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            if (!isCompact)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'ENT DEPARTMENT',
                      provider.getStats('ENT'),
                      AppColors.entColor,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'EYES (OPHTHALMOLOGY)',
                      provider.getStats('EYES'),
                      AppColors.eyesColor,
                      isDark,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildStatCard(
                    context,
                    'ENT DEPARTMENT',
                    provider.getStats('ENT'),
                    AppColors.entColor,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    context,
                    'EYES (OPHTHALMOLOGY)',
                    provider.getStats('EYES'),
                    AppColors.eyesColor,
                    isDark,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String dept,
    Map<String, int> stats,
    Color color,
    bool isDark,
  ) {
    final deptKey = dept.contains('ENT') ? 'ENT' : 'EYES';
    final isSelected = _selectedDeptFilter == deptKey;
    final waiting = stats['waiting'] ?? 0;
    final serving = stats['serving'] ?? 0;
    final completed = stats['completed'] ?? 0;
    final total = stats['total'] ?? 0;

    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isSelected
        ? color
        : (isDark ? AppColors.surfaceLight : AppColors.lightBorder);
    final subtitleColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDeptFilter =
              _selectedDeptFilter == deptKey ? 'ALL' : deptKey;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.08 : 0.04)
              : cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 16,
                spreadRadius: 1,
              )
            else
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    dept,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$total registered',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                    'Waiting', waiting, AppColors.warning, isDark),
                _buildMiniStat(
                    'Serving', serving, AppColors.nowServing, isDark),
                _buildMiniStat(
                    'Done', completed, AppColors.success, isDark),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showDepartmentQueueDialog(context, deptKey, isDark),
                icon: Icon(Icons.list_alt_rounded,
                    size: 16, color: color),
                label: Text(
                  'View Live Queue',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side:
                      BorderSide(color: color.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientDirectorySection(BuildContext context, bool isDark) {
    final titleColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor =
        isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final subtitleColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Consumer2<PatientProvider, QueueProvider>(
      builder: (context, patientProv, queueProv, _) {
        final allPatients = patientProv.patients.reversed.toList();

        // Build map: patientId → QueueEntry for today
        final Map<String, QueueEntry> todayQueueMap = {};
        for (final entry in queueProv.todayQueue) {
          todayQueueMap[entry.patientId] = entry;
        }

        // Categorize patients by department
        final entPatients = allPatients.where((p) {
          final entry = todayQueueMap[p.id];
          if (entry != null) return entry.department == 'ENT';
          final room = (p.assignedRoom ?? '').toUpperCase();
          return room.contains('ENT');
        }).toList();

        final eyesPatients = allPatients.where((p) {
          final entry = todayQueueMap[p.id];
          if (entry != null) return entry.department == 'EYES';
          final room = (p.assignedRoom ?? '').toUpperCase();
          return room.contains('OPHTHA') || room.contains('EYE');
        }).toList();

        final todayQueuePatients = allPatients
            .where((p) => todayQueueMap.containsKey(p.id))
            .toList();

        // Determine which list to show
        List<Patient> displayedPatients;
        String sectionTitle;
        switch (_selectedDeptFilter) {
          case 'ENT':
            displayedPatients = entPatients;
            sectionTitle = 'ENT Patients';
            break;
          case 'EYES':
            displayedPatients = eyesPatients;
            sectionTitle = 'Eyes (Ophtha) Patients';
            break;
          case 'TODAY_QUEUE':
            displayedPatients = todayQueuePatients;
            sectionTitle = "Today's Queued Patients";
            break;
          default:
            displayedPatients = allPatients;
            sectionTitle = 'All Patients';
        }

        final filters = [
          _DeptFilterOption(
              'ALL', 'All Patients', allPatients.length, AppColors.primary),
          _DeptFilterOption(
              'ENT', 'ENT', entPatients.length, AppColors.entColor),
          _DeptFilterOption(
              'EYES', 'Eyes', eyesPatients.length, AppColors.eyesColor),
          _DeptFilterOption('TODAY_QUEUE', "Today's Queue",
              todayQueuePatients.length, AppColors.cyanCalm),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionTitle,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 10),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isActive = _selectedDeptFilter == f.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${f.label} (${f.count})',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: isActive
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                      selected: isActive,
                      selectedColor: f.color,
                      backgroundColor: isDark
                          ? AppColors.surfaceMid
                          : AppColors.lightSurfaceMid,
                      side: BorderSide(
                        color: isActive
                            ? f.color
                            : (isDark
                                ? AppColors.surfaceLight
                                : AppColors.lightBorder),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onSelected: (_) =>
                          setState(() => _selectedDeptFilter = f.key),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            if (displayedPatients.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(Icons.people_outline_rounded,
                        size: 40, color: subtitleColor),
                    const SizedBox(height: 10),
                    Text(
                      _selectedDeptFilter == 'ALL'
                          ? 'No patients registered yet'
                          : 'No patients found for this filter',
                      style: TextStyle(
                          color: subtitleColor,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.go('/receptionist/register'),
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Register First Patient'),
                    ),
                  ],
                ),
              )
            else
              ...displayedPatients.map((patient) {
                final queueEntry = todayQueueMap[patient.id];
                final deptKey = queueEntry?.department;
                final Color deptColor = deptKey == 'ENT'
                    ? AppColors.entColor
                    : deptKey == 'EYES'
                        ? AppColors.eyesColor
                        : AppColors.textSecondary;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                            alpha: isDark ? 0.15 : 0.03),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: (deptKey == 'ENT'
                              ? AppColors.entColor
                              : deptKey == 'EYES'
                                  ? AppColors.eyesColor
                                  : AppColors.primary)
                          .withValues(alpha: 0.15),
                      child: Text(
                        patient.firstName.isNotEmpty
                            ? patient.firstName[0].toUpperCase()
                            : 'P',
                        style: TextStyle(
                          color: deptKey == 'ENT'
                              ? AppColors.entColor
                              : deptKey == 'EYES'
                                  ? AppColors.eyesColor
                                  : AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            patient.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              fontSize: 14.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (deptKey != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  deptColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: deptColor.withValues(
                                      alpha: 0.3)),
                            ),
                            child: Text(
                              deptKey,
                              style: TextStyle(
                                color: deptColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'ID: ${patient.patientNo} • ${patient.sex}, ${patient.age} yrs',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (queueEntry != null) ...[
                          const SizedBox(width: 8),
                          _buildQueueStatusBadge(queueEntry, isDark),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (queueEntry != null)
                          IconButton(
                            onPressed: () =>
                                showQueueTicketPrintDialog(
                              context,
                              ticket: QueueTicketData(
                                queueNumber: queueEntry.queueNumber,
                                patientName: patient.displayName,
                                department: queueEntry.department,
                                doctorName:
                                    queueEntry.assignedDoctor,
                                roomName: queueEntry.assignedRoom,
                                purpose: queueEntry.purpose,
                                issuedAt: queueEntry.createdAt,
                              ),
                              isDark: isDark,
                            ),
                            icon: const Icon(Icons.print_rounded,
                                size: 18, color: AppColors.cyanCalm),
                            tooltip: 'Print Queue Slip',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        else
                          IconButton(
                            onPressed: () => context.go(
                                '/receptionist/checkin?patientId=${patient.id}'),
                            icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 18,
                                color: AppColors.primary),
                            tooltip: 'Check In & Queue',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded,
                            color: subtitleColor, size: 20),
                      ],
                    ),
                    onTap: () => context
                        .go('/receptionist/patient/${patient.id}'),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildQueueStatusBadge(QueueEntry entry, bool isDark) {
    Color badgeColor;
    String label;
    IconData icon;

    switch (entry.status) {
      case 'serving':
        badgeColor = AppColors.nowServing;
        label = '#${entry.queueNumber.split('-').last} Serving';
        icon = Icons.play_circle_filled_rounded;
        break;
      case 'completed':
        badgeColor = AppColors.success;
        label = '#${entry.queueNumber.split('-').last} Done';
        icon = Icons.check_circle_rounded;
        break;
      case 'on_hold':
        badgeColor = AppColors.warning;
        label = '#${entry.queueNumber.split('-').last} Hold';
        icon = Icons.pause_circle_filled_rounded;
        break;
      default:
        badgeColor = AppColors.warning;
        label = '#${entry.queueNumber.split('-').last} Waiting';
        icon = Icons.access_time_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: badgeColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showDepartmentQueueDialog(
      BuildContext context, String deptKey, bool isDark) {
    final queueProv = context.read<QueueProvider>();
    final entries = queueProv.getQueue(deptKey);
    final deptLabel =
        deptKey == 'ENT' ? 'ENT Department' : 'Eyes (Ophthalmology)';
    final deptColor =
        deptKey == 'ENT' ? AppColors.entColor : AppColors.eyesColor;

    final waiting = entries.where((e) => e.isWaiting).toList();
    final serving = entries.where((e) => e.isServing).toList();
    final completed = entries.where((e) => e.isCompleted).toList();

    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor =
        isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.lightBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 520, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: deptKey == 'ENT'
                      ? AppColors.entGradient
                      : AppColors.eyesGradient,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt_rounded,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$deptLabel — Live Queue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Summary row
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat('Waiting', waiting.length,
                        AppColors.warning, isDark),
                    _buildMiniStat('Serving', serving.length,
                        AppColors.nowServing, isDark),
                    _buildMiniStat('Done', completed.length,
                        AppColors.success, isDark),
                  ],
                ),
              ),
              Divider(color: borderColor, height: 1),
              // Queue list
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.hourglass_empty_rounded,
                          size: 40, color: subtitleColor),
                      const SizedBox(height: 10),
                      Text(
                        'No patients queued yet for $deptLabel today',
                        style: TextStyle(
                            color: subtitleColor,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      Color statusColor;
                      IconData statusIcon;
                      switch (e.status) {
                        case 'serving':
                          statusColor = AppColors.nowServing;
                          statusIcon =
                              Icons.play_circle_filled_rounded;
                          break;
                        case 'completed':
                          statusColor = AppColors.success;
                          statusIcon =
                              Icons.check_circle_rounded;
                          break;
                        case 'on_hold':
                          statusColor = Colors.orange;
                          statusIcon =
                              Icons.pause_circle_filled_rounded;
                          break;
                        default:
                          statusColor = AppColors.warning;
                          statusIcon =
                              Icons.access_time_rounded;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius:
                              BorderRadius.circular(12),
                          border:
                              Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            // Queue number
                            Container(
                              width: 52,
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 6),
                              decoration: BoxDecoration(
                                color: deptColor.withValues(
                                    alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Text(
                                e.queueNumber
                                    .split('-')
                                    .last,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: deptColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Patient info
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.patientName,
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w800,
                                      color: titleColor,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${e.assignedDoctor ?? 'No doctor'} • ${e.purpose}',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 11.5,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Status
                            Icon(statusIcon,
                                size: 18,
                                color: statusColor),
                            const SizedBox(width: 6),
                            Text(
                              e.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Print
                            IconButton(
                              onPressed: () =>
                                  showQueueTicketPrintDialog(
                                context,
                                ticket: QueueTicketData(
                                  queueNumber:
                                      e.queueNumber,
                                  patientName:
                                      e.patientName,
                                  department:
                                      e.department,
                                  doctorName:
                                      e.assignedDoctor,
                                  roomName:
                                      e.assignedRoom,
                                  purpose: e.purpose,
                                  issuedAt:
                                      e.createdAt,
                                ),
                                isDark: isDark,
                              ),
                              icon: const Icon(
                                  Icons.print_rounded,
                                  size: 16),
                              tooltip: 'Print Slip',
                              padding: EdgeInsets.zero,
                              constraints:
                                  const BoxConstraints(),
                              color: AppColors.cyanCalm,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatToday() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String sublabel;
  final Gradient gradient;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.onTap,
  });
}

class _DeptFilterOption {
  final String key;
  final String label;
  final int count;
  final Color color;

  _DeptFilterOption(this.key, this.label, this.count, this.color);
}
