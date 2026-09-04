import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../providers/patient_provider.dart';
import '../../data/models/patient.dart';
import '../../data/models/visit_record.dart';
import '../../shared/widgets/olof_logo.dart';
import '../../providers/theme_provider.dart';
import '../../shared/widgets/photo_source_dialog.dart';

/// Patient profile screen with details and visit history
class PatientProfileScreen extends StatefulWidget {
  final String patientId;

  const PatientProfileScreen({super.key, required this.patientId});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool _uploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().selectPatient(widget.patientId);
    });
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
                  backgroundImage: patient.photoUrl != null && patient.photoUrl!.isNotEmpty
                      ? NetworkImage(patient.photoUrl!)
                      : null,
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
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.warning : AppColors.brandBlue,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: () => context
                .go('/receptionist/checkin?patientId=${patient.id}'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: 10,
              ),
            ),
            child: const Text('Check In'),
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
                      image: patient.photoUrl != null && patient.photoUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(patient.photoUrl!),
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
          if (patient.chiefComplaint != null && patient.chiefComplaint!.isNotEmpty) ...[
            Divider(
              height: 22,
              color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
            ),
            Text(
              'Clinical History & Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoRow('Chief Complaint', patient.chiefComplaint!, isDark, isCompact),
          ],
          if (patient.historyOfPresentIllness != null && patient.historyOfPresentIllness!.isNotEmpty)
            _buildInfoRow('History of Illness', patient.historyOfPresentIllness!, isDark, isCompact),
          if (patient.pastMedicalHistory != null && patient.pastMedicalHistory!.isNotEmpty)
            _buildInfoRow('Past Medical History', patient.pastMedicalHistory!, isDark, isCompact),
        ],
      ),
    );
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
              Text(
                'Visit History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),
              if (provider.selectedPatientVisits.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded,
                            size: 34, color: subtitleColor),
                        const SizedBox(height: 8),
                        Text(
                          'No visits recorded yet',
                          style: TextStyle(
                            color: subtitleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...provider.selectedPatientVisits.map(
                  (visit) => _buildVisitCard(context, visit, isDark),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisitCard(BuildContext context, VisitRecord visit, bool isDark) {
    final color = visit.department == 'ENT'
        ? AppColors.entColor
        : AppColors.eyesColor;
    final itemBg = isDark ? AppColors.surfaceLight : AppColors.lightSurfaceMid;
    final borderColor = isDark ? AppColors.surfaceHover : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              visit.department,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.purpose,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  DateHelper.formatDate(visit.visitDate),
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            visit.queueNumber,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
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
}
