/// A structured past-medical-history condition with its medications list.
class PmhCondition {
  final String condition;
  final List<String> medications;

  const PmhCondition({required this.condition, this.medications = const []});

  Map<String, dynamic> toJson() => {
        'condition': condition,
        'medications': medications,
      };

  factory PmhCondition.fromJson(Map<String, dynamic> j) => PmhCondition(
        condition: j['condition']?.toString() ?? '',
        medications:
            (j['medications'] as List?)?.map((e) => e.toString()).toList() ??
                [],
      );

  PmhCondition copyWith({String? condition, List<String>? medications}) =>
      PmhCondition(
        condition: condition ?? this.condition,
        medications: medications ?? this.medications,
      );

  /// Formats a list of PmhCondition objects (and optional free-text other)
  /// into a structured string suitable for saving to patients.past_medical_history.
  /// Example: "Hypertension (Amlodipine, Losartan); DM (Metformin); Allergies"
  static String formatList(List<PmhCondition> conditions, [String? other]) {
    final parts = <String>[];
    for (final c in conditions) {
      if (c.condition.trim().isEmpty) continue;
      if (c.medications.isNotEmpty) {
        parts.add('${c.condition} (${c.medications.join(', ')})');
      } else {
        parts.add(c.condition);
      }
    }
    if (other != null && other.trim().isNotEmpty) {
      parts.add(other.trim());
    }
    return parts.join('; ');
  }

