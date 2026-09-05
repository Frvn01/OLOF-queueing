import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/patient_provider.dart';
import '../../providers/queue_provider.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../shared/widgets/tutorial_dialog.dart';
import '../../providers/theme_provider.dart';
import 'widgets/clinic_management_dialog.dart';

/// Receptionist Dashboard — main hub for registration and check-in
class ReceptionistScreen extends StatefulWidget {
  const ReceptionistScreen({super.key});

  @override
  State<ReceptionistScreen> createState() => _ReceptionistScreenState();
}

class _ReceptionistScreenState extends State<ReceptionistScreen> {
  final TextEditingController _searchController = TextEditingController();

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
                      _buildRecentRegistrations(context, isDark),
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
          // Doctors & Rooms Setup Button
          IconButton(
            icon: const Icon(Icons.medical_services_outlined, color: AppColors.primary),
            tooltip: 'Manage Doctors & Rooms',
            onPressed: () => showClinicManagementDialog(context, isDark: isDark),
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
        icon: Icons.medical_services_rounded,
        label: 'Doctors & Rooms',
        sublabel: 'Add & manage clinic staff & rooms',
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => showClinicManagementDialog(context, isDark: isDark),
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

    if (screenWidth >= 1100) {
      return Row(
        children: [
          Expanded(child: _buildActionCard(context, actions[0], isDark)),
          const SizedBox(width: 14),
          Expanded(child: _buildActionCard(context, actions[1], isDark)),
          const SizedBox(width: 14),
          Expanded(child: _buildActionCard(context, actions[2], isDark)),
          const SizedBox(width: 14),
          Expanded(child: _buildActionCard(context, actions[3], isDark)),
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
          Row(
            children: [
              Expanded(child: _buildActionCard(context, actions[2], isDark)),
              const SizedBox(width: 14),
              Expanded(child: _buildActionCard(context, actions[3], isDark)),
            ],
          ),
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
        const SizedBox(height: 12),
        _buildActionCard(context, actions[3], isDark),
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
            TextField(
              controller: _searchController,
              onChanged: (v) => provider.search(v),
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'Search by patient name or OLOF ID...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          provider.search('');
                        },
                        icon: const Icon(Icons.clear_rounded),
                      )
                    : null,
              ),
            ),
            if (provider.searchResults.isNotEmpty) ...[
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
    final waiting = stats['waiting'] ?? 0;
    final serving = stats['serving'] ?? 0;
    final completed = stats['completed'] ?? 0;
    final total = stats['total'] ?? 0;

    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
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
              _buildMiniStat('Waiting', waiting, AppColors.warning, isDark),
              _buildMiniStat('Serving', serving, AppColors.nowServing, isDark),
              _buildMiniStat('Done', completed, AppColors.success, isDark),
            ],
          ),
        ],
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

  Widget _buildRecentRegistrations(BuildContext context, bool isDark) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Consumer<PatientProvider>(
      builder: (context, provider, _) {
        final recent = provider.patients.reversed.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Registrations',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
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
                    Icon(
                      Icons.people_outline_rounded,
                      size: 40,
                      color: subtitleColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No patients registered yet today',
                      style: TextStyle(
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/receptionist/register'),
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Register First Patient'),
                    ),
                  ],
                ),
              )
            else
              ...recent.map(
                (patient) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 2),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        patient.firstName.isNotEmpty
                            ? patient.firstName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: AppColors.primary,
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
                        color: subtitleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: subtitleColor,
                      size: 20,
                    ),
                    onTap: () =>
                        context.go('/receptionist/patient/${patient.id}'),
                  ),
                ),
              ),
          ],
        );
      },
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
