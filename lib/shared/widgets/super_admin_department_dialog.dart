import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Shows a dialog allowing Super Administrator to choose any clinic department.
Future<void> showSuperAdminDepartmentPicker(
  BuildContext context, {
  String? adminName,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              adminName ?? 'Super Administrator',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'MASTER',
                                style: TextStyle(
                                  color: Color(0xFFD97706),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.5,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select your target station or clinical department:',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Cancel',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Department choices grid / list
              _DepartmentOptionTile(
                icon: Icons.medical_services_rounded,
                title: 'Doctor Station',
                subtitle: 'Conduct consultations, review drawings & prescribe (ENT / General)',
                color: const Color(0xFF059669),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/doctor');
                },
              ),
              const SizedBox(height: 10),
              _DepartmentOptionTile(
                icon: Icons.visibility_rounded,
                title: 'Optha Dept / Ophthalmology Station',
                subtitle: 'Ophthalmology queue management, call patients & room triage',
                color: AppColors.cyanCalm,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/secretary');
                },
              ),
              const SizedBox(height: 10),
              _DepartmentOptionTile(
                icon: Icons.medical_information_rounded,
                title: 'Nurse Clinical Station',
                subtitle: 'Patient triage, vital signs intake & anatomical drawing markup',
                color: const Color(0xFFEC4899),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/nurse');
                },
              ),
              const SizedBox(height: 10),
              _DepartmentOptionTile(
                icon: Icons.person_add_rounded,
                title: 'Receptionist Front Desk',
                subtitle: 'Patient registration, walk-in check-in & priority ticket issuance',
                color: AppColors.primary,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/receptionist');
                },
              ),
              const SizedBox(height: 10),
              _DepartmentOptionTile(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Admin Desktop Workstation',
                subtitle: 'Staff user management, clinic PC backups, doctor rooms & reports',
                color: const Color(0xFF065F46),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/admin');
                },
              ),
              const SizedBox(height: 10),
              _DepartmentOptionTile(
                icon: Icons.tv_rounded,
                title: 'Public TV Queue Display',
                subtitle: 'Public waiting hall queue display board',
                color: const Color(0xFF3B82F6),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/display');
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DepartmentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _DepartmentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
