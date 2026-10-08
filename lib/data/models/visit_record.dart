/// Visit record for patient history tracking
class VisitRecord {
  final String id;
  final String patientId;
  final String department;
  final String purpose;
  final String? chiefComplaint;
  final String? diagnosis;
  final String? notes;
  final String? assignedRoom;
  final String? assignedDoctor;
  final String queueNumber;
  final DateTime visitDate;

  VisitRecord({
    required this.id,
    required this.patientId,
    required this.department,
    required this.purpose,
    this.chiefComplaint,
    this.diagnosis,
    this.notes,
    this.assignedRoom,
    this.assignedDoctor,
    required this.queueNumber,
    DateTime? visitDate,
  }) : visitDate = visitDate ?? DateTime.now();

  bool get isRegistration =>
      purpose.toLowerCase().contains('register') ||
      purpose.toLowerCase().contains('registration');

  bool get isConsultation =>
      !isRegistration &&
      (purpose.toLowerCase().contains('consult') ||
          (diagnosis != null && diagnosis!.isNotEmpty));

  bool get isOther => !isRegistration && !isConsultation;

  String get category {
    if (isRegistration) return 'Registered';
    if (isConsultation) return 'Consultation';
    return 'Other';
  }

  String? get doctorDisplay {
    if (assignedDoctor != null && assignedDoctor!.trim().isNotEmpty) {
      return assignedDoctor!.trim();
    }
    if (notes != null && notes!.contains('Doctor:')) {
      final match = RegExp(r'Doctor:\s*([^\n\r,•]+)').firstMatch(notes!);
      if (match != null) return match.group(1)?.trim();
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'department': department,
        'purpose': purpose,
        if (chiefComplaint != null) 'chief_complaint': chiefComplaint,
        if (diagnosis != null) 'diagnosis': diagnosis,
        if (notes != null) 'notes': notes,
        if (assignedRoom != null) 'assigned_room': assignedRoom,
        if (assignedDoctor != null) 'assigned_doctor': assignedDoctor,
        'queue_number': queueNumber,
        'visit_date': visitDate.toIso8601String(),
      };

  factory VisitRecord.fromJson(Map<String, dynamic> json) => VisitRecord(
        id: json['id']?.toString() ?? '',
        patientId: json['patient_id']?.toString() ?? '',
        department: json['department']?.toString() ?? 'ENT',
        purpose: json['purpose']?.toString() ?? 'Consultation',
        chiefComplaint: json['chief_complaint']?.toString(),
        diagnosis: json['diagnosis']?.toString(),
        notes: json['notes']?.toString(),
        assignedRoom: json['assigned_room']?.toString(),
        assignedDoctor: json['assigned_doctor']?.toString() ??
            _extractDoctor(json['notes']?.toString()),
        queueNumber: json['queue_number']?.toString() ?? '',
        visitDate: json['visit_date'] != null
            ? DateTime.tryParse(json['visit_date'].toString())
            : null,
      );

  static String? _extractDoctor(String? notes) {
    if (notes == null || !notes.contains('Doctor:')) return null;
    final match = RegExp(r'Doctor:\s*([^\n\r,•]+)').firstMatch(notes);
    return match?.group(1)?.trim();
  }
}
