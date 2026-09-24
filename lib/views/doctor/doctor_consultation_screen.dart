import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/models/clinical_examination.dart';
import '../../data/models/patient.dart';
import '../../data/models/queue_entry.dart';
import '../../data/models/vital_signs.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/queue_provider.dart';

class DoctorConsultationScreen extends StatefulWidget {
  final String patientId;
  final QueueEntry? queueEntry;

  const DoctorConsultationScreen({
    super.key,
    required this.patientId,
    this.queueEntry,
  });

  @override
  State<DoctorConsultationScreen> createState() => _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  final TextEditingController _diagnosisCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _prescriptionCtrl = TextEditingController();

  // Specialty Exam Findings state (inspired by Findings.jsx & EyeExam.jsx)
  final Map<String, String> _findingsValues = {};
  final Map<String, String> _findingsStatus = {}; // 'normal', 'mild', 'severe'

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().loadConsultation(
            patientId: widget.patientId,
            queueEntry: widget.queueEntry,
          );
    });
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    _prescriptionCtrl.dispose();
    super.dispose();
  }

  void _setDefaultFindings(bool isEnt) {
    if (_findingsValues.isNotEmpty) return;
    if (isEnt) {
      _findingsValues['Ear Exam'] = 'Normal';
      _findingsStatus['Ear Exam'] = 'normal';
      _findingsValues['Nose Exam'] = 'Clear';
      _findingsStatus['Nose Exam'] = 'normal';
      _findingsValues['Throat / Pharynx'] = 'Normal';
      _findingsStatus['Throat / Pharynx'] = 'normal';
      _findingsValues['Neck & Nodes'] = 'Supple, no lymphadenopathy';
      _findingsStatus['Neck & Nodes'] = 'normal';
    } else {
      _findingsValues['Visual Acuity OD'] = '20/20';
      _findingsStatus['Visual Acuity OD'] = 'normal';
      _findingsValues['Visual Acuity OS'] = '20/20';
      _findingsStatus['Visual Acuity OS'] = 'normal';
      _findingsValues['Eye Pressure (IOP)'] = '15 mmHg (Normal)';
      _findingsStatus['Eye Pressure (IOP)'] = 'normal';
      _findingsValues['Anterior Chamber & Cornea'] = 'Clear, deep and quiet';
      _findingsStatus['Anterior Chamber & Cornea'] = 'normal';
      _findingsValues['Fundoscopy / Retina'] = 'Normal disc, cup-to-disc 0.3';
      _findingsStatus['Fundoscopy / Retina'] = 'normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorProv = context.watch<DoctorProvider>();
    final patient = doctorProv.currentPatient;
    final exams = doctorProv.currentExaminations;
    final isLoading = doctorProv.isLoadingConsultation;

    final isEnt = doctorProv.activeDepartment == AppConstants.deptEnt;
    const themeColor = AppColors.doctorPrimary;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Consultation...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consultation Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Patient profile could not be loaded.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Return to Queue'),
              ),
            ],
          ),
        ),
      );
    }

    _setDefaultFindings(isEnt);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patient.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Ticket: ${widget.queueEntry?.queueNumber ?? "CLINICAL"} • ${patient.patientNo}',
              style: TextStyle(fontSize: 12, color: themeColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Patient Exams',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              doctorProv.loadConsultation(
                patientId: widget.patientId,
                queueEntry: widget.queueEntry,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 1. PATIENT DEMOGRAPHICS & VITAL SIGNS ───────────────────
          _buildPatientDemographicsCard(patient, themeColor),

          const SizedBox(height: 16),

          // ── 2. VITAL SIGNS SUMMARY ROW ──────────────────────────────
          _buildVitalSignsCard(patient.vitalSigns ?? widget.queueEntry?.vitalSigns, themeColor),

          const SizedBox(height: 16),

          // ── 3. CHIEF COMPLAINT / SYMPTOMS / CAUSE OF CONSULTATION ────
          _buildSymptomsAndComplaintCard(patient, themeColor),

          const SizedBox(height: 20),

          // ── 4. NURSE STATION EXAMINATIONS & DIAGRAMS WITH DESCRIPTION ─
          _buildNurseExaminationsSection(context, exams, themeColor),

          const SizedBox(height: 24),

          // ── 5. STRUCTURED SPECIALTY CLINICAL EXAM MATRIX ─────────────
          _buildSpecialtyExamMatrix(isEnt, themeColor),

          const SizedBox(height: 24),

          // ── 6. DOCTOR'S FINDINGS, DIAGNOSIS & PRESCRIPTION ─────────
          _buildDoctorAssessmentCard(themeColor),

          const SizedBox(height: 32),

          // ── 7. COMPLETION ACTION BUTTONS ────────────────────────────
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleCompleteConsultation,
              icon: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isSubmitting ? 'Concluding Visit...' : 'Complete Consultation & Conclude Visit',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPatientDemographicsCard(Patient patient, Color themeColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppImageHelper.buildAvatar(
                  photoUrl: patient.photoUrl,
                  name: patient.fullName,
                  radius: 22,
                  backgroundColor: themeColor.withValues(alpha: 0.15),
                  foregroundColor: themeColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${patient.age} yrs • ${patient.sex} • ${patient.civilStatus}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (patient.isFirstTime)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'FIRST TIME',
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(patient.contactNumber, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    patient.address,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignsCard(VitalSigns? vitals, Color themeColor) {
    final bp = vitals?.bloodPressure ?? '120/80';
    final temp = vitals?.temperature != null ? '${vitals!.temperature}°C' : '36.5°C';
    final hr = vitals?.heartRate != null ? '${vitals!.heartRate} bpm' : '75 bpm';
    final rr = vitals?.respiratoryRate != null ? '${vitals!.respiratoryRate}/min' : '18/min';
    final spo2 = vitals?.oxygenSaturation != null ? '${vitals!.oxygenSaturation}%' : '98%';
    final wt = vitals?.weight != null ? '${vitals!.weight} kg' : '62.0 kg';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart_rounded, size: 18, color: themeColor),
                const SizedBox(width: 6),
                const Text(
                  'Triage Vital Signs (Nurse Intake)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildVitalMetric('Temp', temp, Icons.thermostat_rounded, Colors.orange),
                _buildVitalMetric('BP', bp, Icons.favorite_border_rounded, Colors.red),
                _buildVitalMetric('HR', hr, Icons.favorite_rounded, Colors.pink),
                _buildVitalMetric('RR', rr, Icons.air_rounded, AppColors.cyanCalm),
                _buildVitalMetric('SpO2', spo2, Icons.water_drop_rounded, const Color(0xFF0D9488)),
                _buildVitalMetric('Weight', wt, Icons.scale_rounded, Colors.indigo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSymptomsAndComplaintCard(Patient patient, Color themeColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: themeColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.report_problem_rounded, color: themeColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'CAUSE OF CONSULTATION & SYMPTOMS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: themeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: themeColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                patient.chiefComplaint?.isNotEmpty == true
                    ? patient.chiefComplaint!
                    : 'No specific chief complaint recorded at reception.',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
              ),
            ),
            if (patient.historyOfPresentIllness?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              const Text(
                'History of Present Illness:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                patient.historyOfPresentIllness!,
                style: const TextStyle(fontSize: 13),
              ),
            ],
            if (patient.pastMedicalHistory?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              const Text(
                'Past Medical History:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                patient.pastMedicalHistory!,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNurseExaminationsSection(
    BuildContext context,
    List<Map<String, dynamic>> exams,
    Color themeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.brush_rounded, color: Color(0xFF0D9488), size: 20),
                SizedBox(width: 8),
                Text(
                  'Nurse Station Diagrams & Findings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${exams.length} Exams Recorded',
                style: const TextStyle(
                  color: Color(0xFF0D9488),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (exams.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: const Center(
              child: Text(
                'No clinical diagrams or exams recorded by the nurse for this patient.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...exams.map((group) => _buildExamGroupCard(context, group, themeColor)),
      ],
    );
  }

  Widget _buildExamGroupCard(
    BuildContext context,
    Map<String, dynamic> group,
    Color themeColor,
  ) {
    final examType = group['exam_type']?.toString() ?? 'EXAM';
    final findings = group['clinical_findings']?.toString();
    final items = group['items'] as List<ClinicalExamination>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    examType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '${items.length} Views Captured',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notes_rounded, size: 14, color: Color(0xFF0D9488)),
                      SizedBox(width: 6),
                      Text(
                        'NURSE DESCRIPTION & FINDINGS:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    findings?.isNotEmpty == true
                        ? findings!
                        : 'No detailed clinical descriptions provided by triage nurse.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Clinical Markups & Drawings (Tap image to zoom):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final exam = items[i];
                    return _buildDiagramThumbnail(context, exam);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiagramThumbnail(BuildContext context, ClinicalExamination exam) {
    return GestureDetector(
      onTap: () => _showDiagramLightbox(context, exam),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          color: Colors.black.withValues(alpha: 0.04),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildDiagramImage(exam.imageUrl),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'View: ${exam.viewName}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Positioned(
              top: 4,
              right: 4,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.zoom_in, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagramImage(String? imageUrl) {
    return AppImageHelper.buildDiagramImage(
      imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
    );
  }

  void _showDiagramLightbox(BuildContext context, ClinicalExamination exam) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Diagram: ${exam.displayExamType} (View ${exam.viewName})'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 450, maxWidth: 600),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildDiagramImage(exam.imageUrl),
                ),
              ),
            ),
            if (exam.clinicalFindings?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Notes: ${exam.clinicalFindings!}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Structured Specialty Findings Matrix (Findings.jsx & EyeExam.jsx) ──
  Widget _buildSpecialtyExamMatrix(bool isEnt, Color themeColor) {
    final title = isEnt ? 'ENT Physical Examination Findings' : 'Ophthalmology (Eye) Exam Findings';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: themeColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isEnt ? Icons.hearing_rounded : Icons.visibility_rounded, color: themeColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ..._findingsValues.keys.map((key) {
              final val = _findingsValues[key] ?? 'Normal';
              final status = _findingsStatus[key] ?? 'normal';

              Color badgeBg = Colors.green.shade100;
              Color badgeFg = Colors.green.shade800;
              if (status == 'mild') {
                badgeBg = Colors.amber.shade100;
                badgeFg = Colors.amber.shade800;
              } else if (status == 'severe') {
                badgeBg = Colors.red.shade100;
                badgeFg = Colors.red.shade800;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeFg),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(val, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),
                      // Quick action toggles
                      Wrap(
                        spacing: 6,
                        children: [
                          ChoiceChip(
                            label: const Text('Normal', style: TextStyle(fontSize: 11)),
                            selected: status == 'normal',
                            selectedColor: Colors.green.withValues(alpha: 0.2),
                            onSelected: (_) {
                              setState(() {
                                _findingsStatus[key] = 'normal';
                                _findingsValues[key] = isEnt ? 'Normal / Clear' : 'Normal / Clear';
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Mild', style: TextStyle(fontSize: 11)),
                            selected: status == 'mild',
                            selectedColor: Colors.amber.withValues(alpha: 0.2),
                            onSelected: (_) {
                              setState(() {
                                _findingsStatus[key] = 'mild';
                                _findingsValues[key] = isEnt
                                    ? (key.contains('Ear') ? 'Mild infection / erythema' : 'Mild inflammation')
                                    : 'Mild blurriness / conjunctival injection';
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Severe', style: TextStyle(fontSize: 11)),
                            selected: status == 'severe',
                            selectedColor: Colors.red.withValues(alpha: 0.2),
                            onSelected: (_) {
                              setState(() {
                                _findingsStatus[key] = 'severe';
                                _findingsValues[key] = isEnt
                                    ? (key.contains('Ear') ? 'Severe purulent discharge / perforation' : 'Severe obstruction / hypertrophy')
                                    : 'High IOP / dense cataract / retinal lesion';
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorAssessmentCard(Color themeColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: themeColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_rounded, color: themeColor, size: 22),
                const SizedBox(width: 8),
                const Text(
                  "Doctor's Assessment & Diagnosis",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _diagnosisCtrl,
              decoration: const InputDecoration(
                labelText: 'Primary Diagnosis / Clinical Impression',
                hintText: 'e.g. Chronic Suppurative Otitis Media (CSOM) / Cataract Senile',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Doctor Clinical Findings & Orders',
                hintText: 'Enter clinical observations, examination notes, advice...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _prescriptionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Prescription & Medication (Rx)',
                hintText: 'e.g. Ciprofloxacin Otic Drops 3 gtts TID x 7 days...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCompleteConsultation() async {
    final diagnosis = _diagnosisCtrl.text.trim();
    if (diagnosis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a clinical diagnosis or impression before completing.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final doctorProv = context.read<DoctorProvider>();
    final queueProv = context.read<QueueProvider>();

    // Append structured exam findings to notes
    final StringBuffer fullNotes = StringBuffer();
    if (_findingsValues.isNotEmpty) {
      fullNotes.writeln('[SPECIALTY FINDINGS]');
      _findingsValues.forEach((k, v) {
        final st = _findingsStatus[k] ?? 'normal';
        fullNotes.writeln('• $k: $v ($st)');
      });
      fullNotes.writeln();
    }
    if (_notesCtrl.text.trim().isNotEmpty) {
      fullNotes.writeln('[DOCTOR NOTES]');
      fullNotes.writeln(_notesCtrl.text.trim());
    }

    final success = await doctorProv.completeConsultation(
      diagnosis: diagnosis,
      notes: fullNotes.toString().trim(),
      prescription: _prescriptionCtrl.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      await queueProv.initialize(forceRefresh: true);
      if (!mounted) return;

      // Offer to call next patient
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success),
              SizedBox(width: 8),
              Text('Consultation Complete'),
            ],
          ),
          content: const Text(
            'Visit record has been saved to patient history and the queue ticket marked completed.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop(); // return to dashboard/queue
              },
              child: const Text('Back to Dashboard'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final allQueue = queueProv.todayQueue;
                final nextPatient = doctorProv.getNextPatient(allQueue);
                if (nextPatient != null) {
                  await doctorProv.callPatient(nextPatient);
                  if (!mounted) return;
                  context.pushReplacement(
                    '/doctor/consultation/${nextPatient.patientId}',
                    extra: nextPatient,
                  );
                } else {
                  if (!mounted) return;
                  context.pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text('Call Next Patient Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(doctorProv.consultationError ?? 'Failed to complete consultation'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
