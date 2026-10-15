import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/doctor.dart';
import '../../providers/admin_provider.dart';
import '../../providers/clinic_provider.dart';
import '../../providers/doctor_provider.dart';
import 'qr_scanner_dialog.dart';

/// Hybrid Doctor Switcher Dialog:
/// - 1-Click quick profile switcher
/// - QR Badge Camera/Barcode Scanner support
class DoctorSwitcherDialog extends StatefulWidget {
  final bool navigateToDoctorOnSelect;

  const DoctorSwitcherDialog({
    super.key,
    this.navigateToDoctorOnSelect = false,
  });

  static Future<void> show(
    BuildContext context, {
    bool navigateToDoctorOnSelect = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DoctorSwitcherDialog(
        navigateToDoctorOnSelect: navigateToDoctorOnSelect,
      ),
    );
  }

  @override
  State<DoctorSwitcherDialog> createState() => _DoctorSwitcherDialogState();
}

class _DoctorSwitcherDialogState extends State<DoctorSwitcherDialog> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanDoctorQr() async {
    final scannedCode = await QrScannerDialog.show(
      context,
      title: 'Scan Doctor QR Badge',
    );

    if (scannedCode == null || scannedCode.trim().isEmpty) return;
    if (!mounted) return;

    final adminProv = context.read<AdminProvider>();
    final doctorProv = context.read<DoctorProvider>();
    final staff = adminProv.resolveQrPayload(scannedCode.trim());

    if (staff != null) {
      final defaultRoom = staff.department == AppConstants.deptEyes
          ? 'OPHTHA ROOM 1'
          : 'ENT ROOM 1';
      final room = staff.assignedRoom?.isNotEmpty == true
          ? staff.assignedRoom!
          : defaultRoom;

      doctorProv.selectDoctor(
        doctorName: staff.name,
        department: staff.department,
        room: room,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      if (widget.navigateToDoctorOnSelect) {
        context.go('/doctor');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${DoctorProvider.formatDoctorName(staff.name)} (${staff.department})'),
          backgroundColor: AppColors.doctorPrimary,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Fallback: check if the QR string directly matches a doctor name
    final clinicProv = context.read<ClinicProvider>();
    final matchedDoc = clinicProv.doctors.where((d) =>
        d.name.toLowerCase().contains(scannedCode.toLowerCase()) ||
        scannedCode.toLowerCase().contains(d.name.toLowerCase())).firstOrNull;

    if (matchedDoc != null) {
      doctorProv.selectDoctorModel(matchedDoc);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (widget.navigateToDoctorOnSelect) {
        context.go('/doctor');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${DoctorProvider.formatDoctorName(matchedDoc.name)}'),
          backgroundColor: AppColors.doctorPrimary,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unrecognized QR badge. Please try again or contact admin.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final doctorProv = context.watch<DoctorProvider>();
    final clinicProv = context.watch<ClinicProvider>();
    final adminProv = context.watch<AdminProvider>();

    // ── QR-ONLY mode: Doctor Workstation Access ─────────────────────────────
    if (widget.navigateToDoctorOnSelect) {
      return Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.doctorPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_hospital_rounded,
                              color: AppColors.doctorPrimary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Doctor Workstation',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Access restricted to registered QR badges only.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // QR icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.doctorPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.doctorPrimary.withValues(alpha: 0.25),
                        width: 2),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 50,
                    color: AppColors.doctorPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Scan Your QR Badge',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hold your staff QR badge in front of the camera\nor barcode scanner to authenticate.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Scan button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _scanDoctorQr,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                    label: const Text(
                      'Scan QR Badge to Enter',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.doctorPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Don't have your badge? Contact the clinic administrator.",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Manual switcher mode (Change Doctor Profile — internal use) ──────────
    final Map<String, Doctor> doctorsMap = {};

    for (final d in clinicProv.doctors) {
      doctorsMap[d.name.toLowerCase().trim()] = d;
    }

    for (final s in adminProv.staffList.where((s) => s.role.toLowerCase() == 'doctor' && s.isActive)) {
      final key = s.name.toLowerCase().trim();
      if (!doctorsMap.containsKey(key)) {
        doctorsMap[key] = Doctor(
          id: s.id,
          name: s.name,
          department: s.department,
          room: s.assignedRoom ?? (s.department == AppConstants.deptEyes ? 'OPHTHA ROOM 1' : 'ENT ROOM 1'),
        );
      }
    }

    List<Doctor> allDoctors = doctorsMap.values.toList();

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      allDoctors = allDoctors.where((d) =>
          d.name.toLowerCase().contains(q) ||
          d.department.toLowerCase().contains(q) ||
          (d.room != null && d.room!.toLowerCase().contains(q))).toList();
    }

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.switch_account_rounded, color: AppColors.doctorPrimary, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Change Doctor Profile',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Currently Active Doctor Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.doctorPrimary.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.doctorPrimary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.doctorPrimary,
                      child: Text(
                        doctorProv.activeDoctor.isNotEmpty
                            ? doctorProv.activeDoctor.substring(0, 1).toUpperCase()
                            : 'D',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                doctorProv.formattedDoctorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${doctorProv.activeDepartment} Clinic • ${doctorProv.activeRoom}',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Search Filter
              TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Filter by doctor name or department...',
                  hintStyle: const TextStyle(fontSize: 12.5),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Available Clinic Doctors',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey),
              ),

              const SizedBox(height: 6),

              // Doctors List
              Expanded(
                child: allDoctors.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'No doctors match "$_searchQuery"'
                              : 'No doctors configured in clinic database.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: allDoctors.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final doc = allDoctors[i];
                          final isSelected = doctorProv.activeDoctor.toLowerCase().trim() ==
                              doc.name.toLowerCase().trim();
                          final deptColor = doc.department.toUpperCase() == 'ENT'
                              ? AppColors.entColor
                              : AppColors.eyesColor;

                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.doctorPrimary.withValues(alpha: isDark ? 0.2 : 0.08)
                                  : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.doctorPrimary
                                    : (isDark ? Colors.white12 : Colors.grey.shade200),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              onTap: () {
                                doctorProv.selectDoctorModel(doc);
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Switched to ${DoctorProvider.formatDoctorName(doc.name)} (${doc.department})'),
                                    backgroundColor: AppColors.doctorPrimary,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelected ? AppColors.doctorPrimary : Colors.grey.shade400,
                                child: Text(
                                  doc.name.isNotEmpty ? doc.name.substring(0, 1).toUpperCase() : 'D',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      DoctorProvider.formatDoctorName(doc.name),
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: deptColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      doc.department,
                                      style: TextStyle(
                                        color: deptColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                doc.room ?? (doc.department == AppConstants.deptEyes ? 'OPHTHA ROOM 1' : 'ENT ROOM 1'),
                                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: AppColors.doctorPrimary, size: 20)
                                  : const Icon(Icons.radio_button_unchecked_rounded, size: 18, color: Colors.grey),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
