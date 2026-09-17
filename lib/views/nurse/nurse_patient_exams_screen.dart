import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/nurse_provider.dart';
import '../../providers/theme_provider.dart';

import '../../data/models/patient.dart';
import '../../providers/patient_provider.dart';

/// Patient Exams & Clinical Diagram History Screen
class NursePatientExamsScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String? queueNumber;
  final String? department;
  final String? queueEntryId;
  final String? chiefComplaint;
  final String? historyOfPresentIllness;
  final String? pastMedicalHistory;
  final String? assignedDoctor;
  final String? assignedRoom;

  const NursePatientExamsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.queueNumber,
    this.department,
    this.queueEntryId,
    this.chiefComplaint,
    this.historyOfPresentIllness,
    this.pastMedicalHistory,
    this.assignedDoctor,
    this.assignedRoom,
  });

  @override
  State<NursePatientExamsScreen> createState() => _NursePatientExamsScreenState();
}

class _NursePatientExamsScreenState extends State<NursePatientExamsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NurseProvider>().loadExaminationsForPatient(widget.patientId);
    });
  }

  void _createNewExam(
    String examType, {
    String? chiefComplaint,
    String? hpi,
    String? pmh,
  }) async {
    await context.push(
      '/nurse/drawing',
      extra: {
        'patientId': widget.patientId,
        'patientName': widget.patientName,
        'examType': examType,
        'department': widget.department ?? 'ENT',
        'queueNumber': widget.queueNumber,
        'queueEntryId': widget.queueEntryId,
        'chiefComplaint': chiefComplaint ?? widget.chiefComplaint,
        'historyOfPresentIllness': hpi ?? widget.historyOfPresentIllness,
        'pastMedicalHistory': pmh ?? widget.pastMedicalHistory,
      },
    );
    if (mounted) {
      context.read<NurseProvider>().loadExaminationsForPatient(widget.patientId);
    }
  }

  void _viewOrEditExam(Map<String, dynamic> group, bool viewMode) async {
    await context.push(
      '/nurse/drawing',
      extra: {
        'patientId': widget.patientId,
        'patientName': widget.patientName,
        'examType': group['exam_type'] ?? 'EYES',
        'department': group['department'] ?? widget.department ?? 'ENT',
        'examinationUuid': group['examination_uuid'],
        'savedDiagram': group['items'],
        'viewMode': viewMode,
        'queueNumber': widget.queueNumber,
        'queueEntryId': widget.queueEntryId,
        'chiefComplaint': widget.chiefComplaint,
        'historyOfPresentIllness': widget.historyOfPresentIllness,
        'pastMedicalHistory': widget.pastMedicalHistory,
      },
    );
    if (mounted) {
      context.read<NurseProvider>().loadExaminationsForPatient(widget.patientId);
    }
  }

  void _deleteExam(String examinationUuid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Examination'),
        content: const Text(
          'Are you sure you want to delete this clinical diagram examination? All associated views and annotations will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final nurseProv = context.read<NurseProvider>();
      final success = await nurseProv.deleteExamination(examinationUuid, widget.patientId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Examination deleted' : 'Failed to delete examination',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  IconData _getExamIcon(String examType) {
    switch (examType.toLowerCase()) {
      case 'eyes':
      case 'eye':
        return Icons.visibility_rounded;
      case 'ears':
      case 'ear':
        return Icons.hearing_rounded;
      case 'nose':
        return Icons.air_rounded;
      case 'throat':
        return Icons.coronavirus_rounded;
      case 'neck':
        return Icons.accessibility_new_rounded;
      case 'head':
        return Icons.face_rounded;
      default:
        return Icons.draw_rounded;
    }
  }

  Color _getExamColor(String examType) {
    switch (examType.toLowerCase()) {
      case 'eyes':
      case 'eye':
        return AppColors.cyanCalm;
      case 'ears':
      case 'ear':
        return const Color(0xFFF59E0B); // Amber
      case 'nose':
        return const Color(0xFF10B981); // Emerald
      case 'throat':
        return const Color(0xFFEC4899); // Rose/Pink
      case 'neck':
        return const Color(0xFF8B5CF6); // Purple
      case 'head':
        return const Color(0xFF3B82F6); // Blue
      default:
        return const Color(0xFF06B6D4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final nurseProv = context.watch<NurseProvider>();
    final savedExams = nurseProv.groupedExams;

    final headerBg = isDark ? AppColors.surfaceDark : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

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
              // Top Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      ),
                      tooltip: 'Back to Nurse Station',
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.patientName,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                              if (widget.queueNumber != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.queueNumber!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFEC4899),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            'Patient ID: ${widget.patientId.length > 12 ? widget.patientId.substring(0, 12) : widget.patientId} • Clinical Examinations',
                            style: TextStyle(fontSize: 12, color: subtitleColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh History',
                      onPressed: () {
                        context.read<NurseProvider>().loadExaminationsForPatient(widget.patientId);
                      },
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Receptionist Intake & Clinical Context Banner
                    _buildReceptionistIntakeCard(context, isDark),
                    const SizedBox(height: 20),

                    // Section 1: Create New Examination
                    _buildSectionHeader('Create Clinical Examination Diagram', Icons.add_circle_outline_rounded, isDark),
                    const SizedBox(height: 12),
                    _buildExamCategoriesGrid(context, isDark),

                    const SizedBox(height: 24),

                    // Section 2: Saved Examinations History
                    _buildSectionHeader(
                      'Saved Examinations & Diagrams (${savedExams.length})',
                      Icons.history_rounded,
                      isDark,
                    ),
                    const SizedBox(height: 12),
                    if (nurseProv.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (savedExams.isEmpty)
                      _buildNoExamsCard(isDark)
                    else
                      ...savedExams.map((group) => _buildSavedExamCard(group, isDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceptionistIntakeCard(BuildContext context, bool isDark) {
    Patient? patient;
    try {
      patient = context.watch<PatientProvider>().patients.firstWhere(
            (p) => p.id == widget.patientId,
          );
    } catch (_) {}

    final complaint = widget.chiefComplaint ?? patient?.chiefComplaint ?? '';
    final hpi = widget.historyOfPresentIllness ?? patient?.historyOfPresentIllness ?? '';
    final pmh = widget.pastMedicalHistory ?? patient?.pastMedicalHistory ?? '';
    final doctor = widget.assignedDoctor ?? patient?.assignedDoctor ?? '';
    final room = widget.assignedRoom ?? patient?.assignedRoom ?? '';
    final sex = patient?.sex ?? '';
    final age = patient?.age != null ? '${patient!.age} yrs' : '';
    final patientNo = patient?.patientNo ?? '';

    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_ind_rounded, size: 18, color: Color(0xFFEC4899)),
                const SizedBox(width: 8),
                const Text(
                  'RECEPTIONIST CLINICAL INTAKE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Color(0xFFEC4899),
                  ),
                ),
                const Spacer(),
                if (doctor.isNotEmpty || room.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.meeting_room_outlined, size: 12, color: AppColors.cyanCalm),
                        const SizedBox(width: 4),
                        Text(
                          room.isNotEmpty ? room : doctor,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Demographics row
                if (sex.isNotEmpty || age.isNotEmpty || patientNo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        if (patientNo.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.lightBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Patient No: $patientNo',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subtitleColor),
                            ),
                          ),
                        Text(
                          '$sex ${age.isNotEmpty ? '• $age' : ''}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subtitleColor),
                        ),
                      ],
                    ),
                  ),

                // Chief Complaint
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.record_voice_over_rounded, size: 16, color: Color(0xFFEC4899)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Chief Complaint: ',
                                style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEC4899)),
                              ),
                              TextSpan(
                                text: complaint.isNotEmpty ? complaint : 'None specified during check-in',
                                style: TextStyle(
                                  fontStyle: complaint.isEmpty ? FontStyle.italic : FontStyle.normal,
                                  color: complaint.isEmpty ? subtitleColor : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // History of Present Illness (HPI)
                if (hpi.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_rounded, size: 14, color: subtitleColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: titleColor),
                            children: [
                              TextSpan(
                                text: 'HPI: ',
                                style: TextStyle(fontWeight: FontWeight.w800, color: subtitleColor),
                              ),
                              TextSpan(text: hpi),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Past Medical History (PMH)
                if (pmh.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.medical_services_outlined, size: 14, color: AppColors.cyanCalm),
                      const SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: titleColor),
                            children: [
                              const TextSpan(
                                text: 'Past Medical History: ',
                                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.cyanCalm),
                              ),
                              TextSpan(text: pmh),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFFEC4899)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildExamCategoriesGrid(BuildContext context, bool isDark) {
    Patient? patient;
    try {
      patient = context.watch<PatientProvider>().patients.firstWhere(
            (p) => p.id == widget.patientId,
          );
    } catch (_) {}
    final complaint = widget.chiefComplaint ?? patient?.chiefComplaint;
    final hpi = widget.historyOfPresentIllness ?? patient?.historyOfPresentIllness;
    final pmh = widget.pastMedicalHistory ?? patient?.pastMedicalHistory;

    final categories = [
      {'name': 'Eyes', 'type': 'eyes', 'desc': 'Biomicroscopy, Fundoscopy, Gross Exam'},
      {'name': 'Ears', 'type': 'ears', 'desc': 'Pinna, Canal, Tympanic views 1-3'},
      {'name': 'Nose', 'type': 'nose', 'desc': 'Nasal septum & cavity anatomy'},
      {'name': 'Throat', 'type': 'throat', 'desc': 'Pharynx, tonsils & larynx views 1-3'},
      {'name': 'Neck', 'type': 'neck', 'desc': 'Cervical lymph nodes & thyroid'},
      {'name': 'Head', 'type': 'head', 'desc': 'Cranial & facial clinical views'},
      {'name': 'Blank Canvas', 'type': 'drawing', 'desc': 'Freehand medical drawing'},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final color = _getExamColor(cat['type']!);
        final icon = _getExamIcon(cat['type']!);

        return InkWell(
          onTap: () => _createNewExam(cat['type']!, chiefComplaint: complaint, hpi: hpi, pmh: pmh),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 155,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  cat['name']!,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cat['desc']!,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSavedExamCard(Map<String, dynamic> group, bool isDark) {
    final examType = group['exam_type']?.toString() ?? 'EYES';
    final viewsCount = group['views_count'] ?? 1;
    final createdAt = group['created_at'] as DateTime?;
    final findings = group['clinical_findings']?.toString() ?? '';
    final examUuid = group['examination_uuid']?.toString() ?? '';
    final color = _getExamColor(examType);
    final icon = _getExamIcon(examType);

    final cardBg = isDark ? AppColors.surfaceMid : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            examType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SAVED',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Views Captured: $viewsCount • ${createdAt != null ? DateFormat('MMM d, yyyy h:mm a').format(createdAt) : ''}',
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                      ),
                    ],
                  ),
                ),
                // Overflow options: Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  tooltip: 'Delete Examination',
                  onPressed: () => _deleteExam(examUuid),
                ),
              ],
            ),

            if (findings.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes_rounded, size: 14, color: subtitleColor),
                        const SizedBox(width: 6),
                        Text(
                          'Clinical Findings / Nurse Notes',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      findings,
                      style: TextStyle(fontSize: 12.5, color: titleColor),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewOrEditExam(group, true),
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: const Text('View Diagrams'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewOrEditExam(group, false),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit / Annotate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoExamsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceMid : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.draw_outlined,
              size: 48,
              color: isDark ? AppColors.textDisabled : AppColors.lightTextDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              'No Saved Examinations Yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose an anatomical exam category above to begin annotating diagrams for this patient.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
