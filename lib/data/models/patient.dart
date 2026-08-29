/// Patient data model
class Patient {
  final String id;
  final String patientNo;
  final String firstName;
  final String lastName;
  final String? middleName;
  final DateTime birthday;
  final String sex;
  final String civilStatus;
  final String address;
  final String contactNumber;
  final String? occupation;
  final String? referredBy;
  final String? photoUrl;
  final String? chiefComplaint;
  final String? historyOfPresentIllness;
  final String? pastMedicalHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    required this.patientNo,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.birthday,
    required this.sex,
    required this.civilStatus,
    required this.address,
    required this.contactNumber,
    this.occupation,
    this.referredBy,
    this.photoUrl,
    this.chiefComplaint,
    this.historyOfPresentIllness,
    this.pastMedicalHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get fullName => '$lastName, $firstName${middleName != null ? ' $middleName' : ''}';
  String get displayName => '$firstName $lastName';

  int get age {
    final now = DateTime.now();
    int a = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      a--;
    }
    return a;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_no': patientNo,
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'birthday': birthday.toIso8601String(),
        'sex': sex,
        'civil_status': civilStatus,
        'address': address,
        'contact_number': contactNumber,
        'occupation': occupation,
        'referred_by': referredBy,
        'photo_url': photoUrl,
        'chief_complaint': chiefComplaint,
        'history_of_present_illness': historyOfPresentIllness,
        'past_medical_history': pastMedicalHistory,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as String,
        patientNo: json['patient_no'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        middleName: json['middle_name'] as String?,
        birthday: DateTime.parse(json['birthday'] as String),
        sex: json['sex'] as String,
        civilStatus: json['civil_status'] as String,
        address: json['address'] as String,
        contactNumber: json['contact_number'] as String,
        occupation: json['occupation'] as String?,
        referredBy: json['referred_by'] as String?,
        photoUrl: json['photo_url'] as String?,
        chiefComplaint: json['chief_complaint'] as String?,
        historyOfPresentIllness:
            json['history_of_present_illness'] as String?,
        pastMedicalHistory: json['past_medical_history'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Patient copyWith({
    String? firstName,
    String? lastName,
    String? middleName,
    DateTime? birthday,
    String? sex,
    String? civilStatus,
    String? address,
    String? contactNumber,
    String? occupation,
    String? referredBy,
    String? photoUrl,
    String? chiefComplaint,
    String? historyOfPresentIllness,
    String? pastMedicalHistory,
  }) {
    return Patient(
      id: id,
      patientNo: patientNo,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      birthday: birthday ?? this.birthday,
      sex: sex ?? this.sex,
      civilStatus: civilStatus ?? this.civilStatus,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      occupation: occupation ?? this.occupation,
      referredBy: referredBy ?? this.referredBy,
      photoUrl: photoUrl ?? this.photoUrl,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      historyOfPresentIllness:
          historyOfPresentIllness ?? this.historyOfPresentIllness,
      pastMedicalHistory: pastMedicalHistory ?? this.pastMedicalHistory,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
