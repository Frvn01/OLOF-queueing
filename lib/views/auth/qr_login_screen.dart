import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../shared/widgets/super_admin_department_dialog.dart';

/// Secure QR-Only Staff Authentication Screen.
/// - Scans staff QR badge via camera or USB 2D barcode scanner.
/// - Automatically resolves identity and unlocks the assigned clinical station.
/// - No PINs and No manual station bypass.
class QrLoginScreen extends StatefulWidget {
  /// Optional pre-selected role hint shown in the header (not enforced)
  final String? roleHint;

  const QrLoginScreen({super.key, this.roleHint});

  @override
  State<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends State<QrLoginScreen>
    with SingleTickerProviderStateMixin {
  // ── scanner
  MobileScannerController? _scannerCtrl;
  bool _scannerActive = false;
  bool _processingQr = false;
  final TextEditingController _barcodeCtrl = TextEditingController();
  final FocusNode _barcodeFocus = FocusNode();

  // ── shared
  String? _errorMessage;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    // Load staff before resolving any QR
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdminProvider>().loadStaff();
      _startScanner();
      if (_isDesktop) {
        _barcodeFocus.requestFocus();
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
      setState(() => _scannerActive = true);
    } catch (_) {
      // Camera may not be available on some PCs
    }
  }

  @override
  void dispose() {
    _scannerCtrl?.dispose();
    _barcodeCtrl.dispose();
    _barcodeFocus.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── QR resolved ────────────────────────────────────────────────────────────

  void _handleQrDetect(BarcodeCapture capture) {
    if (_processingQr) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _processingQr = true;
    _scannerCtrl?.stop();
    _resolveAndNavigate(raw);
  }

  Future<void> _resolveAndNavigate(String raw) async {
    final adminProv = context.read<AdminProvider>();
    final staff = adminProv.resolveQrPayload(raw);
    if (staff == null) {
      _shakeCtrl.forward(from: 0);
      setState(() {
        _errorMessage = 'Unrecognized or invalid Staff QR badge. Access Denied.';
        _processingQr = false;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _errorMessage = null);
          _scannerCtrl?.start();
          if (_isDesktop) _barcodeFocus.requestFocus();
        }
      });
      return;
    }

    // Super Admin: Prompt destination department picker
    if (staff.role == 'super_admin') {
      await showSuperAdminDepartmentPicker(context, adminName: staff.name);
      if (mounted) {
        setState(() => _processingQr = false);
        _scannerCtrl?.start();
        if (_isDesktop) _barcodeFocus.requestFocus();
      }
      return;
    }

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

    // Standard staff: Automatically navigate straight to station
    final route = AdminProvider.routeForRole(staff.role);
    if (route != null && mounted) {
      context.go(route);
    } else if (mounted) {
      setState(() => _processingQr = false);
      _scannerCtrl?.start();
      if (_isDesktop) _barcodeFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDarkest : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.surfaceGradient
              : AppColors.lightSurfaceGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _buildScannerCard(isDark),
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

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
            ),
            onPressed: () => context.go('/'),
            tooltip: 'Back to Station Selector',
          ),
          const SizedBox(width: 6),
          const OlofLogo(size: 34, showBorder: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Staff QR Authentication',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  widget.roleHint != null
                      ? 'Scan Staff QR badge to access ${widget.roleHint} station'
                      : 'Scan your Staff QR badge for authorized access',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 12, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  'SECURE',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Scanner Card ─────────────────────────────────────────────────────────────

  Widget _buildScannerCard(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Instruction banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.qr_code_2_rounded,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Present your physical Staff QR badge to the camera or barcode scanner.',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Scanner viewport
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 300,
            child: _scannerActive
                ? Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerCtrl!,
                        onDetect: _handleQrDetect,
                      ),
                      // Crosshair overlay
                      Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.qr_code_scanner_rounded,
                              size: 48, color: AppColors.primary),
                          const SizedBox(height: 12),
                          const Text(
                            'Ready for Staff QR Scan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Scan badge with camera or USB scanner gun',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (ctx, child) => Transform.translate(
              offset: Offset(_shakeAnim.value, 0),
              child: child,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // USB / Hardware Barcode Reader Field (Receives scanner gun input)
        TextField(
          controller: _barcodeCtrl,
          focusNode: _barcodeFocus,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'USB Barcode / QR Scanner Input...',
            hintStyle: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            ),
            prefixIcon: const Icon(Icons.barcode_reader, size: 20, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              onPressed: () {
                final txt = _barcodeCtrl.text.trim();
                if (txt.isNotEmpty) {
                  _barcodeCtrl.clear();
                  _resolveAndNavigate(txt);
                }
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
              ),
            ),
          ),
          onSubmitted: (val) {
            final txt = val.trim();
            if (txt.isNotEmpty) {
              _barcodeCtrl.clear();
              _resolveAndNavigate(txt);
            }
          },
        ),

        const SizedBox(height: 12),

        Text(
          'Security Policy: Only verified Staff QR credentials will unlock clinical stations.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}


