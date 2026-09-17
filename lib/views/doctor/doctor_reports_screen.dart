import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/visit_record.dart';
import '../../data/repositories/patient_repository.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/queue_provider.dart';

class DoctorReportsScreen extends StatefulWidget {
  const DoctorReportsScreen({super.key});

  @override
  State<DoctorReportsScreen> createState() => _DoctorReportsScreenState();
}

class _DoctorReportsScreenState extends State<DoctorReportsScreen> {
  final PatientRepository _patientRepo = PatientRepository();
  List<VisitRecord> _allVisits = [];
  bool _isLoading = true;

  static const Color emeraldPrimary = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final visits = await _patientRepo.getAllVisitRecords();
      if (mounted) {
        setState(() {
          _allVisits = visits;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorProv = context.watch<DoctorProvider>();
    final queueProv = context.watch<QueueProvider>();

    final completedToday = doctorProv.getCompletedPatients(queueProv.todayQueue).length;
    final waitingCount = doctorProv.getAllWaitingPatients(queueProv.todayQueue).length;
    final totalPatients = doctorProv.patients.length;
    final firstTimeCount = doctorProv.patients.where((p) => p.isFirstTime).length;

    // Dynamically calculate diagnosis breakdown from real visit records & complaints
    final diagnosisCounts = <String, int>{};
    for (final v in _allVisits) {
      if (v.diagnosis != null && v.diagnosis!.trim().isNotEmpty) {
        final d = v.diagnosis!.trim();
        diagnosisCounts[d] = (diagnosisCounts[d] ?? 0) + 1;
      }
    }
    // Also include chief complaints if visits are still few
    for (final p in doctorProv.patients) {
      if (p.chiefComplaint != null && p.chiefComplaint!.trim().isNotEmpty) {
        final c = p.chiefComplaint!.trim();
        diagnosisCounts[c] = (diagnosisCounts[c] ?? 0) + 1;
      }
    }

    final sortedDiagnoses = diagnosisCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxDiagnosisCount = sortedDiagnoses.isNotEmpty ? sortedDiagnoses.first.value : 1;

    // Dynamically get follow-up / scheduled patients from queue & patients directory
    final followUpPatients = <Map<String, String>>[];
    for (final q in queueProv.todayQueue) {
      if (q.isWaiting || q.isServing || q.isCompleted) {
        String st = 'Waiting';
        if (q.isServing) st = 'In Progress';
        if (q.isCompleted) st = 'Completed';

        followUpPatients.add({
          'patient': q.patientName,
          'patientNo': q.queueNumber,
          'date': 'Today',
          'condition': q.purpose.isNotEmpty ? q.purpose : 'Consultation',
          'status': st,
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.analytics_rounded, size: 22, color: emeraldPrimary),
            const SizedBox(width: 8),
            Text(
              'Clinical Reports & Stats • ${doctorProv.activeDoctor}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Reports',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              doctorProv.loadPatients(forceRefresh: true);
              queueProv.initialize(forceRefresh: true);
              _loadReportData();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 4 Top Real Metrics Cards (Zero static data) ─
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.people_alt_rounded,
                              label: 'Total Patients',
                              value: '$totalPatients',
                              change: 'In clinic database',
                              color: emeraldPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.check_circle_rounded,
                              label: 'Consulted Today',
                              value: '$completedToday',
                              change: 'Completed visits',
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.hourglass_top_rounded,
                              label: 'In Visit Queue',
                              value: '$waitingCount',
                              change: 'Waiting in line',
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.person_add_rounded,
                              label: 'First-Time Patients',
                              value: '$firstTimeCount',
                              change: 'New registrations',
                              color: const Color(0xFF0D9488),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Real Diagnoses & Live Follow-Up Tracker ─────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dynamic Diagnoses Breakdown Card
                          Expanded(
                            flex: 6,
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.pie_chart_rounded, color: emeraldPrimary, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Clinical Diagnoses & Complaints',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Live Records (${sortedDiagnoses.length})',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    if (sortedDiagnoses.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 24),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Icon(Icons.notes_rounded, size: 40, color: Colors.grey.shade400),
                                              const SizedBox(height: 8),
                                              Text(
                                                'No diagnoses recorded yet.',
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Diagnoses from completed consultations will appear here automatically.',
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      ...sortedDiagnoses.take(8).map((entry) {
                                        final diagnosisName = entry.key;
                                        final count = entry.value;
                                        final ratio = count / maxDiagnosisCount;

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      diagnosisName,
                                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$count ${count == 1 ? 'case' : 'cases'}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: ratio,
                                                  minHeight: 6,
                                                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                                                  valueColor: const AlwaysStoppedAnimation<Color>(emeraldPrimary),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Real Follow-Up & Live Queue Tracker Card
                          Expanded(
                            flex: 4,
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.event_repeat_rounded, color: emeraldPrimary, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Patient Queue Tracker',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    if (followUpPatients.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 24),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Icon(Icons.queue_rounded, size: 40, color: Colors.grey.shade400),
                                              const SizedBox(height: 8),
                                              Text(
                                                'No patients in queue currently.',
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      ...followUpPatients.take(6).map((f) {
                                        final st = f['status']!;
                                        Color badgeCol = const Color(0xFFF59E0B);
                                        if (st == 'Completed') badgeCol = AppColors.success;
                                        if (st == 'In Progress') badgeCol = emeraldPrimary;

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).scaffoldBackgroundColor,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      f['patient']!,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: badgeCol.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      st.toUpperCase(),
                                                      style: TextStyle(
                                                        color: badgeCol,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                f['condition']!,
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.confirmation_number_outlined,
                                                      size: 12, color: Colors.grey.shade500),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    f['patientNo']!,
                                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              ),
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
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String change,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              change,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
