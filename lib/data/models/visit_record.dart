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
    required this.queueNumber,
    DateTime? visitDate,
  }) : visitDate = visitDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'department': department,
        'purpose': purpose,
        'chief_complaint': chiefComplaint,
        'diagnosis': diagnosis,
        'notes': notes,
        'assigned_room': assignedRoom,
        'queue_number': queueNumber,
        'visit_date': visitDate.toIso8601String(),
      };

  factory VisitRecord.fromJson(Map<String, dynamic> json) => VisitRecord(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        department: json['department'] as String,
        purpose: json['purpose'] as String,
        chiefComplaint: json['chief_complaint'] as String?,
        diagnosis: json['diagnosis'] as String?,
        notes: json['notes'] as String?,
        assignedRoom: json['assigned_room'] as String?,
        queueNumber: json['queue_number'] as String,
        visitDate: json['visit_date'] != null
            ? DateTime.parse(json['visit_date'] as String)
            : null,
      );
}
