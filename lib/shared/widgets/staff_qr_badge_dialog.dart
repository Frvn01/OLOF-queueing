import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/local_storage_service.dart';
import '../../providers/admin_provider.dart';
import 'olof_logo.dart';

/// Shows the printable and saveable QR badge dialog for a staff member.
Future<void> showStaffQrBadgeDialog(
  BuildContext context,
  StaffUser staff, {
  bool isNewlyCreated = false,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _StaffQrBadgeDialogWidget(
      staff: staff,
      isNewlyCreated: isNewlyCreated,
    ),
  );
}

class _StaffQrBadgeDialogWidget extends StatefulWidget {
  final StaffUser staff;
  final bool isNewlyCreated;

  const _StaffQrBadgeDialogWidget({
    required this.staff,
    required this.isNewlyCreated,
  });

  @override
  State<_StaffQrBadgeDialogWidget> createState() => _StaffQrBadgeDialogWidgetState();
}

class _StaffQrBadgeDialogWidgetState extends State<_StaffQrBadgeDialogWidget> {
  final GlobalKey _badgeRepaintKey = GlobalKey();
  bool _isSaving = false;

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return const Color(0xFFF59E0B); // Amber / Gold
      case 'doctor':
        return const Color(0xFF059669); // Emerald
      case 'nurse':
        return const Color(0xFFEC4899); // Pink
      case 'receptionist':
        return AppColors.primary; // Blue
      case 'ophtha':
      case 'optha':
      case 'secretary':
        return AppColors.cyanCalm; // Cyan / Teal
      case 'admin':
        return const Color(0xFF065F46); // Dark Emerald
      default:
        return AppColors.primary;
    }
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return 'SUPER ADMINISTRATOR';
      case 'doctor':
        return 'PHYSICIAN / DOCTOR';
      case 'nurse':
        return 'TRIAGE NURSE';
      case 'receptionist':
        return 'RECEPTIONIST';
      case 'ophtha':
      case 'optha':
        return 'OPHTHA DEPT';
      case 'admin':
        return 'CLINIC ADMINISTRATOR';
      default:
        return role.toUpperCase();
    }
  }

  Future<Uint8List?> _captureBadgePng() async {
    try {
      final boundary = _badgeRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing badge PNG: $e');
      return null;
    }
  }

  Future<void> _saveBadgeLocally() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _captureBadgePng();
      if (bytes == null) throw Exception('Could not render badge image');

      final path = await LocalStorageService.instance.saveStaffBadgeLocally(
        staffId: widget.staff.id,
        staffName: widget.staff.name,
        bytes: bytes,
      );

      setState(() {
        _isSaving = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path.isNotEmpty ? 'Badge saved to: $path' : 'Badge image captured successfully!',
          ),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save badge: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _printBadge() {
    // Show high-contrast print layout
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Print Staff Credential Badge'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The badge is prepared for printing on standard ID card stock or paper.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Employee: ${widget.staff.name}\nRole: ${_formatRole(widget.staff.role)}\nStation: ${widget.staff.assignedRoom ?? "General"}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            const Text(
              'You can save the PNG file to your computer and send it to any network or photo printer.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _saveBadgeLocally();
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Save PNG to Print'),
          ),
        ],
      ),
    );
  }

  void _copyQrData() {
    Clipboard.setData(ClipboardData(text: widget.staff.qrPayload));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code payload copied to clipboard!'),
        backgroundColor: Color(0xFF0D9488),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = widget.staff;
    final color = _roleColor(staff.role);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge_rounded, color: color, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        widget.isNewlyCreated ? 'Staff Member Added!' : 'Staff QR Credential Card',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── REPAINT BOUNDARY: CAPTURABLE BADGE ──────────────────────
              RepaintBoundary(
                key: _badgeRepaintKey,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white, // white background for print readability
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Clinic Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const OlofLogo(size: 28, showBorder: false),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'OUR LADY OF FATIMA',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Eye, Ear, Nose & Throat Center',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(height: 1.5, color: Colors.grey.shade200),
                      const SizedBox(height: 12),

                      // Staff Name
                      Text(
                        staff.name,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatRole(staff.role),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Department / Station Info
                      Text(
                        'Dept: ${staff.department} • Station: ${staff.assignedRoom ?? "General"}',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // QR CODE
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: QrImageView(
                          data: staff.qrPayload,
                          version: QrVersions.auto,
                          size: 160,
                          gapless: true,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                          backgroundColor: Colors.white,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: color,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 6),
                      Text(
                        'Scan at any OLOF Kiosk for instant station access',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── Action Buttons ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _printBadge,
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Print Badge'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveBadgeLocally,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded, size: 16),
                      label: Text(_isSaving ? 'Saving...' : 'Save Image (PNG)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _copyQrData,
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copy QR Code Payload String', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
