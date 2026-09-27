import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/doctor_provider.dart';
import '../../../shared/widgets/super_admin_department_dialog.dart';

/// Enterprise-grade QR Scanner & Station Terminal for Mobile & Tablet Kiosks.
/// - Scans staff QR badge and automatically directs to assigned clinical station.
/// - Non-super-admin: Auto-redirects directly to station (Doctor, Nurse, Receptionist, Ophtha).
/// - Super-admin: Prompts destination department picker modal.
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
  bool _isTorchOn = false;

  final _barcodeCtrl = TextEditingController();
  final _barcodeFocus = FocusNode();

  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  late AnimationController _shakeAnimController;
  late Animation<double> _shakeAnimation;

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
      _startScanner();
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
    }
  }

  @override
  void dispose() {
    _scannerCtrl?.dispose();
    _barcodeCtrl.dispose();
    _barcodeFocus.dispose();
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

  Future<void> _onStaffAuthenticated(StaffUser staff) async {
    setState(() {
      _isSuccess = true;
      _statusMessage = 'Access Authorized • Welcome, ${staff.name}';
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

              // ── Main Content: Camera & 2D Barcode Scanner ─────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: _buildCameraScannerView(isDark),
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
                    'Badge Auto-Detection Active',
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
                                  'Camera is not available. Connect a webcam or scan badge below.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _startScanner,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Retry Camera'),
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

        // USB / Bluetooth Barcode Reader Input
        TextField(
          controller: _barcodeCtrl,
          focusNode: _barcodeFocus,
          textInputAction: TextInputAction.go,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onSubmitted: (v) {
            final trimmed = v.trim();
            if (trimmed.isNotEmpty) {
              _barcodeCtrl.clear();
              _processQrCode(trimmed);
            }
          },
          decoration: InputDecoration(
            hintText: 'Or scan badge with USB reader / enter QR code...',
            hintStyle: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              onPressed: () {
                final trimmed = _barcodeCtrl.text.trim();
                if (trimmed.isNotEmpty) {
                  _barcodeCtrl.clear();
                  _processQrCode(trimmed);
                }
              },
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF10B981),
                width: 1.5,
              ),
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
