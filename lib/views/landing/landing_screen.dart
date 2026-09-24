import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../providers/theme_provider.dart';
import 'widgets/mobile_kiosk_scanner.dart';

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
  Widget _buildDesktopStations(
    BuildContext context,
    bool isDark,
    bool isWide,
    bool isCompact,
  ) {
    return Column(
      children: [
        // Staff QR Code Login Hero Card
        _buildQrLoginHeroCard(context, isDark: isDark),

        const SizedBox(height: 18),

        // Featured Admin Desktop Workstation Card (QR / PIN Protected)
        _buildFeaturedAdminCard(context, isDark: isDark),

        const SizedBox(height: 18),

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

        // Featured TV Display Card (Unlocked for Waiting Area)
        _buildFeaturedTvDisplayCard(context, isDark: isDark),

        const SizedBox(height: 24),

        // Clinical & Staff Stations Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_2_rounded,
              size: 16,
              color: Color(0xFF0D9488),
            ),
            const SizedBox(width: 6),
            Text(
              'CLINICAL & STAFF WORKSTATIONS (QR AUTHENTICATED)',
              style: TextStyle(
                fontSize: 12,
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

        // Desktop Stations Grid
        if (isWide)
          Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  context,
                  isDark: isDark,
                  icon: Icons.medical_services_rounded,
                  title: 'Doctor',
                  subtitle: 'Consultations, patient symptoms & nurse drawings',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                  ),
                  route: '/auth/qr-login?role=Doctor',
                  badgeText: 'QR SCAN',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRoleCard(
                  context,
                  isDark: isDark,
                  icon: Icons.medical_information_rounded,
                  title: 'Nurse',
                  subtitle: 'Patient triage, vitals & clinical drawings',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                  ),
                  route: '/auth/qr-login?role=Nurse',
                  badgeText: 'QR SCAN',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRoleCard(
                  context,
                  isDark: isDark,
                  icon: Icons.person_add_rounded,
                  title: 'Receptionist',
                  subtitle: 'Register patients, scan QR & issue tickets',
                  gradient: AppColors.primaryGradient,
                  route: '/auth/qr-login?role=Receptionist',
                  badgeText: 'QR SCAN',
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
                  route: '/auth/qr-login?role=Ophtha',
                  badgeText: 'QR SCAN',
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
                icon: Icons.medical_services_rounded,
                title: 'Doctor',
                subtitle: 'Consultations, patient symptoms & nurse drawings',
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                route: '/auth/qr-login?role=Doctor',
                badgeText: 'QR SCAN',
              ),
              const SizedBox(height: 12),
              _buildRoleCard(
                context,
                isDark: isDark,
                icon: Icons.medical_information_rounded,
                title: 'Nurse',
                subtitle: 'Patient triage, vitals & clinical drawings',
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                ),
                route: '/auth/qr-login?role=Nurse',
                badgeText: 'QR SCAN',
              ),
              const SizedBox(height: 12),
              _buildRoleCard(
                context,
                isDark: isDark,
                icon: Icons.person_add_rounded,
                title: 'Receptionist',
                subtitle: 'Register patients, scan QR & issue tickets',
                gradient: AppColors.primaryGradient,
                route: '/auth/qr-login?role=Receptionist',
                badgeText: 'QR SCAN',
              ),
              const SizedBox(height: 12),
              _buildRoleCard(
                context,
                isDark: isDark,
                icon: Icons.visibility_rounded,
                title: 'Ophtha Dept',
                subtitle: 'Ophthalmology queue, call patients & assign rooms',
                gradient: const LinearGradient(
                  colors: [AppColors.cyanCalm, Color(0xFF0F766E)],
                ),
                route: '/auth/qr-login?role=Ophtha',
                badgeText: 'QR SCAN',
              ),
            ],
          ),
      ],
    );
  }

  /// Staff QR Code Login Hero Banner Card
  Widget _buildQrLoginHeroCard(BuildContext context, {required bool isDark}) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark
        ? const Color(0xFF059669).withValues(alpha: 0.5)
        : const Color(0xFF059669).withValues(alpha: 0.35);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        color: cardBg,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/auth/qr-login'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded,
                      size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Staff QR Code Login',
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
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACCESS GATE',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Scan your physical staff QR badge or enter your 4-digit PIN to enter your station.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => context.push('/auth/qr-login'),
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Scan QR / PIN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mobile & Tablet Station Layout (Exclusive Staff Kiosk):
  Widget _buildMobileStations(
    BuildContext context,
    bool isDark,
    bool isWide,
    bool isCompact,
  ) {
    return MobileKioskScanner(isDark: isDark);
  }

  /// Featured Admin Desktop Workstation Card (Clinic PC)
  Widget _buildFeaturedAdminCard(BuildContext context, {required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.push('/auth/qr-login?role=Admin'),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                const OlofLogo(size: 56, showBorder: true),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Admin Desktop Workstation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'QR / PIN AUTH',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Room-by-room doctor oversight (Serving, Next, Waiting), staff management, local storage & reports',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
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
                if (badgeText != null || isLocked)
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
                            isLocked
                                ? Icons.lock_rounded
                                : Icons.qr_code_2_rounded,
                            size: 11,
                            color: isLocked
                                ? (isDark ? AppColors.warning : AppColors.nowServingTextDark)
                                : (isDark ? AppColors.primarySoft : AppColors.primary),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeText ?? 'LOCKED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isLocked
                                  ? (isDark ? AppColors.warning : AppColors.nowServingTextDark)
                                  : (isDark ? AppColors.primarySoft : AppColors.primary),
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
