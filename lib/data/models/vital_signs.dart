/// Structured Vital Signs recorded during Nurse Station or Receptionist intake
class VitalSigns {
  final String? bloodPressure; // e.g. "120/80"
  final double? temperature; // in Celsius, e.g. 36.6
  final int? heartRate; // bpm, e.g. 75
  final int? respiratoryRate; // cpm, e.g. 18
  final int? oxygenSaturation; // SpO2 %, e.g. 98
  final double? weight; // in kg, e.g. 65.5
  final String? notes; // Additional intake notes

  const VitalSigns({
    this.bloodPressure,
    this.temperature,
    this.heartRate,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.weight,
    this.notes,
  });

  bool get isEmpty =>
      (bloodPressure == null || bloodPressure!.isEmpty) &&
      temperature == null &&
      heartRate == null &&
      respiratoryRate == null &&
      oxygenSaturation == null &&
      weight == null &&
      (notes == null || notes!.isEmpty);

  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toJson() {
    return {
      if (bloodPressure != null) 'blood_pressure': bloodPressure,
      if (temperature != null) 'temperature': temperature,
      if (heartRate != null) 'heart_rate': heartRate,
      if (respiratoryRate != null) 'respiratory_rate': respiratoryRate,
      if (oxygenSaturation != null) 'oxygen_saturation': oxygenSaturation,
      if (weight != null) 'weight': weight,
      if (notes != null) 'notes': notes,
    };
  }

  factory VitalSigns.fromJson(Map<String, dynamic> json) {
    return VitalSigns(
      bloodPressure: json['blood_pressure']?.toString(),
      temperature: json['temperature'] != null
          ? double.tryParse(json['temperature'].toString())
          : null,
      heartRate: json['heart_rate'] != null
          ? int.tryParse(json['heart_rate'].toString())
          : null,
      respiratoryRate: json['respiratory_rate'] != null
          ? int.tryParse(json['respiratory_rate'].toString())
          : null,
      oxygenSaturation: json['oxygen_saturation'] != null
          ? int.tryParse(json['oxygen_saturation'].toString())
          : null,
      weight: json['weight'] != null
          ? double.tryParse(json['weight'].toString())
          : null,
      notes: json['notes']?.toString(),
    );
  }

  String get summary {
    final parts = <String>[];
    if (bloodPressure != null && bloodPressure!.isNotEmpty) parts.add('BP: $bloodPressure');
    if (temperature != null) parts.add('Temp: $temperature°C');
    if (heartRate != null) parts.add('HR: $heartRate bpm');
    if (oxygenSaturation != null) parts.add('SpO2: $oxygenSaturation%');
    if (weight != null) parts.add('Wt: ${weight}kg');
    return parts.join(' | ');
  }
}
