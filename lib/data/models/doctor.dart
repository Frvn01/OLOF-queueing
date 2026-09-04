/// Doctor model for clinic staff assignment
class Doctor {
  final String id;
  final String name; // e.g. 'Dr. Engr. Ranulfo Ramos'
  final String department; // 'ENT', 'EYES', or 'BOTH'
  final String? room; // optional default room e.g. 'Room 1'
  final bool isActive;
  final DateTime createdAt;

  Doctor({
    required this.id,
    required this.name,
    required this.department,
    this.room,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'department': department,
        'room': room,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
        id: json['id'] as String,
        name: json['name'] as String,
        department: json['department'] as String? ?? 'ENT',
        room: json['room'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Doctor copyWith({
    String? id,
    String? name,
    String? department,
    String? room,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      room: room ?? this.room,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
