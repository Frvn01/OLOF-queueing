import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../providers/theme_provider.dart';

/// Landing screen — Adaptive Station Selector
/// - Desktop (Windows/macOS/Linux): Unlocks the TV Queue Display (from Web)
///   while keeping Receptionist and Secretary locked for future updates.
/// - Mobile / Tablet: Unlocks Receptionist and Secretary staff kiosks.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool get isDesktopPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showLockedStationDialog(
      BuildContext context, String roleName, bool isDark) {
    final titleColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_clock_rounded,
                  color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$roleName Station Locked',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The $roleName module is currently locked on Desktop for future updates.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Staff operations for $roleName are optimized for clinic Mobile & Tablet kiosk devices.\n\nOn Desktop, you can launch the Public TV Queue Display for waiting lobby monitors.',
              style: TextStyle(
                fontSize: 13,
                color: subtitleColor,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final isLandscape = mq.orientation == Orientation.landscape;
    final isDesktop = isDesktopPlatform;
    final isWide = screenWidth > 680 || isLandscape;
    final isCompact = screenWidth < 400 && !isLandscape;

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
              // Top Action Row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Platform badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceMid
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.surfaceLight
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDesktop
                                ? Icons.desktop_windows_rounded
                                : Icons.tablet_android_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.primarySoft
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isDesktop ? 'DESKTOP APP' : 'STAFF KIOSK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? AppColors.primarySoft
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Theme toggle button
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceMid
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.surfaceLight
                              : AppColors.lightBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: isDark
                              ? AppColors.warning
                              : AppColors.brandBlue,
                        ),
                        tooltip: isDark
                            ? 'Switch to Eye-Comfort Light'
                            : 'Switch to Eye-Comfort Dark',
                        onPressed: () => themeProv.toggleTheme(),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 16 : 24,
                        vertical: isLandscape ? 8 : (isCompact ? 12 : 24),
                      ),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: isDesktop ? 760 : 680),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Clinic Logo & Branding
                            _buildBranding(isDark, isCompact, isLandscape),
                            SizedBox(
                                height: isLandscape
                                    ? 12
                                    : (isCompact ? 20 : 28)),

                            // ──────────────────────────────────────────
                            // DESKTOP LAYOUT vs MOBILE / TABLET LAYOUT
                            // ──────────────────────────────────────────
                            if (isDesktop)
                              _buildDesktopStations(
                                  context, isDark, isWide, isCompact)
                            else
                              _buildMobileStations(
                                  context, isDark, isWide, isCompact),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Desktop Station Layout:
  /// - TV Queue Display (what is on Web) unlocked and prominent
  /// - Receptionist and Secretary locked for future updates
  Widget _buildDesktopStations(
    BuildContext context,
    bool isDark,
    bool isWide,
    bool isCompact,
  ) {
    return Column(
      children: [
        // Live TV Display Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'LIVE TV QUEUE DISPLAY (WEB VIEW)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.success : AppColors.success,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Featured TV Display Card (Unlocked)
        _buildFeaturedTvDisplayCard(context, isDark: isDark),

        const SizedBox(height: 24),

        // Locked Staff Stations Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'STAFF KIOSK MODULES (MOBILE & TABLET EXCLUSIVE)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Receptionist, Ophtha Dept & Nurse (LOCKED on Desktop)
        if (isWide)
          Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  context,
                  isDark: isDark,
                  icon: Icons.person_add_rounded,
                  title: 'Receptionist',
                  subtitle: 'Register patients, scan QR & issue tickets',
                  gradient: AppColors.primaryGradient,
                  route: '/receptionist',
                  isLocked: true,
                  badgeText: 'LOCKED • FUTURE UPDATES',
                  onLockedTap: () =>
                      _showLockedStationDialog(context, 'Receptionist', isDark),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRoleCard(
                  context,
                  isDark: isDark,
                  icon: Icons.visibility_rounded,
                  title: 'Ophtha Dept',
                  subtitle:
                      'Ophthalmology queue, call patients & assign rooms',
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.cyanCalm,
                      Color(0xFF0F766E),
                    ],
                  ),
                  route: '/secretary',
                  isLocked: true,
                  badgeText: 'LOCKED • FUTURE UPDATES',
                  onLockedTap: () =>
                      _showLockedStationDialog(context, 'Ophtha Dept', isDark),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRoleCard(
                  context,
                  isDark: isDark,
                  icon: Icons.medical_information_rounded,
                  title: 'Nurse',
                  subtitle: 'Patient triage, vitals & clinical assistance',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  route: '/nurse',
                  isLocked: true,
                  badgeText: 'COMING SOON',
                  onLockedTap: () =>
                      _showLockedStationDialog(context, 'Nurse', isDark),
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildRoleCard(
                context,
                isDark: isDark,
                icon: Icons.person_add_rounded,
                title: 'Receptionist',
                subtitle: 'Register patients, scan QR & issue tickets',
                gradient: AppColors.primaryGradient,
                route: '/receptionist',
                isLocked: true,
                badgeText: 'LOCKED • FUTURE UPDATES',
                onLockedTap: () =>
                    _showLockedStationDialog(context, 'Receptionist', isDark),
              ),
              const SizedBox(height: 12),
              _buildRoleCard(
                context,
                isDark: isDark,
                icon: Icons.visibility_rounded,
                title: 'Ophtha Dept',
                subtitle:
                    'Ophthalmology queue, call patients & assign rooms',
                gradient: const LinearGradient(
                  colors: [
                    AppColors.cyanCalm,
                    Color(0xFF0F766E),
                  ],
                ),
                route: '/secretary',
                isLocked: true,
                badgeText: 'LOCKED • FUTURE UPDATES',
                onLockedTap: () =>
                    _showLockedStationDialog(context, 'Ophtha Dept', isDark),
              ),
              const SizedBox(height: 12),
              _buildRoleCard(
                context,
                isDark: isDark,
                icon: Icons.medical_information_rounded,
                title: 'Nurse',
                subtitle: 'Patient triage, vitals & clinical assistance',
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                route: '/nurse',
                isLocked: true,
                badgeText: 'COMING SOON',
                onLockedTap: () =>
                    _showLockedStationDialog(context, 'Nurse', isDark),
              ),
            ],
          ),

        const SizedBox(height: 12),
        Text(
          'Staff stations are reserved for mobile/tablet kiosks. Desktop support will be enabled in future updates.',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textDisabled
                : AppColors.lightTextDisabled,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Mobile & Tablet Station Layout (Exclusive):
  /// - Receptionist and Secretary unlocked as staff kiosks
  /// - No TV Display (mobile is exclusively for staff operations)
  Widget _buildMobileStations(
    BuildContext context,
    bool isDark,
    bool isWide,
    bool isCompact,
  ) {
    return Column(
      children: [
        // Role Selection Header
        Text(
          'SELECT STAFF STATION',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: isDark
                ? AppColors.textSecondary
                : AppColors.lightTextSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        if (isWide) ...[
          Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  context,
                  isDark: isDark,
                  icon: Icons.person_add_rounded,
                  title: 'Receptionist',
                  subtitle: 'Register patients, scan QR & issue tickets',
                  gradient: AppColors.primaryGradient,
                  route: '/receptionist',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRoleCard(
                  context,
                  isDark: isDark,
                  icon: Icons.visibility_rounded,
                  title: 'Ophtha Dept',
                  subtitle: 'Ophthalmology queue, call patients & assign rooms',
                  gradient: const LinearGradient(
                    colors: [AppColors.cyanCalm, Color(0xFF0F766E)],
                  ),
                  route: '/secretary',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRoleCard(
            context,
            isDark: isDark,
            icon: Icons.medical_information_rounded,
            title: 'Nurse',
            subtitle: 'Patient triage, vitals & clinical assistance',
            gradient: const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            route: '/nurse',
            isLocked: true,
            badgeText: 'COMING SOON',
            onLockedTap: () =>
                _showLockedStationDialog(context, 'Nurse', isDark),
          ),
        ] else
          Column(
            children: [
              _buildRoleCard(
                context,
                isDark: isDark,
                icon: Icons.person_add_rounded,
                title: 'Receptionist',
                subtitle: 'Register patients, scan QR & issue tickets',
                gradient: AppColors.primaryGradient,
                route: '/receptionist',
              ),
              const SizedBox(height: 14),
              _buildRoleCard(
                context,
                isDark: isDark,
                icon: Icons.visibility_rounded,
                title: 'Ophtha Dept',
                subtitle: 'Ophthalmology queue, call patients & assign rooms',
                gradient: const LinearGradient(
                  colors: [AppColors.cyanCalm, Color(0xFF0F766E)],
                ),
                route: '/secretary',
              ),
              const SizedBox(height: 14),
              _buildRoleCard(
                context,
                isDark: isDark,
                icon: Icons.medical_information_rounded,
                title: 'Nurse',
                subtitle: 'Patient triage, vitals & clinical assistance',
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                route: '/nurse',
                isLocked: true,
                badgeText: 'COMING SOON',
                onLockedTap: () =>
                    _showLockedStationDialog(context, 'Nurse', isDark),
              ),
            ],
          ),

      ],
    );
  }

  /// Featured Live TV Queue Display Card (Desktop Unlocked)
  Widget _buildFeaturedTvDisplayCard(BuildContext context, {required bool isDark}) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.brandBlue.withValues(alpha: 0.6) : AppColors.primaryLight;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/display'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.tv_rounded, size: 34, color: Colors.white),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Public TV Queue Display',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 11, color: AppColors.success),
                              SizedBox(width: 4),
                              Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live full-screen waiting room monitor with doctor callouts & audio chime (Web version for Desktop)',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Launch',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(bool isDark, bool isCompact, bool isLandscape) {
    final logoSize = isLandscape ? 52.0 : (isCompact ? 72.0 : 88.0);
    final titleSize = isLandscape ? 17.0 : (isCompact ? 20.0 : 23.0);
    final subtitleSize = isLandscape ? 12.0 : (isCompact ? 13.0 : 14.5);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: isLandscape
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OlofLogo(size: logoSize, showBorder: true),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName.toUpperCase(),
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${AppConstants.clinicName} — ${AppConstants.clinicSubtitle}',
                        style: TextStyle(
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        AppConstants.clinicTagline,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.primarySoft
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                OlofLogo(size: logoSize, showBorder: true),
                const SizedBox(height: 14),
                Text(
                  AppConstants.appName.toUpperCase(),
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppConstants.clinicName} — ${AppConstants.clinicSubtitle}',
                  style: TextStyle(
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(
                  AppConstants.clinicTagline,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.primarySoft : AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required String route,
    bool isLocked = false,
    String? badgeText,
    VoidCallback? onLockedTap,
  }) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor =
        isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return MouseRegion(
      cursor: isLocked ? SystemMouseCursors.click : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLocked ? onLockedTap : () => context.go(route),
        child: Opacity(
          opacity: isLocked ? 0.72 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLocked
                    ? (isDark
                        ? AppColors.surfaceHover
                        : AppColors.lightBorderSoft)
                    : borderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: isDark ? (isLocked ? 0.1 : 0.25) : (isLocked ? 0.02 : 0.05)),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: isLocked
                            ? LinearGradient(
                                colors: [
                                  Colors.grey.shade600,
                                  Colors.grey.shade700,
                                ],
                              )
                            : gradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isLocked)
                            BoxShadow(
                              color: (gradient as LinearGradient)
                                  .colors
                                  .first
                                  .withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Icon(icon, size: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (isLocked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceLight
                            : AppColors.lightSurfaceMid,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.surfaceHover
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 11,
                            color: isDark
                                ? AppColors.warning
                                : AppColors.nowServingTextDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeText ?? 'LOCKED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? AppColors.warning
                                  : AppColors.nowServingTextDark,
                            ),
                          ),
                        ],
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
