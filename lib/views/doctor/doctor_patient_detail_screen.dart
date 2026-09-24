import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/models/clinical_examination.dart';
import '../../data/models/patient.dart';
import '../../data/models/visit_record.dart';
import '../../data/repositories/examination_repository.dart';
import '../../data/repositories/patient_repository.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  final String patientId;

  const DoctorPatientDetailScreen({super.key, required this.patientId});

  @override
  State<DoctorPatientDetailScreen> createState() =>
      _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen>
    with SingleTickerProviderStateMixin {
  final PatientRepository _patientRepo = PatientRepository();
  final ExaminationRepository _examRepo = ExaminationRepository();

  late TabController _tabController;
  Patient? _patient;
  List<VisitRecord> _visits = [];
  List<Map<String, dynamic>> _exams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final p = await _patientRepo.getPatient(widget.patientId);
      final v = await _patientRepo.fetchVisitHistory(widget.patientId);
      final e = await _examRepo.getGroupedExaminations(widget.patientId);

      if (mounted) {
        setState(() {
          _patient = p;
          _visits = v;
          _exams = e;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = err.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = AppColors.doctorPrimary;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Record')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Record')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error ?? 'Patient record not found.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Back to Patients'),
              ),
            ],
          ),
        ),
      );
    }

    final p = _patient!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${p.fullName} (${p.patientNo})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => context.push('/doctor/consultation/${p.id}'),
            icon: const Icon(Icons.medical_services_rounded, size: 16),
            label: const Text('Start Consultation'),
            style: FilledButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Refresh Patient Record',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: themeColor,
          labelColor: themeColor,
          isScrollable: true,
          tabs: [
            const Tab(icon: Icon(Icons.person_pin_rounded, size: 18), text: 'Demographics & Vitals'),
            Tab(
              icon: const Icon(Icons.draw_rounded, size: 18),
              text: 'Nurse Drawings & Exams (${_exams.length})',
            ),
            Tab(
              icon: const Icon(Icons.history_rounded, size: 18),
              text: 'Visit History (${_visits.length})',
            ),
            const Tab(icon: Icon(Icons.medication_rounded, size: 18), text: 'Prescriptions / Rx'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Demographics & Vitals ─────────────────────────
          _buildDemographicsTab(p, themeColor),

          // ── Tab 2: Nurse Clinical Drawings & Diagnostics ──────────
          _buildNurseExamsTab(themeColor),

          // ── Tab 3: Visit History ──────────────────────────────────
          _buildVisitHistoryTab(themeColor),

          // ── Tab 4: Prescriptions ──────────────────────────────────
          _buildPrescriptionsTab(themeColor),
        ],
      ),
    );
  }

  // ── Tab 1: Demographics & Vitals ──────────────────────────────
  Widget _buildDemographicsTab(Patient p, Color themeColor) {
    final v = p.vitalSigns;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Summary Card
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      AppImageHelper.buildAvatar(
                        photoUrl: p.photoUrl,
                        name: p.fullName,
                        radius: 36,
                        backgroundColor: themeColor.withValues(alpha: 0.15),
                        foregroundColor: themeColor,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.fullName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildBadge('ID: ${p.patientNo}', AppColors.doctorPrimary),
                                _buildBadge('${p.age} years old', Colors.teal),
                                _buildBadge(p.sex.toUpperCase(), Colors.purple),
                                if (p.civilStatus.isNotEmpty)
                                  _buildBadge(p.civilStatus, Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Assigned to: ${p.assignedDoctor ?? 'Doctor Consultation'}${p.assignedRoom != null && p.assignedRoom!.isNotEmpty ? ' • Room: ${p.assignedRoom}' : ''}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Vitals Sign Card (recorded by Nurse at triage)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.monitor_heart_rounded, color: Colors.redAccent, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Triage Vital Signs (Recorded by Nurse)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (v == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No triage vitals recorded yet for this visit.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 16,
                          runSpacing: 14,
                          children: [
                            _buildVitalTile('Blood Pressure', v.bloodPressure ?? '—', 'mmHg', Icons.speed_rounded),
                            _buildVitalTile('Heart Rate', '${v.heartRate ?? '—'}', 'bpm', Icons.favorite_rounded),
                            _buildVitalTile('Temperature', '${v.temperature ?? '—'}', '°C', Icons.thermostat_rounded),
                            _buildVitalTile('Oxygen Saturation', '${v.oxygenSaturation ?? '—'}', '% SpO2', Icons.air_rounded),
                            _buildVitalTile('Weight', '${v.weight ?? '—'}', 'kg', Icons.scale_rounded),
                            _buildVitalTile('Respiratory Rate', '${v.respiratoryRate ?? '—'}', 'cpm', Icons.air_rounded),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Clinical Complaint & Background
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medical_information_rounded, color: AppColors.doctorPrimary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Chief Complaint & Clinical Background',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDetailRow('Chief Complaint / Symptoms', p.chiefComplaint ?? 'None specified'),
                      _buildDetailRow('History of Present Illness', p.historyOfPresentIllness ?? 'None specified'),
                      _buildDetailRow('Past Medical History', p.pastMedicalHistory ?? 'None specified'),
                      _buildDetailRow('Contact Phone Number', p.contactNumber.isNotEmpty ? p.contactNumber : 'N/A'),
                      _buildDetailRow('Home Address', p.address.isNotEmpty ? p.address : 'N/A'),
                      _buildDetailRow('Occupation', p.occupation ?? 'N/A'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 2: Nurse Clinical Drawings & Diagnostics ──────────────
  Widget _buildNurseExamsTab(Color themeColor) {
    if (_exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.draw_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No nurse clinical diagrams recorded yet.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'When the nurse completes Ear, Nose, Throat, or Eye drawings, they appear here.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _exams.length,
      itemBuilder: (context, i) {
        final exam = _exams[i];
        final rawItems = exam['items'];
        final List<ClinicalExamination> items = rawItems is List
            ? rawItems.whereType<ClinicalExamination>().toList()
            : [];
        final rawViews = (exam['views'] as List?) ?? [];
        final examType = exam['exam_type']?.toString().toUpperCase() ?? 'EXAM';
        final examiner = exam['examiner_name']?.toString() ?? 'Triage Nurse';
        final notes = exam['clinical_findings']?.toString() ??
            exam['notes']?.toString() ??
            '';
        final symptoms = exam['symptoms']?.toString() ?? '';
        final cause = exam['cause']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        examType,
                        style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Recorded by $examiner',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),

                if (symptoms.isNotEmpty || cause.isNotEmpty || notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (symptoms.isNotEmpty)
                          Text('Symptoms: $symptoms', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        if (cause.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Probable Cause: $cause', style: const TextStyle(fontSize: 13)),
                          ),
                        if (notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Nurse Notes: $notes', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Text('Clinical Drawings & Views:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),

                // Diagram images grid (supporting both items and views)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ...items.map<Widget>((item) {
                      final viewName = 'View ${item.viewName}';
                      final imgUrl = item.imageUrl ?? '';

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showDiagramModal(context, '$examType ($viewName)', imgUrl),
                        child: Container(
                          width: 180,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 110,
                                  width: double.infinity,
                                  color: Colors.grey.shade100,
                                  child: AppImageHelper.buildDiagramImage(imgUrl),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                viewName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (items.isEmpty)
                      ...rawViews.map<Widget>((v) {
                        final viewName = v['view_name']?.toString() ?? 'View';
                        final imgData = v['image_data']?.toString() ?? '';

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showDiagramModal(context, viewName, imgData),
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 110,
                                    width: double.infinity,
                                    color: Colors.grey.shade100,
                                    child: AppImageHelper.buildDiagramImage(imgData),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  viewName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Tab 3: Visit History ──────────────────────────────────────
  Widget _buildVisitHistoryTab(Color themeColor) {
    if (_visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No previous visit records found.', style: TextStyle(fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _visits.length,
      itemBuilder: (context, i) {
        final visit = _visits[i];
        final dateStr =
            '${visit.visitDate.year}-${visit.visitDate.month.toString().padLeft(2, '0')}-${visit.visitDate.day.toString().padLeft(2, '0')}';

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Visit Date: $dateStr',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        visit.department,
                        style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (visit.diagnosis != null && visit.diagnosis!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Diagnosis: ${visit.diagnosis}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                if (visit.chiefComplaint != null && visit.chiefComplaint!.isNotEmpty)
                  Text(
                    'Complaint: ${visit.chiefComplaint}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                if (visit.notes != null && visit.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Clinical Notes:\n${visit.notes}',
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Tab 4: Prescriptions ──────────────────────────────────────
  Widget _buildPrescriptionsTab(Color themeColor) {
    final prescriptions = _visits.where((v) => v.notes?.contains('Prescription') == true).toList();

    if (prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_liquid_rounded, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No prescriptions on file for this patient.', style: TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/doctor/consultation/${widget.patientId}'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Prescription in Consultation'),
              style: FilledButton.styleFrom(backgroundColor: themeColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: prescriptions.length,
      itemBuilder: (context, i) {
        final visit = prescriptions[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Prescription Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    Text(
                      '${visit.visitDate.month}/${visit.visitDate.day}/${visit.visitDate.year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  visit.notes ?? '',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildVitalTile(String label, String value, String unit, IconData icon) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.redAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            unit,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDiagramImage(String data) {
    return AppImageHelper.buildDiagramImage(data);
  }

  void _showDiagramModal(BuildContext context, String title, String data) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: _buildDiagramImage(data),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
