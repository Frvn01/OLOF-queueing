import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/queue_provider.dart';
import '../../providers/theme_provider.dart';
import '../../shared/widgets/olof_logo.dart';

import 'doctor_dashboard_screen.dart';
import 'doctor_patients_screen.dart';
import 'doctor_queue_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_schedule_screen.dart';
import 'doctor_reports_screen.dart';
import 'doctor_profile_screen.dart';

class DoctorShell extends StatefulWidget {
  final int initialTab;

  const DoctorShell({super.key, this.initialTab = 0});

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  late int _currentTab;

  ImageProvider _getDoctorImageProvider(String path) {
    if (path.startsWith('data:image')) {
      final base64Str = path.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (!kIsWeb) {
      return FileImage(File(path));
    }
    return NetworkImage(path);
  }

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueProvider>().initialize();
      context.read<DoctorProvider>().loadPatients();
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctorProv = context.watch<DoctorProvider>();
    final queueProv = context.watch<QueueProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final waitingCount = doctorProv.getAllWaitingPatients(queueProv.todayQueue).length;

    // Navigation item definitions matching DoctorSidebar.jsx
    final navItems = [
      _DoctorNavItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        subtitle: 'Overview & Queue',
      ),
      _DoctorNavItem(
        icon: Icons.people_alt_rounded,
        label: 'Patients',
        subtitle: 'Directory & Uploads',
      ),
      _DoctorNavItem(
        icon: Icons.assignment_rounded,
        label: 'Visit Queue',
        subtitle: 'Live Line ($waitingCount)',
        badgeCount: waitingCount,
      ),
      _DoctorNavItem(
        icon: Icons.calendar_month_rounded,
        label: 'Appointments',
        subtitle: 'Scheduled Visits',
      ),
      _DoctorNavItem(
        icon: Icons.schedule_rounded,
        label: 'My Schedule',
        subtitle: 'Weekly Availability',
      ),
      _DoctorNavItem(
        icon: Icons.analytics_rounded,
        label: 'Clinical Reports',
        subtitle: 'Metrics & Trends',
      ),
      _DoctorNavItem(
        icon: Icons.person_rounded,
        label: 'My Profile',
        subtitle: 'Doctor Information',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 720;

        if (isTablet) {
          // ── Tablet Kiosk Layout (Sidebar + Content) ──────────────
          return Scaffold(
            body: Row(
              children: [
                // ── Sleek Emerald Sidebar (from DoctorSidebar.jsx) ───
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF064E3B), // green-900
                              const Color(0xFF022C22), // green-950
                            ]
                          : [
                              const Color(0xFFF0FDF4), // green-50
                              const Color(0xFFDCFCE7), // green-100
                            ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(
                      right: BorderSide(
                        color: isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Sidebar Header with Stethoscope Icon
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.35),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const OlofLogo(size: 42, showBorder: true),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OLOF Clinic',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Doctor Tablet Kiosk',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Navigation Menu List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          itemCount: navItems.length,
                          itemBuilder: (context, i) {
                            final item = navItems[i];
                            final isActive = _currentTab == i;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _onTabSelected(i),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF059669) // green-600
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isActive
                                        ? Border.all(color: const Color(0xFF047857), width: 1.5)
                                        : null,
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF059669).withValues(alpha: 0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 22,
                                        color: isActive
                                            ? Colors.white
                                            : (isDark
                                                ? const Color(0xFF6EE7B7)
                                                : const Color(0xFF065F46)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: TextStyle(
                                            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 14,
                                            color: isActive
                                                ? Colors.white
                                                : (isDark
                                                    ? const Color(0xFFD1FAE5)
                                                    : const Color(0xFF064E3B)),
                                          ),
                                        ),
                                      ),
                                      if (item.badgeCount != null && item.badgeCount! > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isActive ? Colors.white : const Color(0xFF059669),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${item.badgeCount}',
                                            style: TextStyle(
                                              color: isActive ? const Color(0xFF059669) : Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Sidebar Footer with Active Doctor Profile
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.35),
                          border: Border(
                            top: BorderSide(
                              color: isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0),
                            ),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _onTabSelected(6), // Profile tab
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isDark ? const Color(0xFF065F46) : const Color(0xFFDCFCE7))
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF059669),
                                  backgroundImage: (doctorProv.photoUrl != null && doctorProv.photoUrl!.isNotEmpty)
                                      ? _getDoctorImageProvider(doctorProv.photoUrl!)
                                      : null,
                                  child: (doctorProv.photoUrl != null && doctorProv.photoUrl!.isNotEmpty)
                                      ? null
                                      : Text(
                                          doctorProv.activeDoctor.isNotEmpty
                                              ? doctorProv.activeDoctor
                                                  .replaceAll('Dr. ', '')
                                                  .replaceAll('DR. ', '')
                                                  .trim()[0]
                                              : 'D',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctorProv.formattedDoctorName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isDark ? Colors.white : const Color(0xFF064E3B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${doctorProv.activeDepartment} • ${doctorProv.activeRoom}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark
                                              ? const Color(0xFF6EE7B7)
                                              : const Color(0xFF059669),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout_rounded, size: 18),
                                  tooltip: 'Exit to Kiosk Portal',
                                  color: isDark ? Colors.white70 : const Color(0xFF065F46),
                                  onPressed: () => context.go('/'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Right Main Content Area ──────────────────────────
                Expanded(
                  child: IndexedStack(
                    index: _currentTab,
                    children: [
                      DoctorDashboardScreen(onNavigateTab: _onTabSelected),
                      const DoctorPatientsScreen(),
                      const DoctorQueueScreen(),
                      const DoctorAppointmentsScreen(),
                      const DoctorScheduleScreen(),
                      const DoctorReportsScreen(),
                      const DoctorProfileScreen(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // ── Mobile / Compact Layout ──────────────────────────────────
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.lightSurface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
                    width: 1.5,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      ),
                      tooltip: 'Back to Station Selector',
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 2),
                    const OlofLogo(size: 34, showBorder: true),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Doctor Clinical Kiosk',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF059669), Color(0xFF047857)],
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'DOCTOR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${doctorProv.formattedDoctorName} • ${doctorProv.activeDepartment} (${doctorProv.activeRoom})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                      tooltip: 'Refresh Queue',
                      onPressed: () => queueProv.initialize(forceRefresh: true),
                    ),
                    Consumer<ThemeProvider>(
                      builder: (context, tp, _) => IconButton(
                        icon: Icon(
                          tp.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: isDark ? AppColors.warning : AppColors.primary,
                        ),
                        onPressed: () => tp.toggleTheme(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: IndexedStack(
            index: _currentTab,
            children: [
              DoctorDashboardScreen(onNavigateTab: _onTabSelected),
              const DoctorPatientsScreen(),
              const DoctorQueueScreen(),
              const DoctorAppointmentsScreen(),
              const DoctorScheduleScreen(),
              const DoctorReportsScreen(),
              const DoctorProfileScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentTab >= 5 ? 0 : _currentTab,
            onDestinationSelected: (idx) {
              if (idx == 4) {
                // Show more bottom sheet for Schedule, Reports, Profile
                _showMoreOptionsSheet(context);
              } else {
                _onTabSelected(idx);
              }
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              const NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_alt_rounded),
                label: 'Patients',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: waitingCount > 0,
                  label: Text('$waitingCount'),
                  child: const Icon(Icons.assignment_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: waitingCount > 0,
                  label: Text('$waitingCount'),
                  child: const Icon(Icons.assignment_rounded),
                ),
                label: 'Queue',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Appts',
              ),
              const NavigationDestination(
                icon: Icon(Icons.more_horiz_rounded),
                selectedIcon: Icon(Icons.more_horiz_rounded),
                label: 'More',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoreOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.schedule_rounded, color: Color(0xFF059669)),
                title: const Text('My Schedule'),
                subtitle: const Text('Configure weekly availability'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onTabSelected(4);
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics_rounded, color: AppColors.primary),
                title: const Text('Clinical Reports'),
                subtitle: const Text('Stats & case summaries'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onTabSelected(5);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_rounded, color: Color(0xFF8B5CF6)),
                title: const Text('Doctor Profile'),
                subtitle: const Text('View & edit professional info'),
                onTap: () {
                  Navigator.pop(ctx);
                  _onTabSelected(6);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Exit Kiosk to Home'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorNavItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final int? badgeCount;

  _DoctorNavItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.badgeCount,
  });
}
