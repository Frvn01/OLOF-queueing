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

/// QR-only staff login screen.
/// - Mobile / Web / Tablet  → live camera QR scanner via mobile_scanner
/// - Windows Desktop        → PIN fallback (camera scanning unreliable on Win32)
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

  // ── PIN fallback (Desktop / Windows)
  final _pinController = TextEditingController();
  bool _pinMode = false;
  String? _pinError;
  bool _pinObscured = true;

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
      // Desktop always shows PIN; mobile shows scanner
      if (_isDesktop) {
        setState(() => _pinMode = true);
      } else {
        _startScanner();
      }
    });
  }

  void _startScanner() {
    _scannerCtrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    setState(() => _scannerActive = true);
  }

  @override
  void dispose() {
    _scannerCtrl?.dispose();
    _pinController.dispose();
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
        _errorMessage = 'Invalid or unrecognised QR code. Try again.';
        _processingQr = false;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _errorMessage = null);
          _scannerCtrl?.start();
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
      }
      return;
    }

    // If logging in as a Doctor, activate their profile in DoctorProvider
    if (staff.role.toLowerCase() == 'doctor') {
      final defaultRoom = staff.department == AppConstants.deptEyes ? 'OPHTHA ROOM 1' : 'ENT ROOM 1';
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
    }
  }

  // ── PIN fallback ────────────────────────────────────────────────────────────

  Future<void> _submitPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() => _pinError = 'PIN must be exactly 4 digits.');
      _shakeCtrl.forward(from: 0);
      return;
    }
    final adminProv = context.read<AdminProvider>();
    final staff = adminProv.resolvePin(pin);
    if (staff == null) {
      setState(() => _pinError = 'Incorrect PIN. Please try again.');
      _shakeCtrl.forward(from: 0);
      _pinController.clear();
      return;
    }

    // Super Admin PIN
    if (staff.role == 'super_admin') {
      await showSuperAdminDepartmentPicker(context, adminName: staff.name);
      return;
    }

    if (staff.role.toLowerCase() == 'doctor') {
      final defaultRoom = staff.department == AppConstants.deptEyes ? 'OPHTHA ROOM 1' : 'ENT ROOM 1';
      context.read<DoctorProvider>().selectDoctor(
        doctorName: staff.name,
        department: staff.department,
        room: staff.assignedRoom ?? defaultRoom,
      );
    }

    final route = AdminProvider.routeForRole(staff.role);
    if (route != null && mounted) context.go(route);
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
                      child: _pinMode
                          ? _buildPinCard(isDark)
                          : _buildScannerCard(isDark),
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
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
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
                  'Staff Login',
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
                      ? 'Scan your QR card to access ${widget.roleHint} station'
                      : 'Scan your staff QR card to access your station',
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
          // Toggle PIN / Scanner (only on non-desktop)
          if (!_isDesktop)
            TextButton.icon(
              icon: Icon(_pinMode ? Icons.qr_code_scanner : Icons.pin_rounded,
                  size: 18),
              label: Text(_pinMode ? 'Use Camera' : 'Use PIN'),
              onPressed: () {
                setState(() {
                  _pinMode = !_pinMode;
                  _errorMessage = null;
                  _pinError = null;
                  if (!_pinMode && !_scannerActive) _startScanner();
                });
              },
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
        // Instruction
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
                  'Point your camera at your Staff QR card to unlock your station.',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Scanner viewport
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 320,
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: Colors.black87,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
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
      ],
    );
  }

  // ── PIN Card ──────────────────────────────────────────────────────────────────

  Widget _buildPinCard(bool isDark) {
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.lightSurface;
    final borderColor =
        isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (ctx, child) => Transform.translate(
        offset: Offset(_shakeAnim.value, 0),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.pin_rounded,
                  size: 36, color: Colors.white),
            ),

            const SizedBox(height: 20),

            Text(
              'Enter Your Staff PIN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isDesktop
                  ? 'Enter your 4-digit PIN to unlock your station.'
                  : 'No camera? Enter your 4-digit PIN instead.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),

            const SizedBox(height: 28),

            // PIN field
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: _pinObscured,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 14,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '● ● ● ●',
                hintStyle: TextStyle(
                  fontSize: 22,
                  letterSpacing: 10,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary,
                ),
                errorText: _pinError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_pinObscured
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded),
                  onPressed: () =>
                      setState(() => _pinObscured = !_pinObscured),
                ),
              ),
              onSubmitted: (_) => _submitPin(),
              onChanged: (_) {
                if (_pinError != null) setState(() => _pinError = null);
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitPin,
                icon: const Icon(Icons.login_rounded),
                label: const Text('Login to Station',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            if (!_isDesktop) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Scan QR Code instead'),
                onPressed: () => setState(() {
                  _pinMode = false;
                  _pinError = null;
                  if (!_scannerActive) _startScanner();
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
