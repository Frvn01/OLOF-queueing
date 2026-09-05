import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/clinic_provider.dart';

/// Modal dialog allowing the receptionist to add and manage doctors and rooms one-by-one
Future<void> showClinicManagementDialog(
  BuildContext context, {
  bool isDark = false,
  int initialTab = 0, // 0 = Doctors, 1 = Rooms
}) async {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _ClinicManagementDialog(
      isDark: isDark,
      initialTab: initialTab,
    ),
  );
}

class _ClinicManagementDialog extends StatefulWidget {
  final bool isDark;
  final int initialTab;

  const _ClinicManagementDialog({
    required this.isDark,
    required this.initialTab,
  });

  @override
  State<_ClinicManagementDialog> createState() =>
      _ClinicManagementDialogState();
}

class _ClinicManagementDialogState extends State<_ClinicManagementDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Doctor Form
  final _doctorNameCtrl = TextEditingController();
  String? _selectedDoctorRoom;
  String _doctorDept = 'ENT'; // 'ENT', 'EYES', 'BOTH'
  bool _isAddingDoctor = false;

  // Room Form
  final _roomNameCtrl = TextEditingController();
  String _roomDept = 'BOTH'; // 'ENT', 'EYES', 'BOTH'
  bool _isAddingRoom = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _doctorNameCtrl.dispose();
    _roomNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitDoctor() async {
    final name = _doctorNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter doctor name')),
      );
      return;
    }

    setState(() => _isAddingDoctor = true);
    try {
      await context.read<ClinicProvider>().addDoctor(
            name: name,
            department: _doctorDept,
            room: (_selectedDoctorRoom != null && _selectedDoctorRoom!.trim().isNotEmpty)
                ? _selectedDoctorRoom!.trim()
                : null,
          );
      _doctorNameCtrl.clear();
      setState(() {
        _selectedDoctorRoom = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding doctor: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingDoctor = false);
    }
  }

  Future<void> _submitRoom() async {
    final name = _roomNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter room name or number')),
      );
      return;
    }

    setState(() => _isAddingRoom = true);
    try {
      await context.read<ClinicProvider>().addRoom(
            name: name,
            department: _roomDept,
          );
      _roomNameCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding room: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingRoom = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clinic Setup: Doctors & Rooms',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        Text(
                          'Add and manage clinic doctors & consultation rooms',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: subtitleColor, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceLight : AppColors.lightBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: subtitleColor,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.person_pin_rounded, size: 18),
                    text: 'Doctors',
                  ),
                  Tab(
                    icon: Icon(Icons.meeting_room_rounded, size: 18),
                    text: 'Rooms',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDoctorsTab(isDark, borderColor, titleColor, subtitleColor),
                  _buildRoomsTab(isDark, borderColor, titleColor, subtitleColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsTab(
    bool isDark,
    Color borderColor,
    Color titleColor,
    Color subtitleColor,
  ) {
    return Consumer<ClinicProvider>(
      builder: (context, clinic, _) {
        final doctors = clinic.doctors;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // Add Doctor Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceLight.withValues(alpha: 0.35)
                    : AppColors.lightBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'ADD NEW DOCTOR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Doctor Name
                  TextField(
                    controller: _doctorNameCtrl,
                    style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Doctor Name *',
                      hintText: 'e.g. Maria Santos',
                      prefixIcon: const Icon(Icons.person_rounded, size: 18),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 10),

                  // Department Selector (ENT, EYES, BOTH)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Specialization / Department:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildDeptRadio(
                            label: 'ENT',
                            value: 'ENT',
                            current: _doctorDept,
                            activeColor: AppColors.entColor,
                            onChanged: (v) => setState(() => _doctorDept = v),
                          ),
                          const SizedBox(width: 8),
                          _buildDeptRadio(
                            label: 'Eyes',
                            value: 'EYES',
                            current: _doctorDept,
                            activeColor: AppColors.eyesColor,
                            onChanged: (v) => setState(() => _doctorDept = v),
                          ),
                          const SizedBox(width: 8),
                          _buildDeptRadio(
                            label: 'Both / General',
                            value: 'BOTH',
                            current: _doctorDept,
                            activeColor: AppColors.cyanCalm,
                            onChanged: (v) => setState(() => _doctorDept = v),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Default Room Dropdown (fetches all available rooms)
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedDoctorRoom,
                    dropdownColor: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Default Room (Optional)',
                      hintText: 'Select assigned consultation room',
                      prefixIcon: const Icon(Icons.door_sliding_rounded, size: 18),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'None (No Default Room)',
                          style: TextStyle(
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ...clinic.rooms.map(
                        (r) => DropdownMenuItem<String?>(
                          value: r.name,
                          child: Row(
                            children: [
                              Text(
                                r.name,
                                style: TextStyle(
                                  color: titleColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: (r.department == 'ENT'
                                          ? AppColors.entColor
                                          : r.department == 'EYES'
                                              ? AppColors.eyesColor
                                              : AppColors.cyanCalm)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  r.department,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: r.department == 'ENT'
                                        ? AppColors.entColor
                                        : r.department == 'EYES'
                                            ? AppColors.eyesColor
                                            : AppColors.cyanCalm,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedDoctorRoom = v),
                  ),

                  const SizedBox(height: 14),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAddingDoctor ? null : _submitDoctor,
                      icon: _isAddingDoctor
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Doctor'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Doctors List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CURRENT DOCTORS (${doctors.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // List of doctors
            ...doctors.map((doc) {
              Color deptColor = doc.department == 'ENT'
                  ? AppColors.entColor
                  : (doc.department == 'EYES'
                      ? AppColors.eyesColor
                      : AppColors.cyanCalm);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceLight.withValues(alpha: 0.4)
                      : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: deptColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.medical_services_rounded,
                          color: deptColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: deptColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  doc.department,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: deptColor,
                                  ),
                                ),
                              ),
                              if (doc.room != null && doc.room!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '•  ${doc.room}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.urgent, size: 20),
                      tooltip: 'Remove Doctor',
                      onPressed: () => _confirmDelete(
                        context,
                        title: 'Remove Doctor',
                        message: 'Are you sure you want to remove ${doc.name}?',
                        onConfirm: () => clinic.removeDoctor(doc.id),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildRoomsTab(
    bool isDark,
    Color borderColor,
    Color titleColor,
    Color subtitleColor,
  ) {
    return Consumer<ClinicProvider>(
      builder: (context, clinic, _) {
        final rooms = clinic.rooms;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // Add Room Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceLight.withValues(alpha: 0.35)
                    : AppColors.lightBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'ADD NEW ROOM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Room Name
                  TextField(
                    controller: _roomNameCtrl,
                    style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Room Name / Number *',
                      hintText: 'e.g. Room 4, Consultation Room B',
                      prefixIcon: const Icon(Icons.door_sliding_rounded, size: 18),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 10),

                  // Department Selector (ENT, EYES, BOTH)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Designated Department:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildDeptRadio(
                            label: 'ENT',
                            value: 'ENT',
                            current: _roomDept,
                            activeColor: AppColors.entColor,
                            onChanged: (v) => setState(() => _roomDept = v),
                          ),
                          const SizedBox(width: 8),
                          _buildDeptRadio(
                            label: 'Eyes',
                            value: 'EYES',
                            current: _roomDept,
                            activeColor: AppColors.eyesColor,
                            onChanged: (v) => setState(() => _roomDept = v),
                          ),
                          const SizedBox(width: 8),
                          _buildDeptRadio(
                            label: 'Both',
                            value: 'BOTH',
                            current: _roomDept,
                            activeColor: AppColors.cyanCalm,
                            onChanged: (v) => setState(() => _roomDept = v),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAddingRoom ? null : _submitRoom,
                      icon: _isAddingRoom
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Room'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Rooms List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CURRENT ROOMS (${rooms.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // List of rooms
            ...rooms.map((room) {
              Color deptColor = room.department == 'ENT'
                  ? AppColors.entColor
                  : (room.department == 'EYES'
                      ? AppColors.eyesColor
                      : AppColors.cyanCalm);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceLight.withValues(alpha: 0.4)
                      : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: deptColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.door_sliding_rounded,
                          color: deptColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: deptColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              room.department,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: deptColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.urgent, size: 20),
                      tooltip: 'Remove Room',
                      onPressed: () => _confirmDelete(
                        context,
                        title: 'Remove Room',
                        message: 'Are you sure you want to remove ${room.name}?',
                        onConfirm: () => clinic.removeRoom(room.id),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildDeptRadio({
    required String label,
    required String value,
    required String current,
    required Color activeColor,
    required ValueChanged<String> onChanged,
  }) {
    final isSelected = current == value;

    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (widget.isDark
                      ? AppColors.surfaceLight
                      : AppColors.lightBorder),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.urgent),
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
