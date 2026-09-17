import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/clinic_provider.dart';
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

    // Add dynamic clinic doctors from ClinicProvider
    if (_selectedRoleFilter == 'ALL' || _selectedRoleFilter == 'doctor') {
      for (final doc in clinicProv.doctors) {
        unifiedList.add({
          'id': doc.id,
          'name': doc.name,
          'role': 'doctor',
          'department': doc.department,
          'room': doc.room,
          'isActive': doc.isActive,
          'isDoctor': true,
        });
      }
    }

    // Add station staff members from AdminProvider
    if (_selectedRoleFilter == 'ALL' || _selectedRoleFilter != 'doctor') {
      for (final staff in adminProv.staffList) {
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
                    'Staff & Doctor Management',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    'Manage active clinical personnel, doctor room assignments, and station roles.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => showClinicManagementDialog(context, isDark: isDark),
                    icon: const Icon(Icons.medical_services_rounded, size: 17),
                    label: const Text('Manage Doctors & Rooms'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
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
            children: [
              _buildFilterChip('All Personnel', 'ALL'),
              _buildFilterChip('Doctors (${clinicProv.doctors.length})', 'doctor'),
              _buildFilterChip('Nurses', 'nurse'),
              _buildFilterChip('Reception', 'receptionist'),
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
                              if (isDoc) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.cyanCalm.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'SUPABASE SYNCED',
                                    style: TextStyle(
                                      color: AppColors.cyanCalm,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
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
                              Switch(
                                value: item['isActive'] as bool,
                                activeThumbColor: AppColors.success,
                                onChanged: (val) {
                                  if (isDoc) {
                                    clinicProv.toggleDoctorStatus(item['id'] as String);
                                  } else {
                                    adminProv.toggleStaffActive(item['id'] as String);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                onPressed: () {
                                  if (isDoc) {
                                    showClinicManagementDialog(context, isDark: isDark);
                                  } else {
                                    _showAddEditStaffDialog(
                                      context,
                                      item['rawStaff'] as StaffUser?,
                                    );
                                  }
                                },
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
      case 'doctor':
        return AppColors.doctorPrimary;
      case 'nurse':
        return const Color(0xFFEC4899);
      case 'receptionist':
        return const Color(0xFFF59E0B);
      case 'admin':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return Icons.medical_services_rounded;
      case 'nurse':
        return Icons.healing_rounded;
      case 'receptionist':
        return Icons.desk_rounded;
      case 'admin':
        return Icons.security_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  void _showAddEditStaffDialog(BuildContext context, StaffUser? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
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
                  decoration: const InputDecoration(labelText: 'Full Name with Title'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Staff Role'),
                  items: const [
                    DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
                    DropdownMenuItem(value: 'receptionist', child: Text('Receptionist')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => role = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: dept,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('ALL / General')),
                    DropdownMenuItem(value: 'ENT', child: Text('ENT')),
                    DropdownMenuItem(value: 'EYES', child: Text('EYES')),
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
                    DropdownMenuItem(value: 'Triage / Desk', child: Text('Triage / Desk')),
                    DropdownMenuItem(value: 'Admin PC', child: Text('Admin PC')),
                    DropdownMenuItem(value: 'Room 1', child: Text('Room 1')),
                    DropdownMenuItem(value: 'Room 2', child: Text('Room 2')),
                    DropdownMenuItem(value: 'Room 3', child: Text('Room 3 (Procedure)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => room = val);
                  },
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
                if (existing == null) {
                  adminProv.addStaff(
                    StaffUser(
                      id: const Uuid().v4(),
                      name: nameCtrl.text.trim(),
                      role: role,
                      department: dept,
                      assignedRoom: room,
                    ),
                  );
                } else {
                  adminProv.updateStaff(
                    existing.copyWith(
                      name: nameCtrl.text.trim(),
                      role: role,
                      department: dept,
                      assignedRoom: room,
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save Staff Member'),
            ),
          ],
        ),
      ),
    );
  }
}
