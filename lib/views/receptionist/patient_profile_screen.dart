import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_image_helper.dart';
import '../../core/utils/helpers.dart';
import '../../providers/patient_provider.dart';
import '../../data/models/patient.dart';
import '../../data/models/patient_dept_record.dart';
import '../../data/models/visit_record.dart';
import '../../data/repositories/patient_dept_repository.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../providers/theme_provider.dart';
import '../../shared/widgets/photo_source_dialog.dart';
import '../../shared/widgets/pmh_medication_dialog.dart';
import '../../providers/queue_provider.dart';
import '../../providers/clinic_provider.dart';
import '../../data/models/doctor.dart';
import '../../data/models/clinic_room.dart';
import '../../shared/widgets/searchable_picker_dialog.dart';
import '../../shared/widgets/queue_ticket_print.dart';

/// Patient profile screen with details and visit history
class PatientProfileScreen extends StatefulWidget {
  final String patientId;

  const PatientProfileScreen({super.key, required this.patientId});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final PatientDeptRepository _deptRepo = PatientDeptRepository();
  List<PatientDeptRecord> _deptRecords = [];
  bool _uploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();
  String _selectedDeptTab = 'ENT'; // 'ENT' | 'EYES'
  String _visitFilter = 'ALL'; // 'ALL' | 'REGISTERED' | 'CONSULTATIONS' | 'OTHERS'

