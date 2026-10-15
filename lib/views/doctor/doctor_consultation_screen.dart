import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/models/clinical_examination.dart';
import '../../data/models/patient.dart';
import '../../data/models/patient_dept_record.dart';
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

  void _setDefaultFindings(bool isEnt, VitalSigns? vitals) {
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
      final vaOD = vitals?.visualAcuityOD;
      final vaOS = vitals?.visualAcuityOS;
      final iopOD = vitals?.intraocularPressureOD;
      final iopOS = vitals?.intraocularPressureOS;
      final fundusOD = vitals?.funduscopyOD;
      final fundusOS = vitals?.funduscopyOS;

      _findingsValues['Visual Acuity OD'] = (vaOD != null && vaOD.isNotEmpty) ? vaOD : '20/20';
      _findingsStatus['Visual Acuity OD'] = 'normal';
      _findingsValues['Visual Acuity OS'] = (vaOS != null && vaOS.isNotEmpty) ? vaOS : '20/20';
      _findingsStatus['Visual Acuity OS'] = 'normal';

      String iopText = '15 mmHg (Normal)';
      if ((iopOD != null && iopOD.isNotEmpty) || (iopOS != null && iopOS.isNotEmpty)) {
        iopText = 'OD: ${iopOD ?? "-"} mmHg, OS: ${iopOS ?? "-"} mmHg';
      }
      _findingsValues['Eye Pressure (IOP)'] = iopText;
      _findingsStatus['Eye Pressure (IOP)'] = 'normal';

      _findingsValues['Anterior Chamber & Cornea'] = 'Clear, deep and quiet';
      _findingsStatus['Anterior Chamber & Cornea'] = 'normal';

      String fundusText = 'Normal disc, cup-to-disc 0.3';
      if ((fundusOD != null && fundusOD.isNotEmpty) || (fundusOS != null && fundusOS.isNotEmpty)) {
        fundusText = 'OD: ${fundusOD ?? "-"} | OS: ${fundusOS ?? "-"}';
      }
      _findingsValues['Fundoscopy / Retina'] = fundusText;
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

    _setDefaultFindings(isEnt, patient.vitalSigns ?? widget.queueEntry?.vitalSigns);

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
          _buildVitalSignsCard(
            patient.vitalSigns ?? widget.queueEntry?.vitalSigns,
            themeColor,
            !isEnt,
          ),

          const SizedBox(height: 16),

          // ── 3. CHIEF COMPLAINT / SYMPTOMS / CAUSE OF CONSULTATION ────
          _buildSymptomsAndComplaintCard(
            patient,
            doctorProv.currentDeptRecord,
            doctorProv.currentPatientDeptRecords,
            themeColor,
          ),

          const SizedBox(height: 20),

          // ── 4. CLINICAL DIAGRAMS & ANATOMICAL DRAWINGS (DOCTOR CONSULTATION) ─
          _buildClinicalDiagramsSection(context, exams, themeColor, isEnt),

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

  Widget _buildVitalSignsCard(VitalSigns? vitals, Color themeColor, bool isEyes) {
    final hasVitals = vitals != null && vitals.isNotEmpty;
    final bp = vitals?.bloodPressure ?? (hasVitals ? '-' : '120/80');
    final temp = vitals?.temperature != null ? '${vitals!.temperature}°C' : (hasVitals ? '-' : '36.5°C');
    final hr = vitals?.heartRate != null ? '${vitals!.heartRate} bpm' : (hasVitals ? '-' : '75 bpm');
    final rr = vitals?.respiratoryRate != null ? '${vitals!.respiratoryRate}/min' : (hasVitals ? '-' : '18/min');
    final spo2 = vitals?.oxygenSaturation != null ? '${vitals!.oxygenSaturation}%' : (hasVitals ? '-' : '98%');
    final wt = vitals?.weight != null ? '${vitals!.weight} kg' : (hasVitals ? '-' : '62.0 kg');
    final ht = vitals?.height != null ? '${vitals!.height} cm' : (hasVitals ? '-' : '165 cm');

    final hasEyeVitals = vitals?.hasEyeVitals == true;

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
                  'Triage Vital Signs (Nurse Station Intake)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasVitals
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasVitals ? 'INTAKE COMPLETED' : 'DEFAULT BASELINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: hasVitals ? const Color(0xFF10B981) : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 560;
                if (isCompact) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildVitalMetric('Temp', temp, Icons.thermostat_rounded, Colors.orange),
                          _buildVitalMetric('BP', bp, Icons.favorite_border_rounded, Colors.red),
                          _buildVitalMetric('HR / PR', hr, Icons.favorite_rounded, Colors.pink),
                          _buildVitalMetric('RR', rr, Icons.air_rounded, AppColors.cyanCalm),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildVitalMetric('SpO2', spo2, Icons.water_drop_rounded, const Color(0xFF0D9488)),
                          _buildVitalMetric('Weight', wt, Icons.scale_rounded, Colors.indigo),
                          _buildVitalMetric('Height', ht, Icons.straighten_rounded, Colors.teal),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildVitalMetric('Temp', temp, Icons.thermostat_rounded, Colors.orange),
                    _buildVitalMetric('BP', bp, Icons.favorite_border_rounded, Colors.red),
                    _buildVitalMetric('HR / PR', hr, Icons.favorite_rounded, Colors.pink),
                    _buildVitalMetric('RR', rr, Icons.air_rounded, AppColors.cyanCalm),
                    _buildVitalMetric('SpO2', spo2, Icons.water_drop_rounded, const Color(0xFF0D9488)),
                    _buildVitalMetric('Weight', wt, Icons.scale_rounded, Colors.indigo),
                    _buildVitalMetric('Height', ht, Icons.straighten_rounded, Colors.teal),
                  ],
                );
              },
            ),

            // Ophthalmic Eye Vitals (Crucial for Eyes consultation or when eye vitals recorded)
            if (hasEyeVitals || isEyes) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cyanCalm.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cyanCalm.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.visibility_rounded, size: 14, color: AppColors.cyanCalm),
                        SizedBox(width: 6),
                        Text(
                          'OPHTHALMIC TRIAGE VITALS (NURSE STATION)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.cyanCalm,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (hasEyeVitals) ...[
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (vitals!.visualAcuityOD != null || vitals.visualAcuityOS != null)
                            _buildEyeMetricBadge(
                              'Visual Acuity (VA c/-)',
                              'OD: ${vitals.visualAcuityOD ?? "-"}  |  OS: ${vitals.visualAcuityOS ?? "-"}',
                            ),
                          if (vitals.intraocularPressureOD != null || vitals.intraocularPressureOS != null)
                            _buildEyeMetricBadge(
                              'Intraocular Pressure (IOP)',
                              'OD: ${vitals.intraocularPressureOD ?? "-"}  |  OS: ${vitals.intraocularPressureOS ?? "-"} mmHg',
                            ),
                          if (vitals.funduscopyOD != null || vitals.funduscopyOS != null)
                            _buildEyeMetricBadge(
                              'Funduscopy / Retina',
                              'OD: ${vitals.funduscopyOD ?? "-"}  |  OS: ${vitals.funduscopyOS ?? "-"}',
                            ),
                          if (vitals.extraocularMuscleMovement != null && vitals.extraocularMuscleMovement!.isNotEmpty)
                            _buildEyeMetricBadge(
                              'EOMM',
                              vitals.extraocularMuscleMovement!,
                            ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'No ophthalmic measurements recorded during triage yet.',
                        style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            if (vitals?.notes != null && vitals!.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Nurse Notes: ${vitals.notes}',
                style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEyeMetricBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cyanCalm.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.cyanCalm,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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

  IconData _getPmhIcon(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('hyper') || c.contains('blood pressure') || c.contains('htn')) return Icons.monitor_heart_rounded;
    if (c.contains('diabetes') || c.contains('dm') || c.contains('sugar')) return Icons.water_drop_rounded;
    if (c.contains('allerg')) return Icons.warning_amber_rounded;
    if (c.contains('glaucoma') || c.contains('eye')) return Icons.visibility_rounded;
    if (c.contains('operat') || c.contains('surg')) return Icons.local_hospital_rounded;
    if (c.contains('medic')) return Icons.medication_rounded;
    return Icons.health_and_safety_rounded;
  }

  Color _getPmhColor(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('hyper') || c.contains('blood pressure') || c.contains('htn')) return const Color(0xFFEF4444);
    if (c.contains('diabetes') || c.contains('dm') || c.contains('sugar')) return const Color(0xFFF59E0B);
    if (c.contains('allerg')) return const Color(0xFF8B5CF6);
    if (c.contains('glaucoma') || c.contains('eye')) return const Color(0xFF06B6D4);
    if (c.contains('operat') || c.contains('surg')) return const Color(0xFF3B82F6);
    if (c.contains('medic')) return const Color(0xFF10B981);
    return const Color(0xFF6366F1);
  }

  Widget _buildSymptomsAndComplaintCard(
    Patient patient,
    PatientDeptRecord? deptRecord,
    List<PatientDeptRecord> allDeptRecords,
    Color themeColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doctorProv = context.read<DoctorProvider>();
    final activeDept = deptRecord?.department ?? widget.queueEntry?.department ?? 'ENT';
    final complaint = deptRecord?.chiefComplaint?.isNotEmpty == true
        ? deptRecord!.chiefComplaint!
        : (patient.chiefComplaint?.isNotEmpty == true ? patient.chiefComplaint! : null);
    final hpi = deptRecord?.historyOfPresentIllness?.isNotEmpty == true
        ? deptRecord!.historyOfPresentIllness!
        : (patient.historyOfPresentIllness?.isNotEmpty == true ? patient.historyOfPresentIllness! : null);
    final structuredConditions =
        (deptRecord != null && deptRecord.effectiveConditions.isNotEmpty)
            ? deptRecord.effectiveConditions
            : patient.pmhConditionsList;
    final fallbackPmh =
        deptRecord?.pastMedicalHistory ?? patient.pastMedicalHistory;

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
            // Header with department indicator and multi-dept switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.report_problem_rounded, color: themeColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'CAUSE OF CONSULTATION & CLINICAL INTAKE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: themeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    activeDept.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: themeColor,
                    ),
                  ),
                ),
              ],
            ),

            // If patient has multiple department records (e.g. ENT & EYES), show tabs
            if (allDeptRecords.length > 1) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    const Text(
                      'Records Available:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    ...allDeptRecords.map((r) {
                      final isSelected = r.department.toUpperCase() == activeDept.toUpperCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => doctorProv.switchViewedDepartmentRecord(r.department),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? themeColor
                                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.department.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: themeColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint ?? 'No specific chief complaint recorded at reception.',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ],
              ),
            ),

            if (hpi != null && hpi.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'History of Present Illness (HPI):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                hpi,
                style: const TextStyle(fontSize: 13, height: 1.3),
              ),
            ],

            // ── STRUCTURED PAST MEDICAL HISTORY & MEDICATIONS ──────
            if (structuredConditions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.medical_services_outlined, size: 16, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    'PAST MEDICAL HISTORY & MEDICATIONS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...structuredConditions.map((cond) {
                final condColor = _getPmhColor(cond.condition);
                final condIcon = _getPmhIcon(cond.condition);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: condColor.withValues(alpha: isDark ? 0.08 : 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: condColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(condIcon, size: 16, color: condColor),
                          const SizedBox(width: 6),
                          Text(
                            cond.condition,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: condColor,
                            ),
                          ),
                        ],
                      ),
                      if (cond.medications.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: cond.medications.map((med) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: condColor.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.medication_rounded, size: 12, color: condColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    med,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        const SizedBox(height: 2),
                        const Text(
                          'No specific medications recorded',
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (fallbackPmh != null && fallbackPmh.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Additional PMH notes: $fallbackPmh',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ] else if (fallbackPmh != null && fallbackPmh.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Past Medical History:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Text(
                  fallbackPmh,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalDiagramsSection(
    BuildContext context,
    List<Map<String, dynamic>> exams,
    Color themeColor,
    bool isEnt,
  ) {
    // Strictly isolate diagrams by department
    final deptExams = exams.where((group) {
      final groupDept = group['department']?.toString().toUpperCase();
      final examType = group['exam_type']?.toString().toUpperCase() ?? '';
      if (!isEnt) {
        // EYES consultation: STRICTLY EYES diagrams only
        return groupDept == 'EYES' || examType == 'EYES' || examType == 'EYE';
      } else {
        // ENT consultation: STRICTLY ENT diagrams only (no eyes)
        return groupDept != 'EYES' && examType != 'EYES' && examType != 'EYE';
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 520;
            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.draw_rounded, color: Color(0xFF0D9488), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEnt
                              ? 'ENT Anatomical Drawings'
                              : 'Eye Clinical Diagrams',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${deptExams.length} Diagrams',
                          style: const TextStyle(
                            color: Color(0xFF0D9488),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => isEnt
                            ? _showEntDiagramSelectorModal(context)
                            : _showEyeDiagramSelectorModal(context),
                        icon: const Icon(Icons.brush_rounded, size: 15),
                        label: const Text('+ Draw Diagram'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.draw_rounded, color: Color(0xFF0D9488), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isEnt
                          ? 'ENT Anatomical Drawings & Annotations'
                          : 'Eye Clinical Diagrams & Anatomical Drawings',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${deptExams.length} Diagrams',
                        style: const TextStyle(
                          color: Color(0xFF0D9488),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => isEnt
                          ? _showEntDiagramSelectorModal(context)
                          : _showEyeDiagramSelectorModal(context),
                      icon: const Icon(Icons.brush_rounded, size: 15),
                      label: const Text('+ Draw Diagram'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        if (deptExams.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Icon(
                  isEnt ? Icons.hearing_rounded : Icons.visibility_rounded,
                  size: 36,
                  color: (isEnt ? const Color(0xFFF59E0B) : AppColors.cyanCalm).withValues(alpha: 0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  'No ${isEnt ? "ENT" : "ophthalmic"} anatomical diagrams recorded for this patient yet.',
                  style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => isEnt
                      ? _showEntDiagramSelectorModal(context)
                      : _showEyeDiagramSelectorModal(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Open ${isEnt ? "ENT" : "Eye"} Drawing Board'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D9488),
                    side: const BorderSide(color: Color(0xFF0D9488), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          )
        else
          ...deptExams.map((group) => _buildExamGroupCard(context, group, themeColor, isEnt)),
      ],
    );
  }

  Widget _buildExamGroupCard(
    BuildContext context,
    Map<String, dynamic> group,
    Color themeColor,
    bool isEnt,
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
                        'CLINICAL FINDINGS & ANATOMICAL NOTES:',
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
                        : 'No detailed clinical descriptions provided.',
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
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openDrawingScreen(
                    examType: examType,
                    department: group['department']?.toString() ?? (isEnt ? 'ENT' : 'EYES'),
                    examinationUuid: group['examination_uuid'],
                    savedDiagram: group['items'],
                    viewMode: false,
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Annotate / Edit Diagram'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D9488),
                    side: const BorderSide(color: Color(0xFF0D9488)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _openDrawingScreen(
                    examType: examType,
                    department: group['department']?.toString() ?? (isEnt ? 'ENT' : 'EYES'),
                    examinationUuid: group['examination_uuid'],
                    savedDiagram: group['items'],
                    viewMode: true,
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 15),
                  label: const Text('Full View'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEyeDiagramSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cyanCalm.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.visibility_rounded, color: AppColors.cyanCalm, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eye Anatomical Diagrams',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          Text(
                            'Strictly Ophthalmology views for Eyes consultation',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDiagramSelectorTile(
                  ctx,
                  icon: Icons.remove_red_eye_rounded,
                  color: AppColors.cyanCalm,
                  title: 'Gross Examination',
                  subtitle: 'External eye anatomy, eyelids, conjunctiva & sclera (View 1)',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openDrawingScreen(examType: 'eyes', department: 'EYES');
                  },
                ),
                _buildDiagramSelectorTile(
                  ctx,
                  icon: Icons.blur_circular_rounded,
                  color: const Color(0xFF6366F1),
                  title: 'Fundoscopy',
                  subtitle: 'Retina, optic disc, macula & vascular arcade (View 2)',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openDrawingScreen(examType: 'eyes', department: 'EYES');
                  },
                ),
                _buildDiagramSelectorTile(
                  ctx,
                  icon: Icons.biotech_rounded,
                  color: const Color(0xFF0D9488),
                  title: 'Biomicroscopy',
                  subtitle: 'Slit-lamp examination, anterior chamber, cornea & lens (View 3)',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openDrawingScreen(examType: 'eyes', department: 'EYES');
                  },
                ),
                _buildDiagramSelectorTile(
                  ctx,
                  icon: Icons.draw_rounded,
                  color: Colors.blueGrey,
                  title: 'Blank Canvas',
                  subtitle: 'Freehand ophthalmic drawing & clinical sketch',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openDrawingScreen(examType: 'drawing', department: 'EYES');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEntDiagramSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.hearing_rounded, color: Color(0xFFF59E0B), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ENT Anatomical Diagrams',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            Text(
                              'Strictly Ear, Nose, Throat, Head & Neck views',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDiagramSelectorTile(
                    ctx,
                    icon: Icons.hearing_rounded,
                    color: const Color(0xFFF59E0B),
                    title: 'Ears (Otology)',
                    subtitle: 'Pinna, external auditory canal & tympanic membrane (Views 1-3)',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openDrawingScreen(examType: 'ears', department: 'ENT');
                    },
                  ),
                  _buildDiagramSelectorTile(
                    ctx,
                    icon: Icons.air_rounded,
                    color: const Color(0xFF10B981),
                    title: 'Nose (Rhinology)',
                    subtitle: 'Nasal cavity, septum, turbinates & sinuses (View 1)',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openDrawingScreen(examType: 'nose', department: 'ENT');
                    },
                  ),
                  _buildDiagramSelectorTile(
                    ctx,
                    icon: Icons.coronavirus_rounded,
                    color: const Color(0xFFEC4899),
                    title: 'Throat / Laryngology',
                    subtitle: 'Oropharynx, tonsils, larynx & vocal cords (Views 1-3)',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openDrawingScreen(examType: 'throat', department: 'ENT');
                    },
                  ),
                  _buildDiagramSelectorTile(
                    ctx,
                    icon: Icons.face_rounded,
                    color: const Color(0xFF3B82F6),
                    title: 'Head (Cranial / Facial)',
                    subtitle: 'Anterior & lateral cranial/facial views (Views 1-2)',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openDrawingScreen(examType: 'head', department: 'ENT');
                    },
                  ),
                  _buildDiagramSelectorTile(
                    ctx,
                    icon: Icons.accessibility_new_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: 'Neck (Cervical / Lymph Nodes)',
                    subtitle: 'Anterior triangle, thyroid & cervical chain (View 1)',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openDrawingScreen(examType: 'neck', department: 'ENT');
                    },
                  ),
                  _buildDiagramSelectorTile(
                    ctx,
                    icon: Icons.draw_rounded,
                    color: Colors.blueGrey,
                    title: 'Blank Canvas',
                    subtitle: 'Freehand ENT diagram & clinical sketches',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openDrawingScreen(examType: 'drawing', department: 'ENT');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiagramSelectorTile(
    BuildContext ctx, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey),
      ),
    );
  }

  Future<void> _openDrawingScreen({
    required String examType,
    required String department,
    String? examinationUuid,
    dynamic savedDiagram,
    bool viewMode = false,
  }) async {
    final doctorProv = context.read<DoctorProvider>();
    final patient = doctorProv.currentPatient;
    if (patient == null) return;

    final complaint = doctorProv.currentDeptRecord?.chiefComplaint ??
        patient.chiefComplaint ??
        widget.queueEntry?.purpose;
    final hpi = doctorProv.currentDeptRecord?.historyOfPresentIllness ??
        patient.historyOfPresentIllness;
    final pmh = doctorProv.currentDeptRecord?.pmhSummaryText ??
        patient.pastMedicalHistory;

    await context.push(
      '/nurse/drawing',
      extra: {
        'patientId': widget.patientId,
        'patientName': patient.fullName,
        'examType': examType,
        'department': department,
        'queueNumber': widget.queueEntry?.queueNumber,
        'queueEntryId': widget.queueEntry?.id,
        'examinationUuid': examinationUuid,
        'savedDiagram': savedDiagram,
        'viewMode': viewMode,
        'chiefComplaint': complaint,
        'historyOfPresentIllness': hpi,
        'pastMedicalHistory': pmh,
      },
    );

    if (mounted) {
      await doctorProv.loadConsultation(
        patientId: widget.patientId,
        queueEntry: widget.queueEntry,
      );
    }
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
