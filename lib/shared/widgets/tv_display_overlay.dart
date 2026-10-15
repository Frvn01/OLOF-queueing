import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../views/display/display_screen.dart';

// =============================================================================
// TV QUEUE DISPLAY LAUNCHER & OVERLAY
// Supports:
// 1. Spawning a separate native OS window on Windows desktop (Multi-Screen / TV)
//    so the desktop can be used simultaneously for Receptionist, Nurse, Doctor & Admin.
// 2. Full-screen overlay in current window with one-click return.
// 3. Direct navigation on mobile / tablet kiosks.
// =============================================================================

/// Spawns a brand-new independent native desktop window running /display.
Future<bool> launchSeparateDesktopWindow() async {
  if (kIsWeb) return false;
  try {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final exe = Platform.resolvedExecutable;
      await Process.start(exe, ['--display'], mode: ProcessStartMode.detached);
      return true;
    }
  } catch (e) {
    debugPrint('Could not launch separate TV window process: $e');
  }
  return false;
}

/// Main launcher function called by the TV Queue card on LandingScreen.
Future<void> launchTvDisplayOverlay(
  BuildContext context, {
  bool isDesktop = false,
}) async {
  if (!isDesktop) {
    context.go('/display');
    return;
  }

  // On desktop, show the choice dialog between Separate Window vs Current Window Overlay
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 260),
    transitionBuilder: (context, anim, secondaryAnim, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: anim, child: child),
    ),
    pageBuilder: (ctx, anim, secondaryAnim) => const _TvDisplayLauncherDialog(),
  );
}

/// Desktop Launcher Dialog: Choose between Separate Screen (TV) vs This Window Overlay
class _TvDisplayLauncherDialog extends StatefulWidget {
  const _TvDisplayLauncherDialog();

  @override
  State<_TvDisplayLauncherDialog> createState() =>
      _TvDisplayLauncherDialogState();
}

class _TvDisplayLauncherDialogState extends State<_TvDisplayLauncherDialog> {
  bool _isLaunching = false;

  Future<void> _launchSeparateWindow(BuildContext context) async {
    setState(() => _isLaunching = true);
    HapticFeedback.lightImpact();

    final success = await launchSeparateDesktopWindow();

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.tv_rounded, color: Colors.white, size: 22),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TV Queue Display Opened in Separate Window!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Drag the new window to your TV or 2nd monitor. This workstation remains active for Receptionist, Nurse, Doctor & Admin.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(20),
        ),
      );
    } else {
      // Fallback: open overlay in current window
      _openOverlay(context);
    }
  }

  void _openOverlay(BuildContext context) {
    Navigator.of(context).pop();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim, secondaryAnim, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: child,
      ),
      pageBuilder: (ctx, anim, secondaryAnim) => const _TvDisplayOverlay(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceMid : Colors.white;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header Icon & Title ──────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.connected_tv_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TV Queue Display',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Choose how to display the live waiting room queue monitor',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Option 1: Separate Window (Recommended) ──────────
                _OptionCard(
                  isDark: isDark,
                  isRecommended: true,
                  icon: Icons.open_in_new_rounded,
                  accentColor: const Color(0xFF0284C7),
                  title: 'Open in Separate TV Window',
                  badge: 'RECOMMENDED FOR DUAL SCREEN',
                  description:
                      'Launches an independent screen you can drag to your external TV or second monitor. Keeps this desktop free for Receptionist, Nurse, Doctor, and Admin workstations.',
                  buttonLabel: _isLaunching ? 'Opening…' : 'Launch Separate Window',
                  onTap: _isLaunching ? null : () => _launchSeparateWindow(context),
                ),
                const SizedBox(height: 14),

                // ── Option 2: This Window Overlay ───────────────────
                _OptionCard(
                  isDark: isDark,
                  isRecommended: false,
                  icon: Icons.fullscreen_rounded,
                  accentColor: const Color(0xFF64748B),
                  title: 'Open in This Window (Overlay)',
                  badge: 'PREVIEW / SINGLE SCREEN',
                  description:
                      'Displays the TV monitor full-screen inside this application window. Includes a quick "Close TV Display" button to return anytime.',
                  buttonLabel: 'Open Overlay',
                  onTap: _isLaunching ? null : () => _openOverlay(context),
                ),
                const SizedBox(height: 20),

                // ── Footer Cancel ───────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
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

class _OptionCard extends StatefulWidget {
  final bool isDark;
  final bool isRecommended;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String badge;
  final String description;
  final String buttonLabel;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.isDark,
    required this.isRecommended,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.badge,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark
        ? (_hovered
            ? AppColors.surfaceLight
            : AppColors.surfaceLight.withValues(alpha: 0.5))
        : (_hovered ? Colors.blue.shade50 : Colors.grey.shade50);

    final borderColor = widget.isRecommended
        ? (_hovered ? const Color(0xFF0284C7) : const Color(0xFF0284C7).withValues(alpha: 0.4))
        : (_hovered ? Colors.grey.shade400 : Colors.grey.shade300);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: widget.isRecommended ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, size: 20, color: widget.accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.isRecommended
                          ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.badge,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: widget.isRecommended
                            ? const Color(0xFF0284C7)
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: widget.onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.isRecommended
                        ? const Color(0xFF0284C7)
                        : (isDark ? AppColors.surfaceLight : Colors.grey.shade700),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(widget.icon, size: 15),
                  label: Text(
                    widget.buttonLabel,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
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
// OVERLAY WIDGET (USED FOR IN-APP PREVIEW)
// =============================================================================
class _TvDisplayOverlay extends StatelessWidget {
  const _TvDisplayOverlay();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          // ── Full Queue Display ─────────────────────────────────────
          const Positioned.fill(child: DisplayScreen()),

          // ── Close Button (top-right) ──────────────────────────────
          Positioned(
            top: 16,
            right: 16,
            child: _CloseButton(),
          ),

          // ── "TV OVERLAY" label (top-left) ────────────────────────
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tv_rounded, color: Colors.white54, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'TV QUEUE DISPLAY — In-App Preview Mode',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedOpacity(
        opacity: _hovered ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.red.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered ? Colors.red : Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Close TV Display',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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
