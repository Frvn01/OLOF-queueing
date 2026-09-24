import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/doctor_provider.dart';
import '../../../shared/widgets/super_admin_department_dialog.dart';

/// Enterprise-grade, secure QR Scanner & PIN Terminal for Mobile & Tablet Kiosks.
/// - Scans staff QR badge and automatically directs to assigned clinical station.
/// - Non-super-admin: Auto-redirects directly to station (Doctor, Nurse, Receptionist, Ophtha).
/// - Super-admin: Prompts destination department picker modal.
/// - Zero credential leaks: No plain PIN hints, no exposed Super Admin QR buttons.
/// - Clean, modern hospital-grade aesthetics with frosted glass and tactile feedback.
class MobileKioskScanner extends StatefulWidget {
  final bool isDark;

  const MobileKioskScanner({
    super.key,
    required this.isDark,
  });

  @override
  State<MobileKioskScanner> createState() => _MobileKioskScannerState();
}

class _MobileKioskScannerState extends State<MobileKioskScanner>
    with TickerProviderStateMixin {
  MobileScannerController? _scannerCtrl;
  bool _isScannerReady = false;
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isSuccess = false;
  bool _isPinMode = false;
  bool _isTorchOn = false;
  String _enteredPin = '';

  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  late AnimationController _shakeAnimController;
  late Animation<double> _shakeAnimation;

  bool get _isMobileCameraSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();

    // Smooth vertical laser sweep animation
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );

    // Subtle horizontal shake for invalid credential
    _shakeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 14).animate(
      CurvedAnimation(parent: _shakeAnimController, curve: Curves.elasticIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdminProvider>().loadStaff();
      if (_isMobileCameraSupported) {
        _startScanner();
      } else {
        // Fallback to secure PIN mode on desktop platforms without camera
        setState(() => _isPinMode = true);
      }
    });
  }

  void _startScanner() {
    try {
      _scannerCtrl = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      setState(() => _isScannerReady = true);
    } catch (e) {
      debugPrint('MobileScanner initialization error: $e');
      setState(() => _isPinMode = true);
    }
  }

  @override
  void dispose() {
    _scannerCtrl?.dispose();
    _laserAnimController.dispose();
    _shakeAnimController.dispose();
    super.dispose();
  }

  void _handleQrDetection(BarcodeCapture capture) {
    if (_isProcessing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    _processQrCode(raw.trim());
  }

  Future<void> _processQrCode(String raw) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying Credential Token...';
      _isSuccess = false;
    });

    final adminProv = context.read<AdminProvider>();
    final staff = adminProv.resolveQrPayload(raw);

    if (staff == null) {
      _shakeAnimController.forward(from: 0);
      setState(() {
        _statusMessage = 'Unrecognized Credential • Access Denied';
        _isSuccess = false;
      });

      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) {
        setState(() {
          _statusMessage = null;
          _isProcessing = false;
        });
      }
      return;
    }

    _onStaffAuthenticated(staff);
  }

  Future<void> _handlePinDigit(String digit) async {
    if (_isProcessing || _enteredPin.length >= 4) return;

    setState(() {
      _enteredPin += digit;
      _statusMessage = null;
    });

    if (_enteredPin.length == 4) {
      await _validatePin(_enteredPin);
    }
  }

  void _handlePinBackspace() {
    if (_isProcessing || _enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _statusMessage = null;
    });
  }

  void _handlePinClear() {
    if (_isProcessing) return;
    setState(() {
      _enteredPin = '';
      _statusMessage = null;
    });
  }

  Future<void> _validatePin(String pin) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying Staff PIN...';
    });

    final adminProv = context.read<AdminProvider>();
    final staff = adminProv.resolvePin(pin);

    if (staff == null) {
      _shakeAnimController.forward(from: 0);
      setState(() {
        _statusMessage = 'Invalid Security PIN • Access Denied';
        _isSuccess = false;
      });

      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) {
        setState(() {
          _enteredPin = '';
          _statusMessage = null;
          _isProcessing = false;
        });
      }
      return;
    }

    _onStaffAuthenticated(staff);
  }

  Future<void> _onStaffAuthenticated(StaffUser staff) async {
    setState(() {
      _isSuccess = true;
      _statusMessage = 'Access Authorized \u2022 Welcome, ${staff.name}';
    });

    // If logging in as a Doctor, activate their profile in DoctorProvider
    if (staff.role.toLowerCase() == 'doctor') {
      final defaultRoom = staff.department == AppConstants.deptEyes
          ? 'OPHTHA ROOM 1'
          : 'ENT ROOM 1';
      context.read<DoctorProvider>().selectDoctor(
            doctorName: staff.name,
            department: staff.department,
            room: staff.assignedRoom ?? defaultRoom,
          );
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Super Admin: Prompt department selector modal
    if (staff.role == 'super_admin' || staff.role == 'superadmin') {
      await showSuperAdminDepartmentPicker(context, adminName: staff.name);
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
          _isSuccess = false;
          _enteredPin = '';
        });
      }
      return;
    }

    // Direct navigation for standard personnel
    final route = AdminProvider.routeForRole(staff.role);
    if (route != null && mounted) {
      context.go(route);
    } else if (mounted) {
      setState(() {
        _isProcessing = false;
        _statusMessage = null;
        _isSuccess = false;
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF131D31) : Colors.white;
    final borderColor = _isSuccess
        ? const Color(0xFF10B981)
        : (_statusMessage != null && !_isSuccess
            ? AppColors.error
            : (isDark ? const Color(0xFF22304E) : const Color(0xFFE2E8F0)));

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (ctx, child) => Transform.translate(
        offset: Offset(_shakeAnimation.value, 0),
        child: child,
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: borderColor,
            width: _isSuccess || (_statusMessage != null && !_isSuccess) ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isSuccess
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Kiosk Header ──────────────────────────────────────────────
              _buildHeader(isDark),

              // ── Main Content: Camera Scanner vs PIN Pad ───────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.98, end: 1.0).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _isPinMode
                      ? _buildPinPadView(isDark)
                      : _buildCameraScannerView(isDark),
                ),
              ),

              // ── Security Feedback / Status Toast ─────────────────────────
              if (_statusMessage != null) _buildStatusBanner(),

              // ── Security Protocol Footnote (No Leaks) ─────────────────────
              _buildSecurityFooter(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header Widget ──────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF22304E) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STAFF ACCESS TERMINAL',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isPinMode
                        ? 'Staff PIN Authentication'
                        : 'Badge Auto-Detection Active',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Live Online Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5.5),
                const Text(
                  'ONLINE',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Camera Scanner View ────────────────────────────────────────────────────

  Widget _buildCameraScannerView(bool isDark) {
    return Column(
      key: const ValueKey('camera_view'),
      children: [
        // Camera Viewport
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 290,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF090D16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF22304E) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isScannerReady && _scannerCtrl != null)
                  Positioned.fill(
                    child: MobileScanner(
                      controller: _scannerCtrl!,
                      onDetect: _handleQrDetection,
                      errorBuilder: (context, error) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.videocam_off_rounded,
                                  color: AppColors.error,
                                  size: 44,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Camera Scanner Standby',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Switch to PIN mode or allow camera permission.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => setState(() => _isPinMode = true),
                                  icon: const Icon(Icons.dialpad_rounded, size: 16),
                                  label: const Text('Use PIN Authentication'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF10B981),
                      strokeWidth: 2.5,
                    ),
                  ),

                // Center Guide Reticle
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Corner Brackets
                      _buildCornerReticle(),

                      // Animated Laser Beam
                      if (_isScannerReady && !_isProcessing)
                        AnimatedBuilder(
                          animation: _laserAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: 200 * _laserAnimation.value,
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 2.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF10B981).withValues(alpha: 0.0),
                                      const Color(0xFF10B981),
                                      const Color(0xFF06B6D4),
                                      const Color(0xFF10B981),
                                      const Color(0xFF10B981).withValues(alpha: 0.0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      // Ghost Watermark Icon
                      Center(
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          size: 72,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Camera Controls (Frosted Glass Pill)
                if (_scannerCtrl != null && !_isProcessing)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isTorchOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              size: 18,
                              color: _isTorchOn ? const Color(0xFFFBBF24) : Colors.white70,
                            ),
                            tooltip: 'Flashlight',
                            onPressed: () {
                              _scannerCtrl?.toggleTorch();
                              setState(() => _isTorchOn = !_isTorchOn);
                            },
                          ),
                          Container(width: 1, height: 16, color: Colors.white24),
                          IconButton(
                            icon: const Icon(
                              Icons.cameraswitch_rounded,
                              size: 18,
                              color: Colors.white70,
                            ),
                            tooltip: 'Flip Camera',
                            onPressed: () => _scannerCtrl?.switchCamera(),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Scanning prompt text
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      'Align staff badge within frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Action Switch to PIN Pad Mode
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _isPinMode = true),
            icon: const Icon(Icons.dialpad_rounded, size: 18),
            label: const Text('Enter Confidential 4-Digit PIN Instead'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
              side: BorderSide(
                color: isDark ? const Color(0xFF0369A1) : AppColors.primary.withValues(alpha: 0.4),
                width: 1.3,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Corner Reticle Widget ──────────────────────────────────────────────────

  Widget _buildCornerReticle() {
    const cornerSize = 22.0;
    const cornerWidth = 3.5;
    const color = Color(0xFF10B981);

    return Stack(
      children: [
        // Top Left
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: cornerWidth),
                left: BorderSide(color: color, width: cornerWidth),
              ),
            ),
          ),
        ),
        // Top Right
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: cornerWidth),
                right: BorderSide(color: color, width: cornerWidth),
              ),
            ),
          ),
        ),
        // Bottom Left
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: cornerWidth),
                left: BorderSide(color: color, width: cornerWidth),
              ),
            ),
          ),
        ),
        // Bottom Right
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: cornerWidth),
                right: BorderSide(color: color, width: cornerWidth),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── PIN Pad View ───────────────────────────────────────────────────────────

  Widget _buildPinPadView(bool isDark) {
    return Column(
      key: const ValueKey('pin_view'),
      children: [
        const Text(
          'Staff Passcode Verification',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your assigned 4-digit confidential security code',
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 18),

        // 4 Pin Dot Indicators (Masked & Protected)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isFilled = index < _enteredPin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: isFilled ? 18 : 16,
              height: isFilled ? 18 : 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? const Color(0xFF10B981)
                    : Colors.transparent,
                border: Border.all(
                  color: isFilled
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                  width: 2,
                ),
                boxShadow: isFilled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Keypad Grid: 3x4 layout (1-9, C, 0, Backspace)
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            children: [
              _buildKeypadRow(['1', '2', '3'], isDark),
              const SizedBox(height: 10),
              _buildKeypadRow(['4', '5', '6'], isDark),
              const SizedBox(height: 10),
              _buildKeypadRow(['7', '8', '9'], isDark),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSpecialKey(
                    label: 'C',
                    onTap: _handlePinClear,
                    isDark: isDark,
                    color: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
                  ),
                  _buildDigitKey('0', isDark),
                  _buildSpecialKey(
                    icon: Icons.backspace_rounded,
                    onTap: _handlePinBackspace,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Action Switch to Camera Scanner Mode
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _isPinMode = false;
                _enteredPin = '';
                _statusMessage = null;
              });
              if (!_isScannerReady) _startScanner();
            },
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: const Text('Back to Live Camera Scanner'),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> digits, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitKey(d, isDark)).toList(),
    );
  }

  Widget _buildDigitKey(String digit, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handlePinDigit(digit),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 72,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    String? label,
    IconData? icon,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 72,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF162032) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF28354D) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          child: label != null
              ? Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color ?? (isDark ? Colors.white70 : Colors.black87),
                  ),
                )
              : Icon(
                  icon,
                  size: 20,
                  color: color ?? (isDark ? Colors.white70 : Colors.black87),
                ),
        ),
      ),
    );
  }

  // ── Status Toast Banner ────────────────────────────────────────────────────

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: _isSuccess
            ? const Color(0xFF10B981).withValues(alpha: 0.16)
            : AppColors.error.withValues(alpha: 0.16),
        border: Border(
          top: BorderSide(
            color: _isSuccess
                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                : AppColors.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSuccess ? Icons.check_circle_rounded : Icons.shield_outlined,
            color: _isSuccess ? const Color(0xFF10B981) : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: _isSuccess ? const Color(0xFF10B981) : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Security Footer ────────────────────────────────────────────────────────

  Widget _buildSecurityFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 13,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 6),
          Text(
            'OLOF Health Security Protocol • Authorized Personnel Only',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
