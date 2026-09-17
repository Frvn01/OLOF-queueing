import 'vital_signs.dart';

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
  final bool isFirstTime;
  final String? assignedDoctor;
  final String? assignedRoom;
  final VitalSigns? vitalSigns;
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
    this.isFirstTime = true,
    this.assignedDoctor,
    this.assignedRoom,
    this.vitalSigns,
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
        'is_first_time': isFirstTime,
        'assigned_doctor': assignedDoctor,
        'assigned_room': assignedRoom,
        if (vitalSigns != null) 'vital_signs': vitalSigns!.toJson(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id']?.toString() ?? '',
        patientNo: json['patient_no']?.toString() ?? '',
        firstName: json['first_name']?.toString() ?? '',
        lastName: json['last_name']?.toString() ?? '',
        middleName: json['middle_name']?.toString(),
        birthday: json['birthday'] != null
            ? (DateTime.tryParse(json['birthday'].toString()) ??
                DateTime(2000, 1, 1))
            : DateTime(2000, 1, 1),
        sex: json['sex']?.toString() ?? 'Other',
        civilStatus: json['civil_status']?.toString() ?? 'Single',
        address: json['address']?.toString() ?? '',
        contactNumber: json['contact_number']?.toString() ?? '',
        occupation: json['occupation']?.toString(),
        referredBy: json['referred_by']?.toString(),
        photoUrl: json['photo_url']?.toString(),
        chiefComplaint: json['chief_complaint']?.toString(),
        historyOfPresentIllness:
            json['history_of_present_illness']?.toString(),
        pastMedicalHistory: json['past_medical_history']?.toString(),
        isFirstTime: json['is_first_time'] == true ||
            json['is_first_time'] == null ||
            json['is_first_time'].toString() == 'true',
        assignedDoctor: json['assigned_doctor']?.toString(),
        assignedRoom: json['assigned_room']?.toString(),
        vitalSigns: json['vital_signs'] != null && json['vital_signs'] is Map<String, dynamic>
            ? VitalSigns.fromJson(json['vital_signs'] as Map<String, dynamic>)
            : (json['temperature'] != null || json['blood_pressure'] != null || json['bp'] != null)
                ? VitalSigns.fromJson(json)
                : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
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
    bool? isFirstTime,
    String? assignedDoctor,
    String? assignedRoom,
    VitalSigns? vitalSigns,
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
      isFirstTime: isFirstTime ?? this.isFirstTime,
      assignedDoctor: assignedDoctor ?? this.assignedDoctor,
      assignedRoom: assignedRoom ?? this.assignedRoom,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