  /// Parses a past-medical-history string into a `List<PmhCondition>`.
  /// Handles semicolon-separated, newline-separated, or comma-separated lists,
  /// with or without parenthesized medication names.
  static List<PmhCondition> parseFromText(String? text) {
    if (text == null || text.trim().isEmpty) return [];

    final raw = text.trim();
    final tokens = <String>[];
    final buffer = StringBuffer();
    int parenDepth = 0;
    final primaryDelimiter = raw.contains(';') ? ';' : (raw.contains('\n') ? '\n' : ',');

    for (int i = 0; i < raw.length; i++) {
      final char = raw[i];
      if (char == '(') {
        parenDepth++;
        buffer.write(char);
      } else if (char == ')') {
        if (parenDepth > 0) parenDepth--;
        buffer.write(char);
      } else if (char == primaryDelimiter && parenDepth == 0) {
        final t = buffer.toString().trim();
        if (t.isNotEmpty) tokens.add(t);
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) tokens.add(remaining);

    final results = <PmhCondition>[];
    for (var part in tokens) {
      part = part.trim();
      if (part.isEmpty) continue;

      final parenMatch = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(part);
      if (parenMatch != null) {
        final condName = parenMatch.group(1)?.trim() ?? '';
        final medsStr = parenMatch.group(2)?.trim() ?? '';
        final meds = medsStr
            .split(',')
            .map((m) => m.trim())
            .where((m) => m.isNotEmpty)
            .toList();
        if (condName.isNotEmpty) {
          results.add(PmhCondition(condition: condName, medications: meds));
        }
      } else {
        results.add(PmhCondition(condition: part, medications: const []));
      }
    }
    return results;
  }
}

/// Department-scoped clinical record for a patient (one per ENT, one per EYES).
/// Allows the same patient to have independent chief complaint, PMH,
/// assigned doctor, and first-time flag for each department.
class PatientDeptRecord {
  final String id;
  final String patientId;
  final String department; // 'ENT' or 'EYES'
  final String? chiefComplaint;
  final String? historyOfPresentIllness;
  final String? pastMedicalHistory; // legacy free-text fallback
  final List<PmhCondition> pmhConditions; // structured: [{condition, medications}]
  final bool isFirstTime;
  final String? assignedDoctor;
  final String? assignedRoom;
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientDeptRecord({
    required this.id,
    required this.patientId,
    required this.department,
    this.chiefComplaint,
    this.historyOfPresentIllness,
    this.pastMedicalHistory,
    List<PmhCondition>? pmhConditions,
    this.isFirstTime = true,
    this.assignedDoctor,
    this.assignedRoom,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : pmhConditions = pmhConditions ?? const [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ── Convenience helpers ─────────────────────────────────────────────────────

  /// Returns a flat text summary of all PMH conditions and their medications
  /// for display / legacy text fields.
  String get pmhSummaryText {
    if (pmhConditions.isEmpty) return pastMedicalHistory ?? '';
    final parts = pmhConditions.map((c) {
      if (c.medications.isEmpty) return c.condition;
      return '${c.condition}: ${c.medications.join(', ')}';
    }).toList();
    if (pastMedicalHistory != null && pastMedicalHistory!.isNotEmpty) {
      parts.add(pastMedicalHistory!);
    }
    return parts.join(' | ');
  }

  /// Returns pmhConditions if present, otherwise parses pastMedicalHistory.
  List<PmhCondition> get effectiveConditions {
    if (pmhConditions.isNotEmpty) return pmhConditions;
    if (pastMedicalHistory != null && pastMedicalHistory!.isNotEmpty) {
      return PmhCondition.parseFromText(pastMedicalHistory);
    }
    return const [];
  }

  /// True if a condition name is active in pmhConditions.
  bool hasCondition(String condition) =>
      effectiveConditions.any((c) => c.condition == condition);

  /// Get medications for a specific condition (empty list if not found).
  List<String> medicationsFor(String condition) {
    try {
      return effectiveConditions
          .firstWhere((c) => c.condition.toLowerCase() == condition.toLowerCase())
          .medications;
    } catch (_) {
      return [];
    }
  }

  // ── Serialisation ───────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'department': department,
        'chief_complaint': chiefComplaint,
        'history_of_present_illness': historyOfPresentIllness,
        'past_medical_history': pastMedicalHistory,
        'pmh_conditions': pmhConditions.map((c) => c.toJson()).toList(),
        'is_first_time': isFirstTime,
        'assigned_doctor': assignedDoctor,
        'assigned_room': assignedRoom,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Supabase-safe payload (no virtual fields).
  Map<String, dynamic> toSupabaseJson() => {
        'id': id,
        'patient_id': patientId,
        'department': department,
        if (chiefComplaint != null) 'chief_complaint': chiefComplaint,
        if (historyOfPresentIllness != null)
          'history_of_present_illness': historyOfPresentIllness,
        if (pastMedicalHistory != null) 'past_medical_history': pastMedicalHistory,
        'pmh_conditions': pmhConditions.map((c) => c.toJson()).toList(),
        'is_first_time': isFirstTime,
        if (assignedDoctor != null) 'assigned_doctor': assignedDoctor,
        if (assignedRoom != null) 'assigned_room': assignedRoom,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory PatientDeptRecord.fromJson(Map<String, dynamic> j) {
    List<PmhCondition> conditions = [];
    final raw = j['pmh_conditions'];
    if (raw is List) {
      conditions = raw
          .whereType<Map>()
          .map((e) => PmhCondition.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return PatientDeptRecord(
      id: j['id']?.toString() ?? '',
      patientId: j['patient_id']?.toString() ?? '',
      department: j['department']?.toString() ?? 'ENT',
      chiefComplaint: j['chief_complaint']?.toString(),
      historyOfPresentIllness: j['history_of_present_illness']?.toString(),
      pastMedicalHistory: j['past_medical_history']?.toString(),
      pmhConditions: conditions,
      isFirstTime: j['is_first_time'] != false,
      assignedDoctor: j['assigned_doctor']?.toString(),
      assignedRoom: j['assigned_room']?.toString(),
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: j['updated_at'] != null
          ? DateTime.tryParse(j['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  PatientDeptRecord copyWith({
    String? chiefComplaint,
    String? historyOfPresentIllness,
    String? pastMedicalHistory,
    List<PmhCondition>? pmhConditions,
    bool? isFirstTime,
    String? assignedDoctor,
    String? assignedRoom,
  }) =>
      PatientDeptRecord(
        id: id,
        patientId: patientId,
        department: department,
        chiefComplaint: chiefComplaint ?? this.chiefComplaint,
        historyOfPresentIllness:
            historyOfPresentIllness ?? this.historyOfPresentIllness,
        pastMedicalHistory: pastMedicalHistory ?? this.pastMedicalHistory,
        pmhConditions: pmhConditions ?? this.pmhConditions,
        isFirstTime: isFirstTime ?? this.isFirstTime,
        assignedDoctor: assignedDoctor ?? this.assignedDoctor,
        assignedRoom: assignedRoom ?? this.assignedRoom,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
