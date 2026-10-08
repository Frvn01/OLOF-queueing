import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../providers/theme_provider.dart';

// =============================================================================
// [PRODUCTION FEATURE - QR CODE SCANNER LOGIN]
// Staff QR code scanning authentication is preserved for production release.
// For Beta testing, QR scanning is commented out so staff can directly access
// their clinical stations on Desktop, Tablet Kiosk, and Mobile.
// To re-enable for production:
// 1. Uncomment the import below.
// 2. Uncomment the MobileKioskScanner widget / QR hero card calls.
// =============================================================================
// import 'widgets/mobile_kiosk_scanner.dart';

/// Landing / Staff Station Access Hub
/// Fully responsive across Desktop Workstations, Tablet Kiosks, and Mobile devices.
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
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final isLandscape = mq.orientation == Orientation.landscape;

    // Responsive form-factor thresholds
    // Platform guard: Android/iOS are never desktop — only Windows/macOS/Linux/Web can be desktop.
    final isMobilePlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    // On mobile platforms, screen height < 800 in portrait means phone (not tablet)
    final screenHeight = mq.size.height;
    final isPhoneSize = isMobilePlatform &&
        (screenWidth < 640 || (screenWidth < 960 && screenHeight < 800));

    final isDesktopWidth = !isMobilePlatform && screenWidth >= 1024;
    final isTabletKiosk = !isPhoneSize &&
        !isDesktopWidth &&
        (screenWidth >= 640 || isMobilePlatform) &&
        screenWidth < 1024;
    final isMobile = isPhoneSize || (!isDesktopWidth && !isTabletKiosk);

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
              // Top Action / Status Bar
              _buildTopBar(
                context,
                isDark: isDark,
                isDesktopWidth: isDesktopWidth,
                isTabletKiosk: isTabletKiosk,
                isMobile: isMobile,
                themeProv: themeProv,
              ),

              // Main Scrollable Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : (isTabletKiosk ? 24 : 32),
                        vertical: isMobile ? 12 : 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktopWidth ? 1120 : (isTabletKiosk ? 860 : 540),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Clinic Logo & Hero Branding
                            _buildHeroHeader(
                              isDark: isDark,
                              isMobile: isMobile,
                              isLandscape: isLandscape,
                            ),
                            SizedBox(height: isMobile ? 18 : 28),

                            // Section 1: Clinical Workstations
                            _buildSectionHeader(
                              icon: Icons.domain_verification_rounded,
                              title: 'CLINICAL WORKSTATIONS',
                              subtitle: isMobile
                                  ? 'Consultation rooms, triage & desk stations'
                                  : 'Direct staff access to active consultation rooms, triage & ticket stations',
                              isDark: isDark,
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 12),

                            // Clinical Workstations Responsive Grid / List
                            _buildClinicalWorkstations(
                              context,
                              isDark: isDark,
                              isDesktopWidth: isDesktopWidth,
                              isTabletKiosk: isTabletKiosk,
                              isMobile: isMobile,
                            ),
                            SizedBox(height: isMobile ? 22 : 30),

                            // Section 2: Public Displays & Management
                            // Hidden on mobile kiosk — only visible on desktop & tablet
                            if (!isMobile) ...[
                              _buildSectionHeader(
                                icon: Icons.connected_tv_rounded,
                                title: 'DISPLAYS & CLINIC OPERATIONS',
                                subtitle: isDesktopWidth
                                    ? 'Waiting room public queue monitor and administrative workstation oversight'
                                    : 'Waiting room TV and admin oversight',
                                isDark: isDark,
                                isMobile: false,
                              ),
                              const SizedBox(height: 12),

                              // Public TV & Admin Workstation Responsive Cards
                              _buildOperationsWorkstations(
                                context,
                                isDark: isDark,
                                isDesktopWidth: isDesktopWidth,
                                isTabletKiosk: isTabletKiosk,
                                isMobile: false,
                              ),
                              SizedBox(height: isTabletKiosk ? 24 : 28),
                            ],

                            // Bottom Utilities & Footer
                            _buildFooterUtilities(
                              context,
                              isDark: isDark,
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 12),
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

  // ===========================================================================
  // TOP BAR
  // ===========================================================================
  Widget _buildTopBar(
    BuildContext context, {
    required bool isDark,
    required bool isDesktopWidth,
    required bool isTabletKiosk,
    required bool isMobile,
    required ThemeProvider themeProv,
  }) {
    String deviceLabel;
    IconData deviceIcon;

    if (isDesktopWidth) {
      deviceLabel = 'DESKTOP WORKSTATION';
      deviceIcon = Icons.desktop_windows_rounded;
    } else if (isTabletKiosk) {
      deviceLabel = 'KIOSK TERMINAL';
      deviceIcon = Icons.tablet_android_rounded;
    } else {
      deviceLabel = 'STAFF MOBILE';
      deviceIcon = Icons.smartphone_rounded;
    }

    final barBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : AppColors.lightSurface)
            .withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: borderColor.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Platform & System Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: barBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  deviceIcon,
                  size: 14,
                  color: isDark ? AppColors.primarySoft : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  deviceLabel,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.primarySoft : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 5),
                  Text(
                    'ONLINE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right Actions: TV Display shortcut (desktop/tablet only), Theme toggle
          Row(
            children: [
              // TV Display Quick Launcher — hidden on mobile kiosk
              if (!isMobile) ...[
                OutlinedButton.icon(
                  onPressed: () => context.go('/display'),
                  icon: const Icon(Icons.tv_rounded, size: 14),
                  label: const Text(
                    'TV Display',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? const Color(0xFF10B981)
                        : const Color(0xFF059669),
                    side: BorderSide(
                      color: (isDark
                              ? const Color(0xFF10B981)
                              : const Color(0xFF059669))
                          .withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Eye-Comfort Dark/Light Toggle
              Container(
                decoration: BoxDecoration(
                  color: barBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  padding: const EdgeInsets.all(6),
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: isDark ? AppColors.warning : AppColors.brandBlue,
                  ),
                  tooltip: isDark
                      ? 'Switch to Eye-Comfort Light'
                      : 'Switch to Eye-Comfort Dark',
                  onPressed: () => themeProv.toggleTheme(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HERO BRANDING
  // ===========================================================================
  Widget _buildHeroHeader({
    required bool isDark,
    required bool isMobile,
    required bool isLandscape,
  }) {
    final logoSize = isMobile ? 64.0 : 80.0;
    final titleSize = isMobile ? 20.0 : 26.0;
    final subtitleSize = isMobile ? 12.5 : 14.5;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo with halo glow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.2),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: OlofLogo(size: logoSize, showBorder: true),
          ),
          SizedBox(height: isMobile ? 10 : 14),

          // Main App Name
          Text(
            AppConstants.appName.toUpperCase(),
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Clinic Name & Subtitle
          Text(
            '${AppConstants.clinicName} — ${AppConstants.clinicSubtitle}',
            style: TextStyle(
              fontSize: subtitleSize,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),

          // Tagline Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primary : AppColors.primary)
                  .withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
              ),
            ),
            child: Text(
              AppConstants.clinicTagline,
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.primarySoft : AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION HEADER
  // ===========================================================================
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required bool isMobile,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.cyanCalm : AppColors.primary)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: isMobile ? 14 : 16,
            color: isDark ? AppColors.cyanLight : AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 11.5 : 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 10.5 : 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CLINICAL WORKSTATIONS GRID / LIST
  // ===========================================================================
  Widget _buildClinicalWorkstations(
    BuildContext context, {
    required bool isDark,
    required bool isDesktopWidth,
    required bool isTabletKiosk,
    required bool isMobile,
  }) {
    final stations = [
      _StationData(
        title: 'Doctor',
        roleBadge: 'ROOMS 1–3',
        subtitle: 'Consultations, patient symptoms, vitals & drawings',
        icon: Icons.medical_services_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFF059669),
        route: '/doctor',
      ),
      _StationData(
        title: 'Nurse',
        roleBadge: 'TRIAGE & VITALS',
        subtitle: 'Patient triage, vital signs & clinical eye/ENT drawings',
        icon: Icons.medical_information_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFFEC4899),
        route: '/nurse',
      ),
      _StationData(
        title: 'Receptionist',
        roleBadge: 'TICKETS & QR',
        subtitle: 'Register patients, scan QR & issue printed queue tickets',
        icon: Icons.person_add_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFF0284C7),
        route: '/receptionist',
      ),
      _StationData(
        title: 'Ophtha Dept',
        roleBadge: 'SPECIALIST DEPT',
        subtitle: 'Ophthalmology queue, call patients & assign exam rooms',
        icon: Icons.visibility_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFF0D9488),
        route: '/secretary',
      ),
    ];

    // Mobile Phone Layout: Ergonomic horizontal cards
    if (isMobile) {
      return Column(
        children: stations.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StationListTile(
              data: s,
              isDark: isDark,
              onTap: () => _navigateTo(context, s.route),
            ),
          );
        }).toList(),
      );
    }

    // Tablet / Kiosk Layout: 2x2 Grid with touch-friendly cards
    if (isTabletKiosk) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StationGridCard(
                  data: stations[0],
                  isDark: isDark,
                  onTap: () => _navigateTo(context, stations[0].route),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StationGridCard(
                  data: stations[1],
                  isDark: isDark,
                  onTap: () => _navigateTo(context, stations[1].route),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StationGridCard(
                  data: stations[2],
                  isDark: isDark,
                  onTap: () => _navigateTo(context, stations[2].route),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StationGridCard(
                  data: stations[3],
                  isDark: isDark,
                  onTap: () => _navigateTo(context, stations[3].route),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Desktop Layout: 4 Cards in a balanced row
    return Row(
      children: stations.map((s) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: s == stations.last ? 0 : 16,
            ),
            child: _StationGridCard(
              data: s,
              isDark: isDark,
              onTap: () => _navigateTo(context, s.route),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // OPERATIONS & PUBLIC DISPLAYS (TV DISPLAY & ADMIN WORKSTATION)
  // ===========================================================================
  Widget _buildOperationsWorkstations(
    BuildContext context, {
    required bool isDark,
    required bool isDesktopWidth,
    required bool isTabletKiosk,
    required bool isMobile,
  }) {
    final tvCard = _OperationsCard(
      title: 'Public TV Queue Display',
      badgeText: 'LIVE SCREEN',
      badgeColor: AppColors.success,
      subtitle:
          'Live full-screen waiting room monitor with doctor callouts & audio chime for waiting patients.',
      actionText: 'Launch TV Display',
      icon: Icons.tv_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFF0284C7),
      isDark: isDark,
      isMobile: isMobile,
      onTap: () => _navigateTo(context, '/display'),
    );

    final adminCard = _OperationsCard(
      title: 'Admin Workstation',
      badgeText: 'QR REQUIRED',
      badgeColor: const Color(0xFFD97706),
      subtitle:
          'Room-by-room doctor oversight, staff management & reports. Super-admin QR badge required.',
      actionText: 'Scan QR to Unlock',
      icon: Icons.admin_panel_settings_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF065F46), Color(0xFF0D9488)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      accentColor: const Color(0xFF059669),
      isDark: isDark,
      isMobile: isMobile,
      // Admin strictly requires Master Super Admin QR — pass role hint to enforce strict auth
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/auth/qr-login?role=super_admin');
      },
    );

    // Desktop: 2 Cards side-by-side
    if (isDesktopWidth) {
      return Row(
        children: [
          Expanded(child: tvCard),
          const SizedBox(width: 16),
          Expanded(child: adminCard),
        ],
      );
    }

    // Kiosk Tablet & Mobile: Stacked cards
    return Column(
      children: [
        tvCard,
        const SizedBox(height: 12),
        adminCard,
      ],
    );
  }

  // ===========================================================================
  // FOOTER UTILITIES & CLINIC INFO
  // ===========================================================================
  Widget _buildFooterUtilities(
    BuildContext context, {
    required bool isDark,
    required bool isMobile,
  }) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Column(
      children: [
        // Quick Action Badges — hidden on mobile kiosk
        if (!isMobile)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              // Queue Archive & Logs
              ActionChip(
                avatar: const Icon(Icons.history_rounded, size: 16),
                label: const Text('Queue Archive & History'),
                backgroundColor: cardBg,
                side: BorderSide(color: borderColor),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
                onPressed: () => context.push('/archive'),
              ),
            ],
          ),
        if (!isMobile) const SizedBox(height: 16),

        // Clinic Copyright & Tagline
        Text(
          '© ${DateTime.now().year} ${AppConstants.clinicName} — All Rights Reserved',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textDisabled : AppColors.lightTextDisabled,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _navigateTo(BuildContext context, String route) {
    HapticFeedback.lightImpact();
    context.go(route);
  }
}

// =============================================================================
// DATA MODEL FOR CLINICAL STATIONS
// =============================================================================
class _StationData {
  final String title;
  final String roleBadge;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color accentColor;
  final String route;

  const _StationData({
    required this.title,
    required this.roleBadge,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.route,
  });
}

// =============================================================================
// GRID CARD (FOR DESKTOP & TABLET KIOSK)
// =============================================================================
class _StationGridCard extends StatefulWidget {
  final _StationData data;
  final bool isDark;
  final VoidCallback onTap;

  const _StationGridCard({
    required this.data,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_StationGridCard> createState() => _StationGridCardState();
}

class _StationGridCardState extends State<_StationGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isDark = widget.isDark;

    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final defaultBorder = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final hoverBorder = d.accentColor.withValues(alpha: isDark ? 0.8 : 0.6);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? hoverBorder : defaultBorder,
              width: _isHovered ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? d.accentColor.withValues(alpha: isDark ? 0.3 : 0.16)
                    : Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: _isHovered ? 22 : 14,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Icon Container & Role Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container with jewel gradient
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: d.gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: d.accentColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(d.icon, size: 28, color: Colors.white),
                  ),

                  // Role badge pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: d.accentColor.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: d.accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      d.roleBadge,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: d.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Station Title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  d.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 5),

              // Description
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  d.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),

              // Enter Station Action Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceLight : AppColors.lightSurfaceMid)
                      .withValues(alpha: _isHovered ? 1.0 : 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isHovered
                        ? d.accentColor.withValues(alpha: 0.4)
                        : (isDark ? AppColors.surfaceLight : AppColors.lightBorderSoft),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enter Station',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _isHovered
                            ? d.accentColor
                            : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: _isHovered
                          ? d.accentColor
                          : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
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
}

// =============================================================================
// LIST TILE (FOR MOBILE SCREENS)
// =============================================================================
class _StationListTile extends StatelessWidget {
  final _StationData data;
  final bool isDark;
  final VoidCallback onTap;

  const _StationListTile({
    required this.data,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: data.gradient,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: data.accentColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(data.icon, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 14),

              // Title & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          data.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: data.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data.roleBadge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: data.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Arrow
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceMid,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: data.accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// OPERATIONS CARD (PUBLIC TV DISPLAY & ADMIN WORKSTATION)
// =============================================================================
class _OperationsCard extends StatefulWidget {
  final String title;
  final String badgeText;
  final Color badgeColor;
  final String subtitle;
  final String actionText;
  final IconData icon;
  final Gradient gradient;
  final Color accentColor;
  final bool isDark;
  final bool isMobile;
  final VoidCallback onTap;

  const _OperationsCard({
    required this.title,
    required this.badgeText,
    required this.badgeColor,
    required this.subtitle,
    required this.actionText,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.isDark,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_OperationsCard> createState() => _OperationsCardState();
}

class _OperationsCardState extends State<_OperationsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isMobile = widget.isMobile;

    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final defaultBorder = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final hoverBorder = widget.accentColor.withValues(alpha: isDark ? 0.8 : 0.6);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? hoverBorder : defaultBorder,
              width: _isHovered ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.accentColor.withValues(alpha: isDark ? 0.3 : 0.16)
                    : Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: _isHovered ? 20 : 14,
                offset: Offset(0, _isHovered ? 7 : 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: isMobile ? 48 : 56,
                height: isMobile ? 48 : 56,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  size: isMobile ? 26 : 30,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),

              // Title, Badge & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: isMobile ? 15 : 17,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: widget.badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: widget.badgeColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            widget.badgeText,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: widget.badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary,
                        height: 1.3,
                      ),
                      maxLines: isMobile ? 2 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Action Affordance
              if (!isMobile)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.actionText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceLight
                        : AppColors.lightSurfaceMid,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: widget.accentColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
