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
        id: json['id']?.toString() ?? '',
        patientId: json['patient_id']?.toString() ?? '',
        department: json['department']?.toString() ?? 'ENT',
        purpose: json['purpose']?.toString() ?? 'Consultation',
        chiefComplaint: json['chief_complaint']?.toString(),
        diagnosis: json['diagnosis']?.toString(),
        notes: json['notes']?.toString(),
        assignedRoom: json['assigned_room']?.toString(),
        queueNumber: json['queue_number']?.toString() ?? '',
        visitDate: json['visit_date'] != null
            ? DateTime.tryParse(json['visit_date'].toString())
            : null,
      );
}