  @override
  void initState() {
    super.initState();
    _loadDeptRecords();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().selectPatient(widget.patientId);
    });
  }

  Future<void> _loadDeptRecords() async {
    try {
      final records = await _deptRepo.getAllRecords(widget.patientId);
      if (mounted) setState(() => _deptRecords = records);
    } catch (_) {}
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
          child: Consumer<PatientProvider>(
            builder: (context, provider, _) {
              final patient = provider.selectedPatient;
              if (patient == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  _buildHeader(context, patient, isDark, isCompact),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isCompact ? 14 : 20),
                      child: _buildContent(context, patient, provider, isDark, isCompact),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Patient patient, bool isDark, bool isCompact) {
    final headerBg = isDark ? AppColors.surfaceDark : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          const SizedBox(width: 2),
          const OlofLogo(size: 34, showBorder: true),
          const SizedBox(width: 8),
          // ── Profile Avatar in header ───────────────────────────────
          GestureDetector(
            onTap: () => _changePhoto(context, patient),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      isDark ? AppColors.surfaceLight : AppColors.lightSurfaceMid,
                  backgroundImage: AppImageHelper.buildImageProvider(patient.photoUrl),
                  child: patient.photoUrl == null || patient.photoUrl!.isEmpty
                      ? Icon(Icons.person_rounded, size: 22, color: subtitleColor)
                      : null,
                ),
                if (_uploadingPhoto)
                  const Positioned.fill(
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.black38,
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: headerBg,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  patient.displayName,
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: ${patient.patientNo}',
                  style: TextStyle(
                    fontSize: isCompact ? 11.5 : 12.5,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
            tooltip: 'Edit Patient Info',
            onPressed: () => _showEditPatientDialog(context, patient),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.warning : AppColors.brandBlue,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.urgent),
            tooltip: 'Delete Patient Record',
            onPressed: () => _confirmDeletePatient(context, patient),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: () => _showAddConsultationDialog(patient),
            icon: const Icon(Icons.confirmation_number_rounded, size: 16),
            label: Text(isCompact ? 'Consult' : 'Add Consultation'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 16,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Patient patient,
    PatientProvider provider,
    bool isDark,
    bool isCompact,
  ) {
    final isWide = MediaQuery.of(context).size.width > 800;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 2,
              child: _buildPatientDetails(context, patient, isDark, isCompact)),
          const SizedBox(width: 20),
          Expanded(child: _buildQRAndHistory(context, patient, provider, isDark)),
        ],
      );
    }

    return Column(
      children: [
        _buildPatientDetails(context, patient, isDark, isCompact),
        const SizedBox(height: 18),
        _buildQRAndHistory(context, patient, provider, isDark),
      ],
    );
  }

  Widget _buildPatientDetails(BuildContext context, Patient patient, bool isDark, bool isCompact) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile Photo + Name Card ────────────────────────────
          Row(
            children: [
              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.surfaceLight : AppColors.lightSurfaceMid,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 2.5,
                      ),
                      image: AppImageHelper.buildImageProvider(patient.photoUrl) != null
                          ? DecorationImage(
                              image: AppImageHelper.buildImageProvider(patient.photoUrl)!,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: patient.photoUrl == null || patient.photoUrl!.isEmpty
                        ? Icon(Icons.person_rounded, size: 34, color: subtitleColor)
                        : null,
                  ),
                  GestureDetector(
                    onTap: _uploadingPhoto ? null : () => _changePhoto(context, patient),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _uploadingPhoto ? Colors.grey : AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cardBg,
                          width: 2,
                        ),
                      ),
                      child: _uploadingPhoto
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${patient.age} yrs old  •  ${patient.sex}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        patient.patientNo,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Patient Medical Profile',
            style: TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          Divider(
            height: 22,
            color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
          ),
          _buildInfoRow('Full Legal Name', patient.fullName, isDark, isCompact),
          _buildInfoRow('Date of Birth', DateHelper.formatDate(patient.birthday), isDark, isCompact),
          _buildInfoRow('Age', '${patient.age} years old', isDark, isCompact),
          _buildInfoRow('Biological Sex', patient.sex, isDark, isCompact),
          _buildInfoRow('Civil Status', patient.civilStatus, isDark, isCompact),
          _buildInfoRow('Address', patient.address, isDark, isCompact),
          _buildInfoRow('Contact Number', patient.contactNumber, isDark, isCompact),
          if (patient.occupation != null && patient.occupation!.isNotEmpty)
            _buildInfoRow('Occupation', patient.occupation!, isDark, isCompact),
          if (patient.referredBy != null && patient.referredBy!.isNotEmpty)
            _buildInfoRow('Referred By', patient.referredBy!, isDark, isCompact),
          _buildInfoRow('Visit Status', patient.isFirstTime ? 'First-Time Check-up' : 'Returning Patient (Past History)', isDark, isCompact),
          if (patient.assignedDoctor != null && patient.assignedDoctor!.isNotEmpty)
            _buildInfoRow('Assigned Doctor', patient.assignedDoctor!, isDark, isCompact),
          if (patient.assignedRoom != null && patient.assignedRoom!.isNotEmpty)
            _buildInfoRow('Assigned Room', patient.assignedRoom!, isDark, isCompact),
          // ── Past Medical History & Maintenance Medications ─────────────────
          _buildPatientPmhSection(context, patient, isDark, isCompact),

          // ── Department Consultations & Clinical Records ────────────────────
          _buildConsultationsSection(context, patient, isDark, isCompact),
        ],
      ),
    );
  }

  Widget _buildConsultationsSection(
    BuildContext context,
    Patient patient,
    bool isDark,
    bool isCompact,
  ) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    // Records for the active tab
    final tabRecords = _deptRecords
        .where((r) => r.department.toUpperCase() == _selectedDeptTab)
        .toList();
    final isEyesTab = _selectedDeptTab == 'EYES';
    final tabColor = isEyesTab ? AppColors.cyanCalm : AppColors.brandBlue;
    final tabIcon = isEyesTab ? Icons.visibility_rounded : Icons.hearing_rounded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 24,
          color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
        ),

        // ── Header row ────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_shared_rounded, size: 18, color: AppColors.brandBlue),
                const SizedBox(width: 8),
                Text(
                  'Department Records',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddConsultationDialog(patient, preselectedDept: _selectedDeptTab),
              icon: const Icon(Icons.add_rounded, size: 15),
              label: Text(
                'Add $_selectedDeptTab Record',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: tabColor,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── ENT / EYES tab pills ──────────────────────────────────────────
        Row(
          children: [
            _buildDeptTabButton(
              label: 'ENT',
              icon: Icons.hearing_rounded,
              color: AppColors.brandBlue,
              isSelected: _selectedDeptTab == 'ENT',
              hasRecords: _deptRecords.any((r) => r.department.toUpperCase() == 'ENT'),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildDeptTabButton(
              label: 'EYES',
              icon: Icons.visibility_rounded,
              color: AppColors.cyanCalm,
              isSelected: _selectedDeptTab == 'EYES',
              hasRecords: _deptRecords.any((r) => r.department.toUpperCase() == 'EYES'),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Tab content ───────────────────────────────────────────────────
        if (tabRecords.isNotEmpty)
          ...tabRecords.map((dr) => _buildDeptRecordCard(dr, patient, isDark, isCompact))
        else
          // No record state for active tab
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tabColor.withValues(alpha: isDark ? 0.06 : 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tabColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(tabIcon, size: 36, color: tabColor.withValues(alpha: 0.35)),
                const SizedBox(height: 8),
                Text(
                  'No $_selectedDeptTab record found',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This patient has no $_selectedDeptTab consultation on file.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _showAddConsultationDialog(patient, preselectedDept: _selectedDeptTab),
                  icon: Icon(Icons.add_circle_outline_rounded, size: 16, color: tabColor),
                  label: Text(
                    'Register $_selectedDeptTab Consultation',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: tabColor),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Tab pill button for ENT / EYES switching
  Widget _buildDeptTabButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool hasRecords,
    required bool isDark,
  }) {
    final bg = isSelected
        ? color
        : color.withValues(alpha: isDark ? 0.12 : 0.08);
    final fgColor = isSelected ? Colors.white : color;
    final borderColor = isSelected ? color : color.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: () => setState(() => _selectedDeptTab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fgColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: fgColor,
              ),
            ),
            if (hasRecords) ...[
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeptRecordCard(
    PatientDeptRecord dr,
    Patient patient,
    bool isDark,
    bool isCompact,
  ) {
    final isEyes = dr.department.toUpperCase() == 'EYES';
    final deptColor = isEyes ? AppColors.cyanCalm : AppColors.brandBlue;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: deptColor.withValues(alpha: isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: deptColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: deptColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${dr.department.toUpperCase()} CLINIC',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Row(
                children: [
                  if (dr.assignedDoctor != null && dr.assignedDoctor!.isNotEmpty)
                    Text(
                      dr.assignedDoctor!,
                      style: TextStyle(fontSize: 11, color: subtitleColor, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => _showAddConsultationDialog(patient, preselectedDept: dr.department),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: deptColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.confirmation_number_rounded, size: 11, color: deptColor),
                          const SizedBox(width: 3),
                          Text(
                            'New Ticket',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: deptColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (dr.chiefComplaint != null && dr.chiefComplaint!.isNotEmpty)
            _buildInfoRow('Chief Complaint', dr.chiefComplaint!, isDark, isCompact),
          if (dr.historyOfPresentIllness != null && dr.historyOfPresentIllness!.isNotEmpty)
            _buildInfoRow('History of Illness', dr.historyOfPresentIllness!, isDark, isCompact),
        ],
      ),
    );
  }

  Future<void> _showAddConsultationDialog(Patient patient, {String? preselectedDept}) async {
    final themeProv = context.read<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final clinic = context.read<ClinicProvider>();

    final hasEnt = _deptRecords.any((r) => r.department.toUpperCase() == 'ENT');
    final hasEyes = _deptRecords.any((r) => r.department.toUpperCase() == 'EYES');

    String selectedDept = preselectedDept ??
        ((hasEyes && !hasEnt) ? 'ENT' : ((hasEnt && !hasEyes) ? 'EYES' : 'ENT'));
    String selectedPurpose = 'Consultation';
    Doctor? selectedDoctor;
    final matchingRooms = clinic.getRooms(department: selectedDept == 'BOTH' ? null : selectedDept);
    ClinicRoom? selectedRoom = matchingRooms.isNotEmpty ? matchingRooms.first : null;
    final complaintCtrl = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (dialogCtx, setSheetState) {
          final cardBg = isDark ? const Color(0xFF131D31) : Colors.white;
          final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
          final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
                width: 1.5,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.confirmation_number_rounded,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Consultation & Queue Ticket',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: titleColor,
                                ),
                              ),
                              Text(
                                '${patient.fullName} (${patient.patientNo})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Previous records notice
                    if (hasEyes || hasEnt) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (hasEyes && hasEnt)
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : (hasEyes ? AppColors.cyanCalm : AppColors.brandBlue)
                                  .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (hasEyes && hasEnt)
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : (hasEyes ? AppColors.cyanCalm : AppColors.brandBlue)
                                    .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 16,
                              color: hasEyes ? AppColors.cyanCalm : AppColors.brandBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasEyes && !hasEnt
                                    ? 'Patient has prior EYES history. Select ENT to register an ENT consultation.'
                                    : hasEnt && !hasEyes
                                        ? 'Patient has prior ENT history. Select EYES to register an EYES consultation.'
                                        : 'Patient has consultation records for both ENT & EYES.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 1. Department Selection
                    Text(
                      '1. Select Consultation Department',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDeptChoiceButton(
                            dept: 'ENT',
                            label: 'ENT Clinic',
                            icon: Icons.hearing_rounded,
                            color: AppColors.brandBlue,
                            isSelected: selectedDept == 'ENT',
                            onTap: () {
                              setSheetState(() {
                                selectedDept = 'ENT';
                                selectedDoctor = null;
                                final rooms = clinic.getRooms(department: 'ENT');
                                selectedRoom = rooms.isNotEmpty ? rooms.first : null;
                              });
                            },
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDeptChoiceButton(
                            dept: 'EYES',
                            label: 'EYES Clinic',
                            icon: Icons.visibility_rounded,
                            color: AppColors.cyanCalm,
                            isSelected: selectedDept == 'EYES',
                            onTap: () {
                              setSheetState(() {
                                selectedDept = 'EYES';
                                selectedDoctor = null;
                                final rooms = clinic.getRooms(department: 'EYES');
                                selectedRoom = rooms.isNotEmpty ? rooms.first : null;
                              });
                            },
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDeptChoiceButton(
                            dept: 'BOTH',
                            label: 'BOTH Clinics',
                            icon: Icons.sync_alt_rounded,
                            color: const Color(0xFF8B5CF6),
                            isSelected: selectedDept == 'BOTH',
                            onTap: () {
                              setSheetState(() {
                                selectedDept = 'BOTH';
                                selectedDoctor = null;
                                selectedRoom = null;
                              });
                            },
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 2. Purpose
                    Text(
                      '2. Purpose of Visit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['Consultation', 'Follow-up', 'Pre-operative', 'Post-operative', 'Other'].map((p) {
                        final isSel = selectedPurpose == p;
                        return ChoiceChip(
                          label: Text(p, style: TextStyle(fontSize: 11.5, fontWeight: isSel ? FontWeight.w800 : FontWeight.w600)),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setSheetState(() => selectedPurpose = p);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // 3. Chief Complaint
                    Text(
                      '3. Chief Complaint / Reason for Visit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: complaintCtrl,
                      maxLines: 2,
                      style: TextStyle(color: titleColor, fontWeight: FontWeight.w600, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: selectedDept == 'ENT'
                            ? 'e.g. Ear discharge, throat irritation, nasal obstruction...'
                            : selectedDept == 'EYES'
                                ? 'e.g. Blurred vision, eye pain, cataract check...'
                                : 'e.g. Ear symptoms and blurred vision in right eye...',
                        isDense: true,
                        prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Doctor & Room Selection
                    Text(
                      '4. Assign Doctor & Consultation Room (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Doctor Selector
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final doctors = clinic.getDoctors().where((d) {
                          if (selectedDept == 'BOTH') return true;
                          return d.department == selectedDept || d.department == 'BOTH';
                        }).toList();

                        final items = doctors.map((d) => PickerItem<Doctor>(
                          value: d,
                          title: d.name,
                          subtitle: 'Department: ${d.department}',
                          department: d.department,
                          icon: Icons.person_pin_rounded,
                        )).toList();

                        final picked = await showSearchablePicker<Doctor>(
                          dialogCtx,
                          title: 'Select Attending Doctor ($selectedDept)',
                          searchHint: 'Search doctor...',
                          items: items,
                          selectedValue: selectedDoctor,
                          isDark: isDark,
                        );

                        if (picked != null) {
                          setSheetState(() {
                            selectedDoctor = picked;
                            if (picked.room != null && picked.room!.isNotEmpty) {
                              try {
                                selectedRoom = clinic.rooms.firstWhere(
                                  (r) => r.name.toLowerCase() == picked.room!.toLowerCase(),
                                );
                              } catch (_) {}
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.surfaceLight : AppColors.lightBg).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedDoctor != null
                                ? AppColors.primary
                                : (isDark ? AppColors.surfaceHover : AppColors.lightBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.medical_services_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedDoctor?.name ?? 'Assign Attending Doctor (Optional)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selectedDoctor != null ? FontWeight.w800 : FontWeight.w500,
                                  color: selectedDoctor != null ? titleColor : subtitleColor,
                                ),
                              ),
                            ),
                            if (selectedDoctor != null)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () => setSheetState(() => selectedDoctor = null),
                                visualDensity: VisualDensity.compact,
                              )
                            else
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Room Selector
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final rooms = clinic.getRooms().where((r) {
                          if (selectedDept == 'BOTH') return true;
                          return r.department == selectedDept || r.department == 'BOTH';
                        }).toList();

                        final items = rooms.map((r) => PickerItem<ClinicRoom>(
                          value: r,
                          title: r.name,
                          subtitle: 'Department: ${r.department}',
                          department: r.department,
                          icon: Icons.meeting_room_rounded,
                        )).toList();

                        final picked = await showSearchablePicker<ClinicRoom>(
                          dialogCtx,
                          title: 'Select Consultation Room ($selectedDept)',
                          searchHint: 'Search room...',
                          items: items,
                          selectedValue: selectedRoom,
                          isDark: isDark,
                        );

                        if (picked != null) {
                          setSheetState(() => selectedRoom = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.surfaceLight : AppColors.lightBg).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedRoom != null
                                ? AppColors.cyanCalm
                                : (isDark ? AppColors.surfaceHover : AppColors.lightBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.door_sliding_rounded, size: 18, color: AppColors.cyanCalm),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedRoom?.name ?? 'Assign Consultation Room (Optional)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selectedRoom != null ? FontWeight.w800 : FontWeight.w500,
                                  color: selectedRoom != null ? titleColor : subtitleColor,
                                ),
                              ),
                            ),
                            if (selectedRoom != null)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () => setSheetState(() => selectedRoom = null),
                                visualDensity: VisualDensity.compact,
                              )
                            else
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit: Issue Queue Ticket & Print
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting ? null : () async {
                          setSheetState(() => isSubmitting = true);
                          try {
                            final queueProv = context.read<QueueProvider>();
                            final patientProv = context.read<PatientProvider>();
                            final scaffoldMsg = ScaffoldMessenger.of(context);
                            final complaint = complaintCtrl.text.trim();
                            final doctorName = selectedDoctor?.name;
                            final roomName = selectedRoom?.name;

                            final ticketsToPrint = <QueueTicketData>[];

                            if (selectedDept == 'BOTH') {
                              // ENT ticket & record
                              final entEntry = await queueProv.addToQueue(
                                patientId: patient.id,
                                patientName: patient.displayName,
                                patientPhoto: patient.photoUrl,
                                department: 'ENT',
                                purpose: selectedPurpose,
                                doctor: doctorName,
                                room: roomName,
                              );
                              final entRecord = PatientDeptRecord(
                                id: IdGenerator.generateUuid(),
                                patientId: patient.id,
                                department: 'ENT',
                                chiefComplaint: complaint.isNotEmpty ? complaint : null,
                                pastMedicalHistory: patient.pastMedicalHistory,
                                pmhConditions: patient.pmhConditionsList,
                                isFirstTime: !hasEnt,
                                assignedDoctor: doctorName,
                                assignedRoom: roomName,
                              );
                              await _deptRepo.upsert(entRecord);
                              try {
                                await patientProv.addVisitRecord(VisitRecord(
                                  id: IdGenerator.generateUuid(),
                                  patientId: patient.id,
                                  department: 'ENT',
                                  purpose: selectedPurpose,
                                  chiefComplaint: complaint.isNotEmpty ? complaint : null,
                                  assignedDoctor: doctorName,
                                  assignedRoom: roomName,
                                  notes: [
                                    'Consultation added at reception.',
                                    if (doctorName != null) 'Doctor: $doctorName',
                                    if (roomName != null) 'Room: $roomName',
                                  ].join(' • '),
                                  queueNumber: entEntry.queueNumber,
                                  visitDate: DateTime.now(),
                                ));
                              } catch (_) {}
                              ticketsToPrint.add(QueueTicketData(
                                queueNumber: entEntry.queueNumber,
                                patientName: patient.displayName,
                                department: 'ENT',
                                doctorName: doctorName,
                                roomName: roomName,
                                purpose: selectedPurpose,
                              ));

                              // EYES ticket & record
                              final eyesEntry = await queueProv.addToQueue(
                                patientId: patient.id,
                                patientName: patient.displayName,
                                patientPhoto: patient.photoUrl,
                                department: 'EYES',
                                purpose: selectedPurpose,
                                doctor: doctorName,
                                room: roomName,
                              );
                              final eyesRecord = PatientDeptRecord(
                                id: IdGenerator.generateUuid(),
                                patientId: patient.id,
                                department: 'EYES',
                                chiefComplaint: complaint.isNotEmpty ? complaint : null,
                                pastMedicalHistory: patient.pastMedicalHistory,
                                pmhConditions: patient.pmhConditionsList,
                                isFirstTime: !hasEyes,
                                assignedDoctor: doctorName,
                                assignedRoom: roomName,
                              );
                              await _deptRepo.upsert(eyesRecord);
                              try {
                                await patientProv.addVisitRecord(VisitRecord(
                                  id: IdGenerator.generateUuid(),
                                  patientId: patient.id,
                                  department: 'EYES',
                                  purpose: selectedPurpose,
                                  chiefComplaint: complaint.isNotEmpty ? complaint : null,
                                  assignedDoctor: doctorName,
                                  assignedRoom: roomName,
                                  notes: [
                                    'Consultation added at reception.',
                                    if (doctorName != null) 'Doctor: $doctorName',
                                    if (roomName != null) 'Room: $roomName',
                                  ].join(' • '),
                                  queueNumber: eyesEntry.queueNumber,
                                  visitDate: DateTime.now(),
                                ));
                              } catch (_) {}
                              ticketsToPrint.add(QueueTicketData(
                                queueNumber: eyesEntry.queueNumber,
                                patientName: patient.displayName,
                                department: 'EYES',
                                doctorName: doctorName,
                                roomName: roomName,
                                purpose: selectedPurpose,
                              ));
                            } else {
                              // Single department (ENT or EYES)
                              final entry = await queueProv.addToQueue(
                                patientId: patient.id,
                                patientName: patient.displayName,
                                patientPhoto: patient.photoUrl,
                                department: selectedDept,
                                purpose: selectedPurpose,
                                doctor: doctorName,
                                room: roomName,
                              );
                              final isFirst = selectedDept == 'ENT' ? !hasEnt : !hasEyes;
                              final deptRecord = PatientDeptRecord(
                                id: IdGenerator.generateUuid(),
                                patientId: patient.id,
                                department: selectedDept,
                                chiefComplaint: complaint.isNotEmpty ? complaint : null,
                                pastMedicalHistory: patient.pastMedicalHistory,
                                pmhConditions: patient.pmhConditionsList,
                                isFirstTime: isFirst,
                                assignedDoctor: doctorName,
                                assignedRoom: roomName,
                              );
                              await _deptRepo.upsert(deptRecord);
                              try {
                                await patientProv.addVisitRecord(VisitRecord(
                                  id: IdGenerator.generateUuid(),
                                  patientId: patient.id,
                                  department: selectedDept,
                                  purpose: selectedPurpose,
                                  chiefComplaint: complaint.isNotEmpty ? complaint : null,
                                  assignedDoctor: doctorName,
                                  assignedRoom: roomName,
                                  notes: [
                                    'Consultation added at reception.',
                                    if (doctorName != null) 'Doctor: $doctorName',
                                    if (roomName != null) 'Room: $roomName',
                                  ].join(' • '),
                                  queueNumber: entry.queueNumber,
                                  visitDate: DateTime.now(),
                                ));
                              } catch (_) {}
                              ticketsToPrint.add(QueueTicketData(
                                queueNumber: entry.queueNumber,
                                patientName: patient.displayName,
                                department: selectedDept,
                                doctorName: doctorName,
                                roomName: roomName,
                                purpose: selectedPurpose,
                              ));
                            }

                            // Sync patient profile fields if provided
                            if (complaint.isNotEmpty || doctorName != null || roomName != null) {
                              final updatedPatient = patient.copyWith(
                                chiefComplaint: complaint.isNotEmpty ? complaint : patient.chiefComplaint,
                                assignedDoctor: doctorName ?? patient.assignedDoctor,
                                assignedRoom: roomName ?? patient.assignedRoom,
                              );
                              await patientProv.updatePatient(updatedPatient);
                            }

                            await _loadDeptRecords();

                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              Navigator.pop(sheetCtx);

                              for (final t in ticketsToPrint) {
                                await showQueueTicketPrintDialog(
                                  // ignore: use_build_context_synchronously
                                  context,
                                  ticket: t,
                                  isDark: isDark,
                                );
                              }

                              scaffoldMsg.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ticketsToPrint.length > 1
                                        ? 'Issued queue tickets: ${ticketsToPrint.map((t) => t.queueNumber).join(" & ")}!'
                                        : 'Issued queue ticket ${ticketsToPrint.first.queueNumber}!',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (err) {
                            setSheetState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error issuing consultation ticket: $err')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.print_rounded),
                        label: Text(
                          isSubmitting
                              ? 'Assigning Queue Ticket...'
                              : 'Issue Queue Ticket & Print',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: selectedDept == 'ENT'
                              ? AppColors.brandBlue
                              : selectedDept == 'EYES'
                                  ? AppColors.cyanCalm
                                  : const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeptChoiceButton({
    required String dept,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark ? AppColors.surfaceLight : AppColors.lightBg),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (isDark ? AppColors.surfaceHover : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : (isDark ? Colors.white60 : Colors.black54), size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : (isDark ? Colors.white70 : Colors.black87),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientPmhSection(
    BuildContext context,
    Patient patient,
    bool isDark,
    bool isCompact,
  ) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.surfaceLight.withValues(alpha: 0.35) : AppColors.lightBg;
    final borderColor = isDark ? AppColors.surfaceHover : AppColors.lightBorder;

    final conditions = patient.pmhConditionsList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 24,
          color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.medication_liquid_rounded, size: 18, color: AppColors.brandBlue),
                const SizedBox(width: 8),
                Text(
                  'Past Medical History & Medications',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showAddConditionDialog(patient),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
              label: const Text('Add Condition', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (conditions.isEmpty && (patient.pastMedicalHistory == null || patient.pastMedicalHistory!.isEmpty))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 16, color: subtitleColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No past medical conditions or maintenance medications recorded.',
                    style: TextStyle(fontSize: 12.5, color: subtitleColor),
                  ),
                ),
                TextButton(
                  onPressed: () => _showAddConditionDialog(patient),
                  child: const Text('+ Add Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          )
        else
          Column(
            children: conditions.map((c) {
              final condColor = _getPmhColor(c.condition);
              final condIcon = _getPmhIcon(c.condition);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: condColor.withValues(alpha: isDark ? 0.12 : 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: condColor.withValues(alpha: 0.28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Condition Header Row
                    Row(
                      children: [
                        Icon(condIcon, size: 16, color: condColor),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            c.condition,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: condColor,
                            ),
                          ),
                        ),
                        // Edit Medications Button
                        Tooltip(
                          message: 'Edit medications for ${c.condition}',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _editConditionMeds(patient, c.condition, c.medications),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_rounded, size: 12.5, color: condColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Edit Meds',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: condColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Remove Condition Button
                        Tooltip(
                          message: 'Remove ${c.condition}',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _removeCondition(patient, c.condition),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: subtitleColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Medications Chips
                    if (c.medications.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ...c.medications.map((m) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: condColor.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.medication_rounded, size: 12, color: condColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    m,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _editConditionMeds(patient, c.condition, c.medications),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: condColor.withValues(alpha: 0.35),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 12, color: condColor),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Add Med',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: condColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _editConditionMeds(patient, c.condition, c.medications),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: condColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: condColor.withValues(alpha: 0.35),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, size: 13, color: condColor),
                              const SizedBox(width: 4),
                              Text(
                                'No medications listed — tap to add medications (e.g. Amlodipine, Losartan)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: condColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _editConditionMeds(
    Patient patient,
    String conditionName,
    List<String> currentMeds,
  ) async {
    final themeProv = context.read<ThemeProvider>();
    final isDark = themeProv.isDarkMode;

    final result = await showPmhMedicationDialog(
      context,
      conditionName: conditionName,
      existingMeds: currentMeds,
      isDark: isDark,
    );

    if (result == null) return;

    final currentConditions = List<PmhCondition>.from(patient.pmhConditionsList);
    final idx = currentConditions.indexWhere(
      (c) => c.condition.toLowerCase() == conditionName.toLowerCase(),
    );

    if (idx >= 0) {
      currentConditions[idx] = PmhCondition(
        condition: currentConditions[idx].condition,
        medications: result,
      );
    } else {
      currentConditions.add(PmhCondition(
        condition: conditionName,
        medications: result,
      ));
    }

    final knownKeywords = ['hypertension', 'dm', 'diabetes', 'allergies', 'operations', 'medications', 'glaucoma'];
    final otherConditions = currentConditions.where(
      (c) => !knownKeywords.any((k) => c.condition.toLowerCase().contains(k)) && c.medications.isEmpty,
    ).map((c) => c.condition).toList();
    final otherText = otherConditions.isNotEmpty ? otherConditions.join(', ') : null;

    final formatted = PmhCondition.formatList(
      currentConditions.where((c) => knownKeywords.any((k) => c.condition.toLowerCase().contains(k)) || c.medications.isNotEmpty).toList(),
      otherText,
    );

    final updated = patient.copyWith(
      pastMedicalHistory: formatted.isEmpty ? null : formatted,
    );

    if (!mounted) return;
    await context.read<PatientProvider>().updatePatient(updated);

    if (_deptRecords.isNotEmpty) {
      for (final dr in _deptRecords) {
        final updatedDept = dr.copyWith(
          pastMedicalHistory: updated.pastMedicalHistory,
          pmhConditions: updated.pmhConditionsList,
        );
        await _deptRepo.upsert(updatedDept);
      }
      await _loadDeptRecords();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated medications for $conditionName'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _removeCondition(
    Patient patient,
    String conditionName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Condition?'),
        content: Text('Are you sure you want to remove "$conditionName" and its medications from this patient profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.urgent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final currentConditions = List<PmhCondition>.from(patient.pmhConditionsList)
      ..removeWhere((c) => c.condition.toLowerCase() == conditionName.toLowerCase());

    final knownKeywords = ['hypertension', 'dm', 'diabetes', 'allergies', 'operations', 'medications', 'glaucoma'];
    final otherConditions = currentConditions.where(
      (c) => !knownKeywords.any((k) => c.condition.toLowerCase().contains(k)) && c.medications.isEmpty,
    ).map((c) => c.condition).toList();
    final otherText = otherConditions.isNotEmpty ? otherConditions.join(', ') : null;

    final formatted = PmhCondition.formatList(
      currentConditions.where((c) => knownKeywords.any((k) => c.condition.toLowerCase().contains(k)) || c.medications.isNotEmpty).toList(),
      otherText,
    );

    final updated = patient.copyWith(
      pastMedicalHistory: formatted.isEmpty ? null : formatted,
    );

    if (!mounted) return;
    await context.read<PatientProvider>().updatePatient(updated);

    if (_deptRecords.isNotEmpty) {
      for (final dr in _deptRecords) {
        final updatedDept = dr.copyWith(
          pastMedicalHistory: updated.pastMedicalHistory,
          pmhConditions: updated.pmhConditionsList,
        );
        await _deptRepo.upsert(updatedDept);
      }
      await _loadDeptRecords();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed $conditionName from medical profile'),
          backgroundColor: AppColors.urgent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAddConditionDialog(Patient patient) async {
    final standardOptions = [
      'Hypertension',
      'Diabetes Mellitus',
      'Allergies',
      'Glaucoma',
      'Operations',
      'Other Condition...',
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Add Past Medical Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        children: standardOptions.map((opt) {
          final isOther = opt.startsWith('Other');
          final icon = isOther ? Icons.edit_note_rounded : _getPmhIcon(opt);
          final color = isOther ? AppColors.brandBlue : _getPmhColor(opt);
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, opt),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 12),
                Text(opt, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (selected == null) return;

    String conditionName = selected;
    if (selected.startsWith('Other')) {
      if (!mounted) return;
      final customCtrl = TextEditingController();
      final customName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enter Condition Name'),
          content: TextField(
            controller: customCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Condition / Illness',
              hintText: 'e.g. Asthma, Thyroid disease',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, customCtrl.text.trim()),
              child: const Text('Next'),
            ),
          ],
        ),
      );
      if (customName == null || customName.isEmpty) return;
      conditionName = customName;
    }

    if (!mounted) return;
    await _editConditionMeds(patient, conditionName, []);
  }

  Color _getPmhColor(String condition) {
    switch (condition) {
      case 'Hypertension':
        return AppColors.urgent;
      case 'Diabetes Mellitus':
      case 'DM':
        return AppColors.warning;
      case 'Allergies':
        return AppColors.onHold;
      case 'Glaucoma':
        return AppColors.cyanCalm;
      default:
        return AppColors.brandBlue;
    }
  }

  IconData _getPmhIcon(String condition) {
    switch (condition) {
      case 'Hypertension':
        return Icons.favorite_rounded;
      case 'Diabetes Mellitus':
      case 'DM':
        return Icons.bloodtype_rounded;
      case 'Allergies':
        return Icons.warning_amber_rounded;
      case 'Glaucoma':
        return Icons.visibility_rounded;
      case 'Operations':
        return Icons.healing_rounded;
      default:
        return Icons.medication_rounded;
    }
  }

  Widget _buildInfoRow(String label, String value, bool isDark, bool isCompact) {
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isCompact ? 125 : 155,
            child: Text(
              label,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRAndHistory(
    BuildContext context,
    Patient patient,
    PatientProvider provider,
    bool isDark,
  ) {
    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Column(
      children: [
        // QR Code Card
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            children: [
              Text(
                'Patient QR Pass',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: patient.patientNo,
                  version: QrVersions.auto,
                  size: 150,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0369A1),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                patient.patientNo,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Visit History
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title, Add Visit button, and refresh button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history_edu_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visit History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        Text(
                          'Timeline of registrations, consultations & follow-ups',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddConsultationDialog(patient),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Visit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (provider.visitsLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    Tooltip(
                      message: 'Refresh visit history',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => context
                            .read<PatientProvider>()
                            .selectPatient(patient.id),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: subtitleColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              if (provider.visitsLoading && provider.selectedPatientVisits.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading visit history…',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    final rawVisits = provider.selectedPatientVisits;
                    final List<VisitRecord> allVisits = [...rawVisits];

                    // Backfill initial registration event if not yet recorded
                    final hasRegVisit = allVisits.any((v) => v.isRegistration);
                    if (!hasRegVisit) {
                      allVisits.add(
                        VisitRecord(
                          id: 'initial-reg-${patient.id}',
                          patientId: patient.id,
                          department: _deptRecords.isNotEmpty ? _deptRecords.first.department : 'ENT',
                          purpose: 'Initial Registration',
                          chiefComplaint: patient.chiefComplaint,
                          assignedDoctor: patient.assignedDoctor,
                          assignedRoom: patient.assignedRoom,
                          notes: 'Patient registered in clinic records.',
                          queueNumber: 'REG-${patient.patientNo}',
                          visitDate: patient.createdAt,
                        ),
                      );
                    }
                    allVisits.sort((a, b) => b.visitDate.compareTo(a.visitDate));

                    final regCount = allVisits.where((v) => v.isRegistration).length;
                    final consultCount = allVisits.where((v) => v.isConsultation).length;
                    final otherCount = allVisits.where((v) => v.isOther).length;

                    final displayedVisits = allVisits.where((v) {
                      if (_visitFilter == 'REGISTERED') return v.isRegistration;
                      if (_visitFilter == 'CONSULTATIONS') return v.isConsultation;
                      if (_visitFilter == 'OTHERS') return v.isOther;
                      return true;
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter Pills: All, Registered, Consultations, Others
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildVisitFilterChip(
                                label: 'All',
                                count: allVisits.length,
                                value: 'ALL',
                                color: AppColors.primary,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 8),
                              _buildVisitFilterChip(
                                label: 'Registered',
                                count: regCount,
                                value: 'REGISTERED',
                                color: const Color(0xFF10B981), // Emerald
                                isDark: isDark,
                              ),
                              const SizedBox(width: 8),
                              _buildVisitFilterChip(
                                label: 'Consultations',
                                count: consultCount,
                                value: 'CONSULTATIONS',
                                color: AppColors.brandBlue,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 8),
                              _buildVisitFilterChip(
                                label: 'Others',
                                count: otherCount,
                                value: 'OTHERS',
                                color: const Color(0xFFF59E0B), // Amber
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (displayedVisits.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  Icon(Icons.history_rounded, size: 32, color: subtitleColor),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No ${_visitFilter.toLowerCase()} visits found',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...displayedVisits.map(
                            (visit) => _buildVisitCard(context, visit, isDark),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisitFilterChip({
    required String label,
    required int count,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _visitFilter == value;
    final bg = isSelected
        ? color
        : color.withValues(alpha: isDark ? 0.14 : 0.08);
    final fg = isSelected ? Colors.white : color;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _visitFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: fg,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCard(BuildContext context, VisitRecord visit, bool isDark) {
    final deptColor = visit.department == 'ENT'
        ? AppColors.entColor
        : AppColors.eyesColor;
    final itemBg = isDark ? AppColors.surfaceLight : AppColors.lightSurfaceMid;
    final borderColor = isDark ? AppColors.surfaceHover : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    // Category styling
    final Color categoryColor;
    final IconData categoryIcon;
    final String categoryLabel;

    if (visit.isRegistration) {
      categoryColor = const Color(0xFF10B981); // Emerald
      categoryIcon = Icons.how_to_reg_rounded;
      categoryLabel = 'Registered';
    } else if (visit.isConsultation) {
      categoryColor = AppColors.brandBlue;
      categoryIcon = Icons.medical_services_rounded;
      categoryLabel = 'Consultation';
    } else {
      categoryColor = const Color(0xFFF59E0B); // Amber
      categoryIcon = Icons.event_note_rounded;
      categoryLabel = visit.purpose;
    }

    final doctor = visit.doctorDisplay;
    final hasDiagnosis = visit.diagnosis != null && visit.diagnosis!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top badges and queue number (wrapped to prevent overflow on narrow screens)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon, size: 12, color: categoryColor),
                        const SizedBox(width: 4),
                        Text(
                          categoryLabel,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Department Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: deptColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: deptColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      visit.department,
                      style: TextStyle(
                        color: deptColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              // Queue Number Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white10 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.confirmation_number_rounded,
                        size: 11, color: subtitleColor),
                    const SizedBox(width: 4),
                    Text(
                      visit.queueNumber,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Visit Purpose Title
          Text(
            visit.purpose,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: titleColor,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 4),

          // Date & Time
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 13, color: subtitleColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  DateHelper.formatDateTime(visit.visitDate),
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          // Doctor & Room
          if (doctor != null || visit.assignedRoom != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (doctor != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_pin_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        doctor,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                if (visit.assignedRoom != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.door_sliding_rounded,
                          size: 14, color: AppColors.cyanCalm),
                      const SizedBox(width: 4),
                      Text(
                        visit.assignedRoom!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],

          // Chief Complaint
          if (visit.chiefComplaint != null && visit.chiefComplaint!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 14, color: subtitleColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Chief Complaint: ${visit.chiefComplaint}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Diagnosis (if doctor completed consultation)
          if (hasDiagnosis) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 15, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Diagnosis: ${visit.diagnosis}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Pick a new photo and upload it for the given patient
  Future<void> _changePhoto(BuildContext context, Patient patient) async {
    if (_uploadingPhoto) return;

    final isDark = context.read<ThemeProvider>().isDarkMode;
    final source = await showPhotoSourceDialog(context, isDark: isDark);
    if (source == null) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (picked == null) return;
      final Uint8List bytes = await picked.readAsBytes();
      setState(() => _uploadingPhoto = true);
      if (!context.mounted) return;
      await context.read<PatientProvider>().uploadPatientPhoto(
            patient.id,
            bytes,
            picked.name.isNotEmpty ? picked.name : 'photo.jpg',
          );
      setState(() => _uploadingPhoto = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _uploadingPhoto = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update photo: $e')),
        );
      }
    }
  }

  /// Show edit dialog for updating patient information
  Future<void> _showEditPatientDialog(
      BuildContext context, Patient patient) async {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    // Controllers pre-filled with current data
    final firstNameCtrl = TextEditingController(text: patient.firstName);
    final lastNameCtrl = TextEditingController(text: patient.lastName);
    final middleNameCtrl = TextEditingController(text: patient.middleName ?? '');
    final addressCtrl = TextEditingController(text: patient.address);
    final contactCtrl = TextEditingController(text: patient.contactNumber);
    final occupationCtrl = TextEditingController(text: patient.occupation ?? '');
    final referredByCtrl = TextEditingController(text: patient.referredBy ?? '');
    final chiefComplaintCtrl =
        TextEditingController(text: patient.chiefComplaint ?? '');
    final historyCtrl =
        TextEditingController(text: patient.historyOfPresentIllness ?? '');

    // Parse existing pastMedicalHistory into structured conditions and medications
    final parsedConditions =
        PmhCondition.parseFromText(patient.pastMedicalHistory);
    final Map<String, List<String>> editConditionMeds = {};
    for (final c in parsedConditions) {
      editConditionMeds[c.condition] = List.from(c.medications);
    }
    if (editConditionMeds.containsKey('DM') &&
        !editConditionMeds.containsKey('Diabetes Mellitus')) {
      editConditionMeds['Diabetes Mellitus'] = editConditionMeds['DM']!;
    }

    final existingPmh = (patient.pastMedicalHistory ?? '').toLowerCase();
    bool editPmhHypertension = existingPmh.contains('hypertension');
    bool editPmhDM =
        existingPmh.contains('dm') || existingPmh.contains('diabetes');
    bool editPmhAllergies = existingPmh.contains('allergies');
    bool editPmhOperations = existingPmh.contains('operations');
    bool editPmhMedications = existingPmh.contains('medications');
    bool editPmhGlaucoma = existingPmh.contains('glaucoma');

    final knownKeywords = [
      'hypertension',
      'dm',
      'diabetes',
      'allergies',
      'operations',
      'medications',
      'glaucoma'
    ];
    final otherParts = parsedConditions
        .where((c) =>
            !knownKeywords.any((k) => c.condition.toLowerCase().contains(k)))
        .map((c) => c.condition)
        .join(', ');
    final pmhOtherCtrl = TextEditingController(text: otherParts);

    final cardBg =
        isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final titleColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    Widget field(String label, TextEditingController ctrl,
        {int maxLines = 1, TextInputType? keyboard}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboard,
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit Patient: ${patient.displayName}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.of(dialogCtx).pop(false),
                      icon: const Icon(Icons.close_rounded),
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Scrollable fields
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: field('First Name', firstNameCtrl)),
                            const SizedBox(width: 12),
                            Expanded(child: field('Last Name', lastNameCtrl)),
                          ],
                        ),
                        field('Middle Name (optional)', middleNameCtrl),
                        field('Address', addressCtrl),
                        Row(
                          children: [
                            Expanded(
                                child: field('Contact Number', contactCtrl,
                                    keyboard: TextInputType.phone)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: field('Occupation', occupationCtrl)),
                          ],
                        ),
                        field('Referred By', referredByCtrl),
                        field('Chief Complaint', chiefComplaintCtrl,
                            maxLines: 2),
                        field('History of Present Illness', historyCtrl,
                            maxLines: 2),
                        const SizedBox(height: 2),

                        // ── Past Medical History — checkbox section ──────────
                        StatefulBuilder(
                          builder: (_, setLocal) {
                            final pmhCardBg = isDark
                                ? AppColors.surfaceLight.withValues(alpha: 0.25)
                                : AppColors.lightBg;
                            final pmhBorder = isDark
                                ? AppColors.surfaceHover
                                : AppColors.lightBorder;

                            Widget checkItem(
                              String label,
                              String conditionKey,
                              bool value,
                              ValueChanged<bool> onChanged, {
                              Color? accent,
                            }) {
                              final condAccent = accent ?? AppColors.primary;
                              final meds = editConditionMeds[conditionKey] ?? [];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () async {
                                        final newVal = !value;
                                        onChanged(newVal);
                                        if (newVal) {
                                          final result =
                                              await showPmhMedicationDialog(
                                            context,
                                            conditionName: conditionKey,
                                            existingMeds: meds,
                                            isDark: isDark,
                                          );
                                          if (result != null) {
                                            setLocal(() =>
                                                editConditionMeds[conditionKey] =
                                                    result);
                                          }
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: Checkbox(
                                                value: value,
                                                onChanged: (v) async {
                                                  final newVal = v ?? false;
                                                  onChanged(newVal);
                                                  if (newVal) {
                                                    final result =
                                                        await showPmhMedicationDialog(
                                                      context,
                                                      conditionName:
                                                          conditionKey,
                                                      existingMeds: meds,
                                                      isDark: isDark,
                                                    );
                                                    if (result != null) {
                                                      setLocal(() =>
                                                          editConditionMeds[
                                                                  conditionKey] =
                                                              result);
                                                    }
                                                  }
                                                },
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                activeColor: condAccent,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: value
                                                    ? condAccent
                                                    : titleColor,
                                              ),
                                            ),
                                            if (value) ...[
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () async {
                                                  final result =
                                                      await showPmhMedicationDialog(
                                                    context,
                                                    conditionName: conditionKey,
                                                    existingMeds: meds,
                                                    isDark: isDark,
                                                  );
                                                  if (result != null) {
                                                    setLocal(() =>
                                                        editConditionMeds[
                                                                conditionKey] =
                                                            result);
                                                  }
                                                },
                                                child: Icon(Icons.edit_rounded,
                                                    size: 13,
                                                    color: condAccent
                                                        .withValues(alpha: 0.8)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (value && meds.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 28, top: 2),
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 2,
                                          children: meds
                                              .map((m) => Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 5,
                                                        vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: condAccent
                                                          .withValues(
                                                              alpha: isDark
                                                                  ? 0.18
                                                                  : 0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      border: Border.all(
                                                          color: condAccent
                                                              .withValues(
                                                                  alpha: 0.25)),
                                                    ),
                                                    child: Text(
                                                      m,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isDark
                                                            ? Colors.white
                                                            : Colors.black87,
                                                      ),
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: pmhCardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: pmhBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.medical_services_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Past Medical History & Medications',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: titleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            checkItem(
                                              'Hypertension',
                                              'Hypertension',
                                              editPmhHypertension,
                                              (v) => setLocal(() =>
                                                  editPmhHypertension = v),
                                              accent: AppColors.urgent,
                                            ),
                                            checkItem(
                                              'DM (Diabetes)',
                                              'Diabetes Mellitus',
                                              editPmhDM,
                                              (v) => setLocal(
                                                  () => editPmhDM = v),
                                              accent: AppColors.warning,
                                            ),
                                            checkItem(
                                              'Allergies',
                                              'Allergies',
                                              editPmhAllergies,
                                              (v) => setLocal(() =>
                                                  editPmhAllergies = v),
                                              accent: AppColors.onHold,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            checkItem(
                                              'Operations',
                                              'Operations',
                                              editPmhOperations,
                                              (v) => setLocal(() =>
                                                  editPmhOperations = v),
                                            ),
                                            checkItem(
                                              'Medications',
                                              'Medications',
                                              editPmhMedications,
                                              (v) => setLocal(() =>
                                                  editPmhMedications = v),
                                            ),
                                            checkItem(
                                              'Glaucoma',
                                              'Glaucoma',
                                              editPmhGlaucoma,
                                              (v) => setLocal(() =>
                                                  editPmhGlaucoma = v),
                                              accent: AppColors.cyanCalm,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: pmhOtherCtrl,
                                    style: TextStyle(
                                        color: titleColor,
                                        fontWeight: FontWeight.w700),
                                    decoration: const InputDecoration(
                                      labelText: 'Other relevant history',
                                      hintText:
                                          'Additional notes, surgeries, conditions...',
                                      prefixIcon:
                                          Icon(Icons.notes_rounded, size: 18),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(dialogCtx).pop(false),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46)),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.of(dialogCtx).pop(true),
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 46)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wait one frame so the dialog fully disposes before triggering provider
    // notifications — prevents the '_dependents.isEmpty' assertion error.
    await Future.delayed(Duration.zero);

    if (confirmed == true && context.mounted) {
      final updated = patient.copyWith(
        firstName: firstNameCtrl.text.trim().isNotEmpty
            ? firstNameCtrl.text.trim()
            : patient.firstName,
        lastName: lastNameCtrl.text.trim().isNotEmpty
            ? lastNameCtrl.text.trim()
            : patient.lastName,
        middleName: middleNameCtrl.text.trim().isNotEmpty
            ? middleNameCtrl.text.trim()
            : null,
        address: addressCtrl.text.trim().isNotEmpty
            ? addressCtrl.text.trim()
            : patient.address,
        contactNumber: contactCtrl.text.trim().isNotEmpty
            ? contactCtrl.text.trim()
            : patient.contactNumber,
        occupation: occupationCtrl.text.trim().isNotEmpty
            ? occupationCtrl.text.trim()
            : null,
        referredBy: referredByCtrl.text.trim().isNotEmpty
            ? referredByCtrl.text.trim()
            : null,
        chiefComplaint: chiefComplaintCtrl.text.trim().isNotEmpty
            ? chiefComplaintCtrl.text.trim()
            : null,
        historyOfPresentIllness: historyCtrl.text.trim().isNotEmpty
            ? historyCtrl.text.trim()
            : null,
        pastMedicalHistory: () {
          final conditions = <PmhCondition>[];
          if (editPmhHypertension) {
            conditions.add(PmhCondition(
                condition: 'Hypertension',
                medications: editConditionMeds['Hypertension'] ?? []));
          }
          if (editPmhDM) {
            conditions.add(PmhCondition(
                condition: 'Diabetes Mellitus',
                medications: editConditionMeds['Diabetes Mellitus'] ?? []));
          }
          if (editPmhAllergies) {
            conditions.add(PmhCondition(
                condition: 'Allergies',
                medications: editConditionMeds['Allergies'] ?? []));
          }
          if (editPmhOperations) {
            conditions.add(PmhCondition(
                condition: 'Operations',
                medications: editConditionMeds['Operations'] ?? []));
          }
          if (editPmhMedications) {
            conditions.add(PmhCondition(
                condition: 'Medications',
                medications: editConditionMeds['Medications'] ?? []));
          }
          if (editPmhGlaucoma) {
            conditions.add(PmhCondition(
                condition: 'Glaucoma',
                medications: editConditionMeds['Glaucoma'] ?? []));
          }
          final otherText = pmhOtherCtrl.text.trim().isNotEmpty
              ? pmhOtherCtrl.text.trim()
              : null;
          final formatted = PmhCondition.formatList(conditions, otherText);
          return formatted.isEmpty ? null : formatted;
        }(),
      );

      await context.read<PatientProvider>().updatePatient(updated);

      // Also update department clinical records in memory/storage
      if (_deptRecords.isNotEmpty) {
        for (final dr in _deptRecords) {
          final updatedDeptRec = dr.copyWith(
            chiefComplaint: updated.chiefComplaint,
            historyOfPresentIllness: updated.historyOfPresentIllness,
            pastMedicalHistory: updated.pastMedicalHistory,
            pmhConditions: updated.pmhConditionsList,
          );
          await _deptRepo.upsert(updatedDeptRec);
        }
      }
      _loadDeptRecords();

      // Dispose controllers
      firstNameCtrl.dispose();
      lastNameCtrl.dispose();
      middleNameCtrl.dispose();
      addressCtrl.dispose();
      contactCtrl.dispose();
      occupationCtrl.dispose();
      referredByCtrl.dispose();
      chiefComplaintCtrl.dispose();
      historyCtrl.dispose();
      pmhOtherCtrl.dispose();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient record updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      // Always dispose if cancelled
      firstNameCtrl.dispose();
      lastNameCtrl.dispose();
      middleNameCtrl.dispose();
      addressCtrl.dispose();
      contactCtrl.dispose();
      occupationCtrl.dispose();
      referredByCtrl.dispose();
      chiefComplaintCtrl.dispose();
      historyCtrl.dispose();
      pmhOtherCtrl.dispose();
    }
  }

  Future<void> _confirmDeletePatient(
      BuildContext context, Patient patient) async {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.urgent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.urgent, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Delete Patient Record',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the patient record for ${patient.displayName} (ID: ${patient.patientNo})?\n\nThis will also remove their clinic visit history.',
          style: TextStyle(
            color:
                isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.urgent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Wait one frame so the dialog fully disposes before triggering provider
    // notifications — prevents the '_dependents.isEmpty' assertion error.
    await Future.delayed(Duration.zero);

    if (confirmed == true && context.mounted) {
      await context.read<PatientProvider>().deletePatient(patient.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient record for ${patient.displayName} deleted'),
            backgroundColor: AppColors.urgent,
          ),
        );
        context.go('/receptionist');
      }
    }
  }
}
