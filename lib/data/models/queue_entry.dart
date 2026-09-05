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
      };

  factory QueueEntry.fromJson(Map<String, dynamic> json) => QueueEntry(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        patientName: json['patient_name'] as String,
        patientPhoto: json['patient_photo'] as String?,
        department: json['department'] as String,
        queueNumber: json['queue_number'] as String,
        purpose: json['purpose'] as String,
        status: json['status'] as String? ?? 'waiting',
        assignedRoom: json['assigned_room'] as String?,
        assignedDoctor: json['assigned_doctor'] as String?,
        dateKey: json['date_key'] as String,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        calledAt: json['called_at'] != null
            ? DateTime.parse(json['called_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );

  QueueEntry copyWith({
    String? status,
    String? assignedRoom,
    String? assignedDoctor,
    DateTime? calledAt,
    DateTime? completedAt,
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
    );
  }

  bool get isWaiting => status == 'waiting';
  bool get isServing => status == 'serving';
  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';
  bool get isOnHold => status == 'on_hold';
}
