import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/patient_provider.dart';
import '../../providers/queue_provider.dart';
import '../../data/models/patient.dart';
import '../../shared/widgets/qr_scanner_dialog.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../providers/theme_provider.dart';
import '../../providers/clinic_provider.dart';
import '../../data/models/doctor.dart';
import '../../data/models/clinic_room.dart';
import '../../shared/widgets/searchable_picker_dialog.dart';
import 'widgets/clinic_management_dialog.dart';

/// Check-in screen — select department and purpose, then join queue
class CheckinScreen extends StatefulWidget {
  final String? patientId;
  final String? initialDoctor;
  final String? initialRoom;
  final String? initialDept;

  const CheckinScreen({
    super.key,
    this.patientId,
    this.initialDoctor,
    this.initialRoom,
    this.initialDept,
  });

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  Patient? _patient;
  String? _selectedDepartment;
  String? _selectedPurpose;
  Doctor? _selectedDoctor;
  ClinicRoom? _selectedRoom;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _assignedQueueNumber;

  // For QR / manual lookup
  final _patientNoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDept != null && widget.initialDept!.isNotEmpty) {
      _selectedDepartment = widget.initialDept;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initInitialDoctorAndRoom();
    });
    if (widget.patientId != null) {
      _loadPatient(widget.patientId!);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _initInitialDoctorAndRoom() {
    final clinic = context.read<ClinicProvider>();
    if (widget.initialDoctor != null && widget.initialDoctor!.isNotEmpty) {
      try {
        final doc = clinic.doctors.firstWhere(
          (d) => d.name.toLowerCase() == widget.initialDoctor!.toLowerCase(),
        );
        setState(() {
          _selectedDoctor = doc;
          if (_selectedDepartment == null && doc.department != 'BOTH') {
            _selectedDepartment = doc.department;
          }
        });
      } catch (_) {}
    }

    if (widget.initialRoom != null && widget.initialRoom!.isNotEmpty) {
      try {
        final r = clinic.rooms.firstWhere(
          (rm) => rm.name.toLowerCase() == widget.initialRoom!.toLowerCase(),
        );
        setState(() => _selectedRoom = r);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _patientNoController.dispose();
    super.dispose();
  }

  Future<void> _loadPatient(String id) async {
    final patient =
        await context.read<PatientProvider>().getPatientById(id);
    setState(() {
      _patient = patient;
      _isLoading = false;
    });
  }

  Future<void> _lookupByPatientNo() async {
    final no = _patientNoController.text.trim();
    if (no.isEmpty) return;
    setState(() => _isLoading = true);
    final patient =
        await context.read<PatientProvider>().getPatientByNo(no);
    setState(() {
      _patient = patient;
      _isLoading = false;
    });
    if (patient == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient not found in records')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 500;

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
              _buildHeader(context, isDark),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _assignedQueueNumber != null
                        ? _buildQueueAssigned(context, isDark, isCompact)
                        : _patient == null
                            ? _buildPatientLookup(context, isDark, isCompact)
                            : _buildCheckinForm(context, isDark, isCompact),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final headerBg = isDark ? AppColors.surfaceDark : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/receptionist'),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            ),
            tooltip: 'Back to Receptionist Station',
          ),
          const SizedBox(width: 4),
          const OlofLogo(size: 34, showBorder: true),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Patient Check-in',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.warning : AppColors.brandBlue,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientLookup(BuildContext context, bool isDark, bool isCompact) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 20 : 32,
          vertical: isCompact ? 20 : 32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isCompact ? 76 : 88,
                height: isCompact ? 76 : 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: isCompact ? 38 : 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Look Up Patient',
                style: TextStyle(
                  fontSize: isCompact ? 20 : 22,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Scan QR code pass or enter patient ID',
                style: TextStyle(
                  fontSize: 13.5,
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _patientNoController,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  labelText: 'Patient ID Number',
                  hintText: 'e.g. OLOF-2026-XXXX',
                  prefixIcon: const Icon(Icons.badge_rounded),
                  suffixIcon: IconButton(
                    onPressed: _lookupByPatientNo,
                    icon: const Icon(Icons.search_rounded),
                  ),
                ),
                onSubmitted: (_) => _lookupByPatientNo(),
              ),
              const SizedBox(height: 16),
              Text(
                '— OR —',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: subtitleColor,
                  letterSpacing: 1.0,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final scannedCode = await QrScannerDialog.show(context);
                  if (scannedCode != null && scannedCode.isNotEmpty) {
                    _patientNoController.text = scannedCode;
                    _lookupByPatientNo();
                  }
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan QR Code Camera'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckinForm(BuildContext context, bool isDark, bool isCompact) {
    final patient = _patient!;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 24,
          vertical: isCompact ? 16 : 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        patient.firstName.isNotEmpty
                            ? patient.firstName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.displayName,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${patient.patientNo}  •  ${patient.age} yrs  •  ${patient.sex}',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _patient = null),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Change patient',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Department Selection
              Text(
                'Select Medical Department *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDeptCard(
                      'ENT',
                      'Ear, Nose & Throat Center',
                      Icons.hearing_rounded,
                      AppColors.entColor,
                      AppColors.entGradient,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDeptCard(
                      'EYES',
                      'Ophthalmology Center',
                      Icons.visibility_rounded,
                      AppColors.eyesColor,
                      AppColors.eyesGradient,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Purpose Selection
              Text(
                'Purpose of Visit *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.visitPurposes.map((purpose) {
                  final isSelected = _selectedPurpose == purpose;
                  return ChoiceChip(
                    label: Text(purpose),
                    selected: isSelected,
                    onSelected: (s) =>
                        setState(() => _selectedPurpose = s ? purpose : null),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    labelStyle: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                    ),
                  );
                }).toList(),
              ),
                     const SizedBox(height: 24),

              // Doctor & Room Selection (Optional)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assign Doctor & Room (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => showClinicManagementDialog(context, isDark: isDark),
                    icon: const Icon(Icons.settings_rounded, size: 15),
                    label: const Text('Setup'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Doctor Selector
              _buildDoctorSelector(context, isDark),
              const SizedBox(height: 10),

              // Room Selector
              _buildRoomSelector(context, isDark),

              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedDepartment != null &&
                          _selectedPurpose != null &&
                          !_isSubmitting
                      ? _submitCheckin
                      : null,
                  icon: const Icon(Icons.confirmation_number_rounded),
                  label: Text(_isSubmitting
                      ? 'Assigning Queue Ticket...'
                      : 'Issue Queue Ticket'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    textStyle: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorSelector(BuildContext context, bool isDark) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.surfaceLight.withValues(alpha: 0.4) : AppColors.lightBg;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Consumer<ClinicProvider>(
      builder: (context, clinic, _) {
        final hasDoctor = _selectedDoctor != null;

        return Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () async {
              final doctors = clinic.getDoctors();
              final items = doctors
                  .map((d) => PickerItem<Doctor>(
                        value: d,
                        title: d.name,
                        subtitle: d.room != null && d.room!.isNotEmpty
                            ? 'Specialty: ${d.department} • Default Room: ${d.room}'
                            : 'Specialty: ${d.department}',
                        department: d.department,
                        icon: Icons.person_pin_rounded,
                      ))
                  .toList();

              final picked = await showSearchablePicker<Doctor>(
                context,
                title: 'Select Attending Doctor',
                searchHint: 'Search doctor name or specialty...',
                items: items,
                selectedValue: _selectedDoctor,
                isDark: isDark,
                addNewLabel: '+ Add Doctor',
                onAddNew: () => showClinicManagementDialog(context, isDark: isDark, initialTab: 0),
              );

              setState(() {
                _selectedDoctor = picked;
                if (picked != null && _selectedDepartment == null && picked.department != 'BOTH') {
                  _selectedDepartment = picked.department;
                }
                if (picked != null && _selectedRoom == null && picked.room != null) {
                  try {
                    _selectedRoom = clinic.rooms.firstWhere(
                      (r) => r.name.toLowerCase() == picked.room!.toLowerCase(),
                    );
                  } catch (_) {}
                }
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasDoctor ? AppColors.primary : borderColor,
                  width: hasDoctor ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medical_services_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasDoctor ? _selectedDoctor!.name : 'Choose Doctor',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: hasDoctor ? titleColor : subtitleColor,
                          ),
                        ),
                        Text(
                          hasDoctor
                              ? '${_selectedDoctor!.department} Attending Physician'
                              : 'Tap to filter and select doctor with search',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasDoctor)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: subtitleColor,
                      onPressed: () => setState(() => _selectedDoctor = null),
                      tooltip: 'Clear Doctor',
                    )
                  else
                    Icon(Icons.keyboard_arrow_down_rounded, color: subtitleColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomSelector(BuildContext context, bool isDark) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.surfaceLight.withValues(alpha: 0.4) : AppColors.lightBg;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;

    return Consumer<ClinicProvider>(
      builder: (context, clinic, _) {
        final hasRoom = _selectedRoom != null;

        return Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () async {
              final rooms = clinic.getRooms();
              final items = rooms
                  .map((r) => PickerItem<ClinicRoom>(
                        value: r,
                        title: r.name,
                        subtitle: 'Department: ${r.department}',
                        department: r.department,
                        icon: Icons.meeting_room_rounded,
                      ))
                  .toList();

              final picked = await showSearchablePicker<ClinicRoom>(
                context,
                title: 'Select Consultation Room',
                searchHint: 'Search room name or number...',
                items: items,
                selectedValue: _selectedRoom,
                isDark: isDark,
                addNewLabel: '+ Add Room',
                onAddNew: () => showClinicManagementDialog(context, isDark: isDark, initialTab: 1),
              );

              setState(() => _selectedRoom = picked);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasRoom ? AppColors.primary : borderColor,
                  width: hasRoom ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.cyanCalm.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.door_sliding_rounded,
                        color: AppColors.cyanCalm, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasRoom ? _selectedRoom!.name : 'Choose Consultation Room',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: hasRoom ? titleColor : subtitleColor,
                          ),
                        ),
                        Text(
                          hasRoom
                              ? 'Assigned to ${_selectedRoom!.name} (${_selectedRoom!.department})'
                              : 'Tap to filter and select room with search',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasRoom)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: subtitleColor,
                      onPressed: () => setState(() => _selectedRoom = null),
                      tooltip: 'Clear Room',
                    )
                  else
                    Icon(Icons.keyboard_arrow_down_rounded, color: subtitleColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeptCard(
    String dept,
    String label,
    IconData icon,
    Color color,
    LinearGradient gradient,
    bool isDark,
  ) {
    final isSelected = _selectedDepartment == dept;
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    return InkWell(
      onTap: () => setState(() => _selectedDepartment = dept),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : borderColor,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 12,
              ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              dept,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueAssigned(BuildContext context, bool isDark, bool isCompact) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 20 : 32,
          vertical: isCompact ? 20 : 32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const OlofLogo(size: 60, showBorder: true),
              const SizedBox(height: 14),
              Text(
                'Queue Ticket Assigned!',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: _selectedDepartment == 'ENT'
                      ? AppColors.entGradient
                      : AppColors.eyesGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.glowShadow(
                    _selectedDepartment == 'ENT'
                        ? AppColors.entColor
                        : AppColors.eyesColor,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _assignedQueueNumber ?? '',
                      style: TextStyle(
                        fontSize: isCompact ? 46 : 54,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      _selectedDepartment == 'ENT'
                          ? 'ENT Department'
                          : 'EYES Department',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    if (_selectedRoom != null || _selectedDoctor != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Proceed to ${_selectedRoom?.name ?? _selectedDoctor?.room ?? "Consultation Room"}${_selectedDoctor != null ? " • ${_selectedDoctor!.name}" : ""}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ticket has been synced with the Doctor station and Waiting Area TV Display.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/receptionist'),
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text('Back to Dashboard'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitCheckin() async {
    if (_patient == null ||
        _selectedDepartment == null ||
        _selectedPurpose == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final entry = await context.read<QueueProvider>().addToQueue(
            patientId: _patient!.id,
            patientName: _patient!.displayName,
            patientPhoto: _patient!.photoUrl,
            department: _selectedDepartment!,
            purpose: _selectedPurpose!,
            room: _selectedRoom?.name ?? _selectedDoctor?.room,
          );

      setState(() {
        _assignedQueueNumber = entry.queueNumber;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
