import 'vital_signs.dart';

/// Queue entry representing a patient in the queue
class QueueEntry {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientPhoto;
  final String department; // 'ENT' or 'EYES'
  final String queueNumber; // e.g. 'ENT-001'
  final String purpose; // e.g. 'Consultation', 'Follow-up'
  final String status; // waiting, serving, completed, skipped, on_hold
  final String? assignedRoom;
  final String? assignedDoctor;
  final String dateKey; // 'YYYY-MM-DD' for daily reset
  final DateTime createdAt;
  final DateTime? calledAt;
  final DateTime? completedAt;
  final VitalSigns? vitalSigns;
  final String? assistedBy;
  final String source; // 'walkin' or 'scheduled'

  QueueEntry({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientPhoto,
    required this.department,
    required this.queueNumber,
    required this.purpose,
    this.status = 'waiting',
    this.assignedRoom,
    this.assignedDoctor,
    required this.dateKey,
    DateTime? createdAt,
    this.calledAt,
    this.completedAt,
    this.vitalSigns,
    this.assistedBy,
    this.source = 'walkin',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'patient_name': patientName,
        'patient_photo': patientPhoto,
        'department': department,
        'queue_number': queueNumber,
        'purpose': purpose,
        'status': status,
        'assigned_room': assignedRoom,
        'assigned_doctor': assignedDoctor,
        'date_key': dateKey,
        'created_at': createdAt.toIso8601String(),
        'called_at': calledAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        if (vitalSigns != null) 'vital_signs': vitalSigns!.toJson(),
        if (assistedBy != null) 'assisted_by': assistedBy,
        'source': source,
      };

  factory QueueEntry.fromJson(Map<String, dynamic> json) => QueueEntry(
        id: json['id']?.toString() ?? '',
        patientId: json['patient_id']?.toString() ?? '',
        patientName: json['patient_name']?.toString() ?? 'Unknown',
        patientPhoto: json['patient_photo']?.toString(),
        department: json['department']?.toString() ?? 'ENT',
        queueNumber: json['queue_number']?.toString() ?? '',
        purpose: json['purpose']?.toString() ?? 'Consultation',
        status: json['status']?.toString() ?? 'waiting',
        assignedRoom: json['assigned_room']?.toString(),
        assignedDoctor: json['assigned_doctor']?.toString(),
        dateKey: json['date_key']?.toString() ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        calledAt: json['called_at'] != null
            ? DateTime.tryParse(json['called_at'].toString())
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'].toString())
            : null,
        vitalSigns: json['vital_signs'] != null && json['vital_signs'] is Map<String, dynamic>
            ? VitalSigns.fromJson(json['vital_signs'] as Map<String, dynamic>)
            : (json['temperature'] != null || json['blood_pressure'] != null || json['bp'] != null)
                ? VitalSigns.fromJson(json)
                : null,
        assistedBy: json['assisted_by']?.toString() ?? json['nurse_name']?.toString(),
        source: json['source']?.toString() ?? 'walkin',
      );

  QueueEntry copyWith({
    String? status,
    String? assignedRoom,
    String? assignedDoctor,
    DateTime? calledAt,
    DateTime? completedAt,
    VitalSigns? vitalSigns,
    String? assistedBy,
    String? source,
  }) {
    return QueueEntry(
      id: id,
      patientId: patientId,
      patientName: patientName,
      patientPhoto: patientPhoto,
      department: department,
      queueNumber: queueNumber,
      purpose: purpose,
      status: status ?? this.status,
      assignedRoom: assignedRoom ?? this.assignedRoom,
      assignedDoctor: assignedDoctor ?? this.assignedDoctor,
      dateKey: dateKey,
      createdAt: createdAt,
      calledAt: calledAt ?? this.calledAt,
      completedAt: completedAt ?? this.completedAt,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      assistedBy: assistedBy ?? this.assistedBy,
      source: source ?? this.source,
    );
  }

  bool get isWaiting => status == 'waiting';
  bool get isServing => status == 'serving';
  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';
  bool get isOnHold => status == 'on_hold';
}
