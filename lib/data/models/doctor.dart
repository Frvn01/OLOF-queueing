/// Doctor model for clinic staff assignment
class Doctor {
  final String id;
  final String name; // e.g. 'Dr. Engr. Ranulfo Ramos'
  final String department; // 'ENT', 'EYES', or 'BOTH'
  final String? room; // optional default room e.g. 'Room 1'
  final String? photoUrl;
  final String? email;
  final String? phone;
  final String? licenseNumber;
  final int? yearsOfExperience;
  final String? bio;
  final bool isActive;
  final DateTime createdAt;

  Doctor({
    required this.id,
    required this.name,
    required this.department,
    this.room,
    this.photoUrl,
    this.email,
    this.phone,
    this.licenseNumber,
    this.yearsOfExperience,
    this.bio,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'department': department,
        'room': room,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (licenseNumber != null) 'license_number': licenseNumber,
        if (yearsOfExperience != null) 'years_experience': yearsOfExperience,
        if (bio != null) 'bio': bio,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
        id: json['id'] as String,
        name: json['name'] as String,
        department: json['department'] as String? ?? 'ENT',
        room: json['room'] as String?,
        photoUrl: json['photo_url'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        licenseNumber: json['license_number'] as String?,
        yearsOfExperience: json['years_experience'] != null
            ? int.tryParse(json['years_experience'].toString())
            : null,
        bio: json['bio'] as String?,
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
    String? photoUrl,
    String? email,
    String? phone,
    String? licenseNumber,
    int? yearsOfExperience,
    String? bio,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      room: room ?? this.room,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      bio: bio ?? this.bio,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
