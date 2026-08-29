import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../providers/theme_provider.dart';

/// Landing screen — Mobile & Tablet Staff Station Kiosk
/// Exclusively for the 2 clinic staff roles: Receptionist and Secretary.
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
    // Wide if screen is wide OR if we're in landscape (phone rotated)
    final isWide = screenWidth > 600 || isLandscape;
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
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
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Clinic Logo & Branding
                            _buildBranding(isDark, isCompact, isLandscape),
                            SizedBox(height: isLandscape ? 12 : (isCompact ? 24 : 32)),

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

                            // Strictly 2 Roles for Mobile App: Receptionist & Secretary
                            if (isWide)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _buildRoleCard(
                                      context,
                                      isDark: isDark,
                                      icon: Icons.person_add_rounded,
                                      title: 'Receptionist',
                                      subtitle:
                                          'Register patients, scan QR & issue tickets',
                                      gradient: AppColors.primaryGradient,
                                      route: '/receptionist',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildRoleCard(
                                      context,
                                      isDark: isDark,
                                      icon: Icons.assignment_rounded,
                                      title: 'Secretary',
                                      subtitle:
                                          'Manage doctor queues, call patients & assign rooms',
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.cyanCalm,
                                          Color(0xFF0F766E),
                                        ],
                                      ),
                                      route: '/secretary',
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
                                    subtitle:
                                        'Register patients, scan QR & issue tickets',
                                    gradient: AppColors.primaryGradient,
                                    route: '/receptionist',
                                  ),
                                  const SizedBox(height: 14),
                                  _buildRoleCard(
                                    context,
                                    isDark: isDark,
                                    icon: Icons.assignment_rounded,
                                    title: 'Secretary',
                                    subtitle:
                                        'Manage doctor queues, call patients & assign rooms',
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.cyanCalm,
                                        Color(0xFF0F766E),
                                      ],
                                    ),
                                    route: '/secretary',
                                  ),
                                ],
                              ),
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
          // In landscape: put logo & text side by side to save vertical space
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
                          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${AppConstants.clinicName} — ${AppConstants.clinicSubtitle}',
                        style: TextStyle(
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        AppConstants.clinicTagline,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.primarySoft : AppColors.primary,
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
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppConstants.clinicName} — ${AppConstants.clinicSubtitle}',
                  style: TextStyle(
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
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
  }) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
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
        ),
      ),
    );
  }
}
