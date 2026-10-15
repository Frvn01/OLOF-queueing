import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/admin_provider.dart';

/// Admin Password Authentication Dialog
/// Shown when the Admin Workstation card is tapped — replaces QR requirement.
/// Password is validated against the hardcoded super-admin credential.
class AdminPasswordDialog extends StatefulWidget {
  const AdminPasswordDialog({super.key});

  /// Show the admin login dialog.
  /// Returns true if authentication was successful.
  static Future<bool> show(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, anim, secondaryAnim) => const AdminPasswordDialog(),
    );
    return result == true;
  }

  @override
  State<AdminPasswordDialog> createState() => _AdminPasswordDialogState();
}

class _AdminPasswordDialogState extends State<AdminPasswordDialog>
    with SingleTickerProviderStateMixin {
  final _passwordCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscure = true;
  bool _isChecking = false;
  String? _errorText;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // ── Accepted Admin Passwords ──────────────────────────────────────────────
  static bool _isValidPassword(String input, [BuildContext? context]) {
    final trimmed = input.trim();
    final lower = trimmed.toLowerCase();
    if (lower == 'admin' ||
        lower == 'admin123' ||
        lower == 'admin1234' ||
        lower == 'admin@123' ||
        lower == 'admin2025' ||
        lower == 'admin2026' ||
        lower == 'olof' ||
        lower == 'olof123' ||
        lower == 'olofadmin' ||
        lower == 'olofadmin2025' ||
        lower == 'olofadmin2026' ||
        lower == 'olof@admin' ||
        lower == 'olof@admin2025' ||
        lower == 'olof@admin2026' ||
        lower == 'password' ||
        lower == 'superadmin' ||
        lower == 'super_admin' ||
        trimmed == '9999' ||
        trimmed == '1234' ||
        trimmed == '123456' ||
        trimmed == '0000') {
      return true;
    }

    if (context != null) {
      try {
        final staffList = context.read<AdminProvider>().staffList;
        for (final staff in staffList) {
          if (staff.pin4.isNotEmpty && staff.pin4 == trimmed) return true;
          if (staff.qrSecret == trimmed || staff.qrSecret.toLowerCase() == lower) return true;
        }
      } catch (_) {}
    }

    return false;
  }
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _focusNode.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isChecking) return;
    final pw = _passwordCtrl.text;
    if (pw.isEmpty) {
      setState(() => _errorText = 'Please enter the admin password.');
      return;
    }

    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    // Brief artificial delay for UX
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    if (_isValidPassword(pw, context)) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(true);
      appRouter.go('/admin');
    } else {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
      _passwordCtrl.clear();
      setState(() {
        _isChecking = false;
        _errorText = 'Incorrect password. Access denied.';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _errorText = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceMid : Colors.white;
    const adminGreen = Color(0xFF059669);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(
              _shakeAnim.value * (_shakeCtrl.value < 0.5 ? 1 : -1),
              0,
            ),
            child: child,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: adminGreen.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: adminGreen.withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Icon badge ────────────────────────────────────
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF065F46), Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: adminGreen.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Title ─────────────────────────────────────────
                  Text(
                    'Admin Workstation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter the administrator password to continue.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ── Password field ────────────────────────────────
                  TextField(
                    controller: _passwordCtrl,
                    focusNode: _focusNode,
                    obscureText: _obscure,
                    onSubmitted: (_) => _submit(),
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                        letterSpacing: _obscure ? 4 : 1,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Admin password',
                        prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                        ),
                        errorText: _errorText,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceLight.withValues(alpha: 0.5)
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: adminGreen, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Default password: admin (or 9999)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Buttons ───────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _isChecking ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: adminGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isChecking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login_rounded, size: 18),
                          label: Text(
                            _isChecking ? 'Verifying…' : 'Unlock Admin',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Show admin password dialog then navigate to /admin if successful.
Future<void> showAdminPasswordLogin(BuildContext context) async {
  final ok = await AdminPasswordDialog.show(context);
  if (ok == true) {
    HapticFeedback.lightImpact();
    appRouter.go('/admin');
  }
}
