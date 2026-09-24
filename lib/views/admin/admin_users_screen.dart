import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/clinic_provider.dart';
import '../../shared/widgets/staff_qr_badge_dialog.dart';
import '../receptionist/widgets/clinic_management_dialog.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _selectedRoleFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProv = context.watch<AdminProvider>();
    final clinicProv = context.watch<ClinicProvider>();

    // Build unified list of staff and doctors
    final List<Map<String, dynamic>> unifiedList = [];

    // Add station staff members from AdminProvider (excluding doctors to follow Supabase clinic_doctors)
    if (_selectedRoleFilter == 'ALL' || _selectedRoleFilter != 'doctor') {
      for (final staff in adminProv.staffList) {
        if (staff.role == 'doctor') continue;
        if (_selectedRoleFilter == 'ALL' ||
            staff.role.toLowerCase() == _selectedRoleFilter.toLowerCase()) {
          unifiedList.add({
            'id': staff.id,
            'name': staff.name,
            'role': staff.role,
            'department': staff.department,
            'room': staff.assignedRoom ?? 'None',
            'isActive': staff.isActive,
            'isDoctor': false,
            'rawStaff': staff,
          });
        }
      }
    }

    // Add dynamic clinic doctors from ClinicProvider (following Supabase clinic_doctors)
    if (_selectedRoleFilter == 'ALL' || _selectedRoleFilter == 'doctor') {
      for (final doc in clinicProv.doctors) {
        // Try to find matching StaffUser; if not found, create a synthetic one for QR
        final StaffUser? matched = adminProv.staffList.cast<StaffUser?>().firstWhere(
          (s) => s?.name.toLowerCase() == doc.name.toLowerCase(),
          orElse: () => null,
        );
        final defaultRoom = doc.department == AppConstants.deptEyes ? 'OPHTHA ROOM 1' : 'ENT ROOM 1';
        // Build a synthetic StaffUser so doctors always have a QR badge synced to Supabase
        final StaffUser docStaff = matched ?? StaffUser(
          id: doc.id,
          name: doc.name,
          role: 'doctor',
          department: doc.department,
          assignedRoom: doc.room ?? defaultRoom,
          qrSecret: 'olof-doc-${doc.id}',
          pin4: '3333',
        );
        unifiedList.add({
          'id': doc.id,
          'name': doc.name,
          'role': 'doctor',
          'department': doc.department,
          'room': doc.room ?? defaultRoom,
          'isActive': doc.isActive,
          'isDoctor': true,
          'rawStaff': docStaff,
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Management Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Staff & Personnel Management',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    'Manage active staff, QR cards, 4-digit PINs, and station roles.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.push('/auth/staff-cards'),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 17),
                    label: const Text('View All QR Cards'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showClinicManagementDialog(context, isDark: isDark),
                    icon: const Icon(Icons.medical_services_rounded, size: 17),
                    label: const Text('Doctor Rooms'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditStaffDialog(context, null),
                    icon: const Icon(Icons.person_add_rounded, size: 17),
                    label: const Text('Add Staff Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Role Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('All Personnel (${unifiedList.length})', 'ALL'),
              _buildFilterChip('Super Admin', 'super_admin'),
              _buildFilterChip('Doctors', 'doctor'),
              _buildFilterChip('Nurses', 'nurse'),
              _buildFilterChip('Reception', 'receptionist'),
              _buildFilterChip('Optha Dept', 'ophtha'),
              _buildFilterChip('Administrators', 'admin'),
            ],
          ),

          const SizedBox(height: 16),

          // Staff Data Table Card
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
                  width: 1.5,
                ),
              ),
              child: unifiedList.isEmpty
                  ? Center(
                      child: Text(
                        'No personnel found for selected filter.',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: unifiedList.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = unifiedList[index];
                        final isDoc = item['isDoctor'] as bool;
                        final role = item['role'] as String;
                        final roleColor = _getRoleColor(role);
                        final rawStaff = item['rawStaff'] as StaffUser?;

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: roleColor.withValues(alpha: 0.15),
                            child: Icon(
                              _getRoleIcon(role),
                              color: roleColor,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                item['name'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  role.toUpperCase(),
                                  style: TextStyle(
                                    color: roleColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              if (rawStaff != null && rawStaff.pin4.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_rounded, size: 10, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'PIN SET',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                            ],
                          ),
                          subtitle: Text(
                            'Dept: ${item['department']} | Assigned: ${item['room']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // QR Code Button — shown for ALL staff (including Supabase doctors)
                              if (rawStaff != null)
                                IconButton(
                                  icon: const Icon(Icons.qr_code_rounded, size: 20, color: AppColors.primary),
                                  tooltip: 'View QR Badge',
                                  onPressed: () => _showStaffQrDialog(context, rawStaff, isDark),
                                ),
                              Switch(
                                value: item['isActive'] as bool,
                                activeThumbColor: AppColors.success,
                                onChanged: (val) {
                                  if (isDoc) {
                                    clinicProv.toggleDoctorStatus(item['id'] as String);
                                  }
                                  if (rawStaff != null) {
                                    adminProv.toggleStaffActive(rawStaff.id);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                tooltip: 'Edit Staff Member',
                                onPressed: () {
                                  if (rawStaff != null) {
                                    _showAddEditStaffDialog(context, rawStaff);
                                  } else if (isDoc) {
                                    showClinicManagementDialog(context, isDark: isDark);
                                  }
                                },
                              ),
                              if (rawStaff != null && !isDoc)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                  tooltip: 'Delete Staff Member',
                                  onPressed: () => _confirmDelete(context, rawStaff),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedRoleFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedRoleFilter = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return const Color(0xFFF59E0B);
      case 'doctor':
        return AppColors.doctorPrimary;
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

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
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

  void _confirmDelete(BuildContext context, StaffUser staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff Member?'),
        content: Text('Are you sure you want to remove ${staff.name}? This will invalidate their QR login card.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              context.read<AdminProvider>().deleteStaff(staff.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStaffQrDialog(BuildContext context, StaffUser staff, bool isDark) {
    showStaffQrBadgeDialog(context, staff);
  }

  void _showAddEditStaffDialog(BuildContext context, StaffUser? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final pinCtrl = TextEditingController(
      text: existing?.pin4 ?? (1000 + Random().nextInt(9000)).toString(),
    );
    String role = existing?.role ?? 'nurse';
    String dept = existing?.department ?? 'ALL';
    String room = existing?.assignedRoom ?? 'Clinical Kiosk';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Add Staff Member' : 'Edit Staff Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name with Title',
                    hintText: 'e.g. Dr. Maria Santos, RN John Doe',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Staff Role'),
                  items: const [
                    DropdownMenuItem(value: 'doctor', child: Text('Doctor / Physician')),
                    DropdownMenuItem(value: 'nurse', child: Text('Triage Nurse')),
                    DropdownMenuItem(value: 'receptionist', child: Text('Receptionist')),
                    DropdownMenuItem(value: 'ophtha', child: Text('Optha Dept / Ophthalmology')),
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Administrator (Master)')),
                    DropdownMenuItem(value: 'admin', child: Text('Clinic Administrator')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        role = val;
                        if (val == 'ophtha') {
                          dept = 'EYES';
                          room = 'Ophtha Clinic';
                        } else if (val == 'doctor') {
                          room = 'ENT ROOM 1';
                        } else if (val == 'super_admin') {
                          dept = 'ALL';
                          room = 'All Stations';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: dept,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('ALL / General')),
                    DropdownMenuItem(value: 'ENT', child: Text('ENT (Ear, Nose, Throat)')),
                    DropdownMenuItem(value: 'EYES', child: Text('EYES (Ophthalmology)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => dept = val);
                  },
                ),
                const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                  initialValue: room,
                  decoration: const InputDecoration(labelText: 'Assigned Station / Room'),
                  items: const [
                    DropdownMenuItem(value: 'Clinical Kiosk', child: Text('Clinical Kiosk')),
                    DropdownMenuItem(value: 'Triage / Desk', child: Text('Triage / Front Desk')),
                    DropdownMenuItem(value: 'Ophtha Clinic', child: Text('Ophtha Clinic Station')),
                    DropdownMenuItem(value: 'ENT ROOM 1', child: Text('ENT ROOM 1')),
                    DropdownMenuItem(value: 'ENT ROOM 2', child: Text('ENT ROOM 2')),
                    DropdownMenuItem(value: 'OPHTHA ROOM 1', child: Text('OPHTHA ROOM 1')),
                    DropdownMenuItem(value: 'OPHTHA ROOM 2', child: Text('OPHTHA ROOM 2')),
                    DropdownMenuItem(value: 'OPHTHA ROOM 3', child: Text('OPHTHA ROOM 3')),
                    DropdownMenuItem(value: 'OPHTHA ROOM 4', child: Text('OPHTHA ROOM 4')),
                    DropdownMenuItem(value: 'Admin PC', child: Text('Admin PC')),
                    DropdownMenuItem(value: 'All Stations', child: Text('All Stations (Master)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => room = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: '4-Digit Login PIN',
                    hintText: 'e.g. 1234',
                    counterText: '',
                    helperText: 'Used as fallback on Windows desktop when camera is unavailable',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final adminProv = context.read<AdminProvider>();
                final pin = pinCtrl.text.trim().isEmpty ? '0000' : pinCtrl.text.trim();
                final StaffUser savedStaff;
                if (existing == null) {
                  savedStaff = StaffUser(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    role: role,
                    department: dept,
                    assignedRoom: room,
                    qrSecret: role == 'super_admin'
                        ? 'olof-super-admin-master-key-2026'
                        : const Uuid().v4(),
                    pin4: pin,
                  );
                  adminProv.addStaff(savedStaff);
                } else {
                  savedStaff = existing.copyWith(
                    name: nameCtrl.text.trim(),
                    role: role,
                    department: dept,
                    assignedRoom: room,
                    pin4: pin,
                  );
                  adminProv.updateStaff(savedStaff);
                }
                Navigator.pop(ctx);
                showStaffQrBadgeDialog(context, savedStaff, isNewlyCreated: existing == null);
              },
              child: const Text('Save & Generate QR Badge'),
            ),
          ],
        ),
      ),
    );
  }
}
