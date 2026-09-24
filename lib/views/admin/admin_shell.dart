import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/queue_provider.dart';
import '../../providers/theme_provider.dart';
import '../../shared/widgets/olof_logo.dart';
import 'admin_dashboard_screen.dart';
import 'admin_queue_screen.dart';
import 'admin_users_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_settings_screen.dart';

/// Desktop & Tablet layout shell for Clinic Admin Workstation
/// Formatted with official OLOF Logo and emerald clinic theme, uniform with Receptionist & Nurse stations.
class AdminShell extends StatefulWidget {
  final int initialTab;
  const AdminShell({super.key, this.initialTab = 0});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueProvider>().initialize();
      context.read<AdminProvider>().loadStaff();
      context.read<AdminProvider>().refreshStorageStats();
    });
  }

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    AdminQueueScreen(),
    AdminUsersScreen(),
    AdminReportsScreen(),
    AdminSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final queueProv = context.watch<QueueProvider>();
    final waitingCount = queueProv.todayQueue.where((e) => e.isWaiting || e.isOnHold).length;

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
              // ── Uniform Clinic Header (Matches Receptionist & Nurse) ──
              _buildTopAppBar(context, isDark, waitingCount),

              // ── Main Body (Sidebar + Content) ───────────────────────
              Expanded(
                child: Row(
                  children: [
                    // ── Emerald Clinic Navigation Sidebar ─────────────
                    _buildSidebar(context, isDark, waitingCount),

                    // ── Active Page View ──────────────────────────────
                    Expanded(
                      child: _pages[_currentIndex],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, bool isDark, int waitingCount) {
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Admin Operations Center',
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Queue Oversight, Doctor Allocation & Clinic Workstation',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Launch TV Display
          IconButton(
            icon: const Icon(Icons.tv_rounded, color: AppColors.cyanCalm),
            tooltip: 'Launch TV Queue Display Screen',
            onPressed: () => context.push('/display'),
          ),
          // Refresh Data
          IconButton(
            tooltip: 'Refresh Queue & Storage',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () {
              context.read<QueueProvider>().initialize(forceRefresh: true);
              context.read<AdminProvider>().refreshStorageStats();
            },
          ),
          // Theme Toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProv, _) => IconButton(
              icon: Icon(
                themeProv.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? AppColors.warning : AppColors.primary,
              ),
              tooltip: themeProv.isDarkMode ? 'Light Mode' : 'Dark Mode',
              onPressed: () => themeProv.toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, bool isDark, int waitingCount) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF064E3B), // emerald-900
                  const Color(0xFF022C22), // emerald-950
                ]
              : [
                  const Color(0xFFF0FDF4), // emerald-50
                  const Color(0xFFDCFCE7), // emerald-100
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
          // Sidebar Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: 'Executive Overview',
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.meeting_room_rounded,
                  label: 'Queue & Rooms',
                  badge: waitingCount > 0 ? '$waitingCount' : null,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.people_alt_rounded,
                  label: 'Staff & Doctors',
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.assessment_rounded,
                  label: 'Clinical Reports',
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.storage_rounded,
                  label: 'Local Storage & Backup',
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Sidebar Footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.25),
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0),
                ),
              ),
            ),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Exit to Stations', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                side: BorderSide(
                  color: isDark ? const Color(0xFF065F46) : const Color(0xFF86EFAC),
                ),
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
    String? badge,
  }) {
    final isSelected = _currentIndex == index;
    final activeColor = AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _currentIndex = index),
          hoverColor: Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46)),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
