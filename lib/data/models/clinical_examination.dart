import 'dart:convert';
import 'annotation.dart';

/// Clinical Examination & Medical Drawing model (Nurse Station)
class ClinicalExamination {
  final String id;
  final String examinationUuid;
  final String patientId;
  final String? queueEntryId;
  final String department;
  final String examType;
  final String viewName;
  final List<Annotation> annotations;
  final String? imageUrl;
  final String? clinicalFindings;
  final String? deviceInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClinicalExamination({
    required this.id,
    required this.examinationUuid,
    required this.patientId,
    this.queueEntryId,
    required this.department,
    required this.examType,
    required this.viewName,
    required this.annotations,
    this.imageUrl,
    this.clinicalFindings,
    this.deviceInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Normalized exam type for display
  String get displayExamType {
    final lower = examType.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examination_uuid': examinationUuid,
      'patient_id': patientId,
      if (queueEntryId != null) 'queue_entry_id': queueEntryId,
      'department': department,
      'exam_type': examType.toUpperCase(),
      'view_name': viewName,
      'annotations': annotations.map((a) => a.toJson()).toList(),
      if (imageUrl != null) 'image_url': imageUrl,
      if (clinicalFindings != null) 'clinical_findings': clinicalFindings,
      if (deviceInfo != null) 'device_info': deviceInfo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ClinicalExamination.fromJson(Map<String, dynamic> json) {
    List<Annotation> parsedAnnotations = [];
    final rawAnnotations = json['annotations'];
    if (rawAnnotations != null) {
      try {
        dynamic decoded = rawAnnotations;
        if (decoded is String && decoded.isNotEmpty) {
          decoded = jsonDecode(decoded);
        }
        if (decoded is List) {
          parsedAnnotations = decoded
              .map((item) {
                try {
                  return Annotation.fromJson(Map<String, dynamic>.from(item));
                } catch (_) {
                  return null;
                }
              })
              .whereType<Annotation>()
              .toList();
        }
      } catch (_) {}
    }

    return ClinicalExamination(
      id: json['id']?.toString() ?? '',
      examinationUuid: json['examination_uuid']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      queueEntryId: json['queue_entry_id']?.toString(),
      department: json['department']?.toString() ?? 'ENT',
      examType: json['exam_type']?.toString() ?? 'EYES',
      viewName: json['view_name']?.toString() ?? '1',
      annotations: parsedAnnotations,
      imageUrl: json['image_url']?.toString(),
      clinicalFindings: json['clinical_findings']?.toString(),
      deviceInfo: json['device_info']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ClinicalExamination copyWith({
    String? id,
    String? examinationUuid,
    String? patientId,
    String? queueEntryId,
    String? department,
    String? examType,
    String? viewName,
    List<Annotation>? annotations,
    String? imageUrl,
    String? clinicalFindings,
    String? deviceInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicalExamination(
      id: id ?? this.id,
      examinationUuid: examinationUuid ?? this.examinationUuid,
      patientId: patientId ?? this.patientId,
      queueEntryId: queueEntryId ?? this.queueEntryId,
      department: department ?? this.department,
      examType: examType ?? this.examType,
      viewName: viewName ?? this.viewName,
      annotations: annotations ?? this.annotations,
      imageUrl: imageUrl ?? this.imageUrl,
      clinicalFindings: clinicalFindings ?? this.clinicalFindings,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
