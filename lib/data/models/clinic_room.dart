/// Clinic room model
class ClinicRoom {
  final String id;
  final String name; // e.g. 'Room 1', 'Room 2', 'ENT Examination Room'
  final String department; // 'ENT', 'EYES', or 'BOTH'
  final bool isActive;
  final DateTime createdAt;

  ClinicRoom({
    required this.id,
    required this.name,
    required this.department,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'department': department,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  factory ClinicRoom.fromJson(Map<String, dynamic> json) => ClinicRoom(
        id: json['id'] as String,
        name: json['name'] as String,
        department: json['department'] as String? ?? 'BOTH',
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  ClinicRoom copyWith({
    String? id,
    String? name,
    String? department,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ClinicRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
