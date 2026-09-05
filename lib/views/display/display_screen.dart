import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/audio_helper.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../data/models/queue_entry.dart';
import '../../providers/queue_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/clinic_provider.dart';

/// Client Display Screen for TV / Web Waiting Room Projection
/// Specifically designed for eye and ENT clinic patients:
/// - Eye-Comfort Anti-Glare Soft White & Dark Theme toggles
/// - Large, high-contrast WCAG AAA typography (for patients with low vision, cataracts, post-dilation)
/// - Melodious audio chime on new patient calls
/// - Real-time clock, status counters, and clinic announcement ticker
class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen>
    with SingleTickerProviderStateMixin {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();
  String? _lastCalledEntId;
  String? _lastCalledEyesId;
  bool _audioEnabled = true;
  bool _isPlayingChimeFeedback = false;
  // Tracks whether the user has tapped the screen (required by Chrome to unlock audio)
  bool _webAudioUnlocked = !kIsWeb;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String? _getServingDoctor(QueueEntry serving, String department) {
    if (serving.assignedDoctor != null && serving.assignedDoctor!.trim().isNotEmpty) {
      return serving.assignedDoctor!;
    }
    // Check if room has an assigned doctor in ClinicProvider
    if (serving.assignedRoom != null && serving.assignedRoom!.trim().isNotEmpty) {
      try {
        final clinic = context.read<ClinicProvider>();
        final doc = clinic.getDoctorForRoom(serving.assignedRoom!);
        if (doc != null) return doc.name;
      } catch (_) {}
    }
    // Return null for new/unassigned patients
    return null;
  }

  void _checkAndPlayChime(QueueEntry? entServing, QueueEntry? eyesServing) {
    bool hasNewCall = false;

    if (entServing != null && entServing.id != _lastCalledEntId) {
      _lastCalledEntId = entServing.id;
      hasNewCall = true;
    }

    if (eyesServing != null && eyesServing.id != _lastCalledEyesId) {
      _lastCalledEyesId = eyesServing.id;
      hasNewCall = true;
    }

    if (hasNewCall && _audioEnabled) {
      _triggerChime();
    }
  }

  Future<void> _triggerChime() async {
    setState(() => _isPlayingChimeFeedback = true);
    await AudioHelper.playChime();
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) {
          setState(() => _isPlayingChimeFeedback = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final isHighContrast = themeProv.isHighContrast;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final bgColor = isDark ? AppColors.surfaceDarkest : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        // Any tap on the screen unlocks Web Audio API context (Chrome requirement)
        onTap: _handleScreenTap,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            SafeArea(
        child: Consumer<QueueProvider>(
          builder: (context, queueProv, _) {
            final entServing = queueProv.getNowServing(AppConstants.deptEnt);
            final eyesServing = queueProv.getNowServing(AppConstants.deptEyes);
            final entWaiting = queueProv.getWaiting(AppConstants.deptEnt);
            final eyesWaiting = queueProv.getWaiting(AppConstants.deptEyes);

            // Trigger chime if serving changed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndPlayChime(entServing, eyesServing);
            });

            return Column(
              children: [
                _buildHeader(context, isDark: isDark, isHighContrast: isHighContrast),
                Expanded(
                  child: isLandscape
                      ? Row(
                          children: [
                            Expanded(
                              child: _buildDepartmentSection(
                                department: AppConstants.deptEnt,
                                title: 'ENT DEPARTMENT',
                                subtitle: 'Ear, Nose & Throat Center',
                                icon: Icons.hearing_rounded,
                                accentColor: AppColors.entColor,
                                gradient: AppColors.entGradient,
                                serving: entServing,
                                waitingList: entWaiting,
                                isDark: isDark,
                                isHighContrast: isHighContrast,
                              ),
                            ),
                            Container(
                              width: 2,
                              color: isDark
                                  ? AppColors.surfaceLight.withValues(alpha: 0.6)
                                  : AppColors.lightBorder,
                            ),
                            Expanded(
                              child: _buildDepartmentSection(
                                department: AppConstants.deptEyes,
                                title: 'EYES (OPHTHALMOLOGY)',
                                subtitle: 'Comprehensive Eye Care',
                                icon: Icons.visibility_rounded,
                                accentColor: AppColors.eyesColor,
                                gradient: AppColors.eyesGradient,
                                serving: eyesServing,
                                waitingList: eyesWaiting,
                                isDark: isDark,
                                isHighContrast: isHighContrast,
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildDepartmentSection(
                                department: AppConstants.deptEnt,
                                title: 'ENT DEPARTMENT',
                                subtitle: 'Ear, Nose & Throat Center',
                                icon: Icons.hearing_rounded,
                                accentColor: AppColors.entColor,
                                gradient: AppColors.entGradient,
                                serving: entServing,
                                waitingList: entWaiting,
                                isDark: isDark,
                                isHighContrast: isHighContrast,
                              ),
                              Divider(
                                height: 2,
                                color: isDark
                                    ? AppColors.surfaceLight
                                    : AppColors.lightBorder,
                              ),
                              _buildDepartmentSection(
                                department: AppConstants.deptEyes,
                                title: 'EYES (OPHTHALMOLOGY)',
                                subtitle: 'Comprehensive Eye Care',
                                icon: Icons.visibility_rounded,
                                accentColor: AppColors.eyesColor,
                                gradient: AppColors.eyesGradient,
                                serving: eyesServing,
                                waitingList: eyesWaiting,
                                isDark: isDark,
                                isHighContrast: isHighContrast,
                              ),
                            ],
                          ),
                        ),
                ),
                _buildFooterTicker(isDark: isDark),
              ],
            );
          },
        ),
      ), // SafeArea

      // Audio Unlock Banner Overlay (web only — Chrome autoplay policy)
      if (kIsWeb && !_webAudioUnlocked)
        _buildAudioUnlockBanner(isDark: isDark),
    ], // Stack children
    ), // Stack
    ), // GestureDetector
  );
}

  // ── Web Audio Unlock ─────────────────────────────────────────────────────

  /// Called on any screen tap. On web, this unlocks the AudioContext.
  void _handleScreenTap() {
    if (!_webAudioUnlocked) {
      AudioHelper.unlockWebAudio();
      setState(() => _webAudioUnlocked = true);
    }
  }

  /// Bottom banner prompting the user to tap to enable sound (web only).
  Widget _buildAudioUnlockBanner({required bool isDark}) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _handleScreenTap();
            _triggerChime();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xCC0369A1), Color(0xCC0284C7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.touch_app_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'TAP ANYWHERE TO ENABLE CHIME SOUND',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Required by browser',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required bool isDark,
    required bool isHighContrast,
  }) {
    final timeStr = DateFormat('hh:mm:ss a').format(_currentTime);
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(_currentTime);
    final themeProv = context.read<ThemeProvider>();

    final headerBg = isDark ? AppColors.surfaceDark : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.primarySoft : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!kIsWeb)
            IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              ),
              onPressed: () => context.go('/'),
              tooltip: 'Return to Staff Kiosk',
            ),
          if (!kIsWeb) const SizedBox(width: 8),

          // Clinic Logo with Real Asset and Polished Container
          const OlofLogo(size: 48, showBorder: true),
          const SizedBox(width: 14),

          // Clinic Header Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OUR LADY OF FATIMA E.E.N.T. CENTER',
                  style: TextStyle(
                    fontSize: isHighContrast ? 22 : 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${AppConstants.clinicSubtitle} • ${AppConstants.clinicTagline}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: subtitleColor,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── ACCESSIBILITY & AUDIO CONTROLS ──
          // Test Chime Sound Button
          Tooltip(
            message: 'Test Audio Chime',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _triggerChime,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _isPlayingChimeFeedback
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceMid : AppColors.lightSurfaceMid),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isPlayingChimeFeedback
                        ? AppColors.primaryLight
                        : borderColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPlayingChimeFeedback
                          ? Icons.graphic_eq_rounded
                          : Icons.notifications_active_rounded,
                      size: 18,
                      color: _isPlayingChimeFeedback
                          ? Colors.white
                          : (isDark ? AppColors.primaryLight : AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isPlayingChimeFeedback ? 'PLAYING...' : 'TEST CHIME',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _isPlayingChimeFeedback
                            ? Colors.white
                            : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Audio Mute/Unmute Toggle
          IconButton(
            icon: Icon(
              _audioEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _audioEnabled
                  ? (isDark ? AppColors.cyanCalm : AppColors.primary)
                  : (isDark ? AppColors.textDisabled : AppColors.lightTextDisabled),
            ),
            tooltip: _audioEnabled ? 'Mute Queue Chime' : 'Unmute Queue Chime',
            onPressed: () {
              setState(() {
                _audioEnabled = !_audioEnabled;
              });
              if (_audioEnabled) {
                _triggerChime();
              }
            },
          ),

          // Low-Vision / High-Contrast Mode Toggle
          IconButton(
            icon: Icon(
              isHighContrast ? Icons.visibility_rounded : Icons.visibility_outlined,
              color: isHighContrast
                  ? AppColors.warning
                  : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
            ),
            tooltip: isHighContrast
                ? 'High-Legibility Mode ON'
                : 'Enable High-Legibility Vision Care Mode',
            onPressed: () => themeProv.toggleHighContrast(),
          ),

          // Eye-Comfort Theme Toggle (Soft White / Dark Slate)
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.warning : AppColors.brandBlue,
            ),
            tooltip: isDark
                ? 'Switch to Eye-Comfort Light (Anti-Glare)'
                : 'Switch to Eye-Comfort Dark (Night Slate)',
            onPressed: () => themeProv.toggleTheme(),
          ),
          const SizedBox(width: 10),

          // Live Digital Clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceMid : AppColors.lightSurfaceMid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: isHighContrast ? 21 : 19,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.cyanCalm : AppColors.primaryDark,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentSection({
    required String department,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required LinearGradient gradient,
    required QueueEntry? serving,
    required List<QueueEntry> waitingList,
    required bool isDark,
    required bool isHighContrast,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Department Title Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isHighContrast ? 22 : 19,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${waitingList.length} WAITING',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // NOW SERVING CARD (Large Prominent Call Display)
          Expanded(
            flex: 3,
            child: _buildNowServingCard(
              department: department,
              serving: serving,
              accentColor: accentColor,
              isDark: isDark,
              isHighContrast: isHighContrast,
            ),
          ),
          const SizedBox(height: 14),

          // UP NEXT / WAITING QUEUE TICKER
          Expanded(
            flex: 2,
            child: _buildUpcomingQueueCard(
              waitingList: waitingList,
              accentColor: accentColor,
              isDark: isDark,
              isHighContrast: isHighContrast,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowServingCard({
    required String department,
    required QueueEntry? serving,
    required Color accentColor,
    required bool isDark,
    required bool isHighContrast,
  }) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textDisabled = isDark ? AppColors.textDisabled : AppColors.lightTextDisabled;

    if (serving == null) {
      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceLight : AppColors.lightBg)
                      .withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_empty_rounded,
                  size: 48,
                  color: textDisabled,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'STANDBY FOR CALL',
                style: TextStyle(
                  fontSize: isHighContrast ? 24 : 21,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please watch and listen for your number',
                style: TextStyle(
                  fontSize: isHighContrast ? 16 : 14,
                  color: textDisabled,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isNewCall = _isPlayingChimeFeedback;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.nowServing,
            width: isHighContrast ? 4.5 : 3.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.nowServing.withValues(alpha: isNewCall ? 0.5 : 0.28),
              blurRadius: isNewCall ? 36 : 24,
              spreadRadius: isNewCall ? 5 : 2,
            ),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing Status tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.nowServing,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.nowServing.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up_rounded, size: 15, color: AppColors.surfaceDarkest),
                        SizedBox(width: 6),
                        Text(
                          'NOW SERVING',
                          style: TextStyle(
                            color: AppColors.surfaceDarkest,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Giant Queue Number (Ultra-High Contrast & Scaled)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      serving.queueNumber,
                      style: TextStyle(
                        fontSize: isHighContrast ? 104 : 88,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.nowServing : const Color(0xFFB45309),
                        letterSpacing: 2.0,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Doctor Name or NEW PATIENT badge
                  Builder(
                    builder: (ctx) {
                      final doctorName = _getServingDoctor(serving, department);
                      final hasRoom = serving.assignedRoom != null && serving.assignedRoom!.trim().isNotEmpty;
                      if (doctorName != null) {
                        return Text(
                          doctorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isHighContrast ? 24 : 21,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                            letterSpacing: 0.5,
                          ),
                        );
                      } else {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            hasRoom ? 'NEW PATIENT' : 'NEW PATIENT — UNASSIGNED',
                            style: TextStyle(
                              fontSize: isHighContrast ? 16 : 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.warning,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 3),
                  // Purpose label
                  Text(
                    serving.purpose.toUpperCase(),
                    style: TextStyle(
                      fontSize: isHighContrast ? 13 : 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Assigned Room Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: (serving.assignedRoom != null && serving.assignedRoom!.trim().isNotEmpty)
                          ? (isDark ? AppColors.primaryDark : AppColors.primary)
                          : (isDark ? AppColors.surfaceLight : AppColors.lightSurfaceMid),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (serving.assignedRoom != null && serving.assignedRoom!.trim().isNotEmpty)
                            ? AppColors.primaryLight
                            : (isDark ? AppColors.surfaceHover : AppColors.lightBorder),
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (serving.assignedRoom != null && serving.assignedRoom!.trim().isNotEmpty)
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (serving.assignedRoom != null && serving.assignedRoom!.trim().isNotEmpty)
                              ? Icons.meeting_room_rounded
                              : Icons.info_outline_rounded,
                          color: (serving.assignedRoom != null && serving.assignedRoom!.trim().isNotEmpty)
                              ? Colors.white
                              : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (serving.assignedRoom != null && serving.assignedRoom!.trim().isNotEmpty)
                              ? 'PROCEED TO ${serving.assignedRoom!.toUpperCase()}'
                              : 'PLEASE WAIT FOR ROOM ASSIGNMENT',
                          style: TextStyle(
                            fontSize: isHighContrast ? 17 : 15.5,
                            fontWeight: FontWeight.w900,
                            color: (serving.assignedRoom != null && serving.assignedRoom!.trim().isNotEmpty)
                                ? Colors.white
                                : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingQueueCard({
    required List<QueueEntry> waitingList,
    required Color accentColor,
    required bool isDark,
    required bool isHighContrast,
  }) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final itemBg = isDark ? AppColors.surfaceLight : AppColors.lightSurfaceMid;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.queue_rounded, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'UP NEXT / WAITING QUEUE',
                style: TextStyle(
                  fontSize: isHighContrast ? 15 : 13.5,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: waitingList.isEmpty
                ? Center(
                    child: Text(
                      'No more patients in queue',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? AppColors.textDisabled : AppColors.lightTextDisabled,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: waitingList.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = waitingList[index];
                      final hasDoctor = item.assignedDoctor != null && item.assignedDoctor!.trim().isNotEmpty;
                      final hasRoom = item.assignedRoom != null && item.assignedRoom!.trim().isNotEmpty;
                      final isNew = !hasDoctor && !hasRoom;

                      return Container(
                        width: 145,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: itemBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: item.isOnHold
                                ? AppColors.onHold
                                : isNew
                                    ? AppColors.warning.withValues(alpha: 0.5)
                                    : (isDark ? AppColors.surfaceHover : AppColors.lightBorder),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.queueNumber,
                              style: TextStyle(
                                fontSize: isHighContrast ? 22 : 20,
                                fontWeight: FontWeight.w900,
                                color: item.isOnHold
                                    ? AppColors.onHold
                                    : textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (isNew)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.warning,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              )
                            else if (hasRoom && !hasDoctor)
                              Text(
                                item.assignedRoom!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.cyanCalm,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            else
                              // Purpose shown instead of patient full name for Data Privacy Act
                              Text(
                                item.purpose,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (item.isOnHold)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.onHold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ON HOLD',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.onHold,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterTicker({required bool isDark}) {
    final footerBg = isDark ? AppColors.surfaceDark : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: footerBg,
        border: Border(
          top: BorderSide(color: borderColor, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_rounded, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'NOTICE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please listen for the chime and watch the screen for your number. Senior citizens, pregnant patients, and PWDs are provided priority care.',
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
