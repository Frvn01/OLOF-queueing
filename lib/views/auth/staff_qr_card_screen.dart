import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../shared/widgets/staff_qr_badge_dialog.dart';

/// Admin-only screen: shows every staff member's unique QR login card.
/// Admin can share / print these so staff can scan to log in.
class StaffQrCardScreen extends StatelessWidget {
  const StaffQrCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProv = context.watch<AdminProvider>();
    final staff = adminProv.staffList;

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
              // ── Header ──────────────────────────────────────────────────
              _buildHeader(context, isDark),
              // ── Grid of QR Cards ────────────────────────────────────────
              Expanded(
                child: staff.isEmpty
                    ? Center(
                        child: Text(
                          'No staff members found.\nAdd staff from Admin → Staff & Doctors.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 15,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: staff
                                .map((s) => _QrCard(staff: s, isDark: isDark))
                                .toList(),
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
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
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
                  'Staff QR Login Cards',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Print or share each card with the corresponding staff member.',
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
          // Info chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.primary),
                SizedBox(width: 5),
                Text(
                  'ADMIN ONLY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual QR Card Widget ─────────────────────────────────────────────────

class _QrCard extends StatelessWidget {
  final StaffUser staff;
  final bool isDark;

  const _QrCard({required this.staff, required this.isDark});

  Color get _roleColor {
    switch (staff.role.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return const Color(0xFFF59E0B);
      case 'doctor':
        return const Color(0xFF059669);
      case 'nurse':
        return const Color(0xFFEC4899);
      case 'receptionist':
        return AppColors.primary;
      case 'ophtha':
      case 'optha':
      case 'secretary':
        return AppColors.cyanCalm;
      case 'admin':
        return const Color(0xFF065F46);
      default:
        return Colors.grey;
    }
  }

  IconData get _roleIcon {
    switch (staff.role.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return Icons.shield_rounded;
      case 'doctor':
        return Icons.medical_services_rounded;
      case 'nurse':
        return Icons.healing_rounded;
      case 'receptionist':
        return Icons.desk_rounded;
      case 'ophtha':
      case 'optha':
      case 'secretary':
        return Icons.visibility_rounded;
      case 'admin':
        return Icons.security_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _roleColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coloured role header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _roleColor,
                  _roleColor.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_roleIcon, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        staff.role.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  staff.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${staff.department} · ${staff.assignedRoom ?? 'No room'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // QR Code
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: QrImageView(
              data: staff.qrPayload,
              version: QrVersions.auto,
              size: 160,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: isDark ? Colors.white : Colors.black,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: isDark ? Colors.white : Colors.black,
              ),
              backgroundColor: Colors.transparent,
            ),
          ),

          const SizedBox(height: 8),

          // Print & Save Badge Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => showStaffQrBadgeDialog(context, staff),
                icon: const Icon(Icons.print_rounded, size: 15),
                label: const Text('Print / Save Badge', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Instruction footer
          Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              'Scan QR on any OLOF kiosk for instant station access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
