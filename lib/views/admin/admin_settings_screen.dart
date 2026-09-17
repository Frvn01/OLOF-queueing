import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/admin_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isBackingUp = false;

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final stats = adminProv.storageStats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Local Storage & System Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            'Manage Clinic PC local disk allocation, diagram archives, and data backups.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 24),

          // ── Architecture Status Banner ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Storage Architecture: Option A (Hybrid Safe Mode)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Database: Supabase Cloud Free Tier (pure text records, vital signs, complaints, nurse descriptions — well under 500 MB limit).\n'
                        '• Media & Diagrams: Saved directly to this Clinic PC hard drive, completely bypassing the 1 GB cloud storage limit with zero subscription fees.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Storage Usage Card ──────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storage_rounded, color: Color(0xFF0D9488)),
                      SizedBox(width: 10),
                      Text(
                        'Clinic PC Hard Drive Storage Status',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('Storage Directory', stats['location'] ?? 'Loading...'),
                  const Divider(height: 20),
                  _buildStatRow('Total Clinical Files (Drawings & Photos)', '${stats['totalFiles'] ?? 0} files'),
                  const Divider(height: 20),
                  _buildStatRow('Disk Space Consumed', stats['formattedSize'] ?? '0 MB'),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isBackingUp ? null : _runBackup,
                        icon: _isBackingUp
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.backup_rounded, size: 18),
                        label: Text(_isBackingUp ? 'Exporting Backup...' : 'Create Instant Local Backup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => adminProv.refreshStorageStats(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Refresh Disk Usage'),
                      ),
                    ],
                  ),
                  if (adminProv.lastBackupPath != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Last backup saved at: ${adminProv.lastBackupPath}',
                        style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Clinic Configuration Info ───────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_hospital_rounded, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text(
                        'Clinic Profile & Information',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('Center Name', AppConstants.clinicName),
                  const Divider(height: 20),
                  _buildStatRow('Specialty', AppConstants.clinicSubtitle),
                  const Divider(height: 20),
                  _buildStatRow('Address', AppConstants.clinicAddress),
                  const Divider(height: 20),
                  _buildStatRow('Phone', AppConstants.clinicPhone),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _runBackup() async {
    setState(() => _isBackingUp = true);
    final adminProv = context.read<AdminProvider>();
    final path = await adminProv.createBackup();
    if (!mounted) return;
    setState(() => _isBackingUp = false);

    if (path != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success),
              SizedBox(width: 8),
              Text('Backup Successful'),
            ],
          ),
          content: Text(
            'Full patient database and queue logs successfully exported to local clinic storage:\n\n$path',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup creation failed'), backgroundColor: AppColors.error),
      );
    }
  }
}
