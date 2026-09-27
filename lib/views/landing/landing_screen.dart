import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../providers/theme_provider.dart';
import 'widgets/mobile_kiosk_scanner.dart';

/// Landing / Staff Login Screen — Exclusive QR Access Terminal
/// - Strictly requires physical Staff QR badge scanning (camera or 2D USB barcode reader).
/// - No PINs and No manual station bypass.
/// - TV Queue Display link available for waiting room screens.
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

                    // Right action buttons: TV Display launcher + Theme toggle
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.go('/display'),
                          icon: const Icon(Icons.tv_rounded, size: 15),
                          label: const Text(
                            'TV Display',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                            side: BorderSide(
                              color: (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)).withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Clinic Logo & Branding
                            _buildBranding(isDark, isCompact, isLandscape),
                            SizedBox(
                                height: isLandscape
                                    ? 12
                                    : (isCompact ? 16 : 24)),

                            // ──────────────────────────────────────────
                            // ONLY THE QR CODE SCANNER ON LOGIN SCREEN
                            // ──────────────────────────────────────────
                            MobileKioskScanner(isDark: isDark),
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
}
