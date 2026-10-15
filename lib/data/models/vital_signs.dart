/// Structured Vital Signs recorded during Nurse Station or Receptionist intake
class VitalSigns {
  final String? bloodPressure; // e.g. "120/80"
  final double? temperature; // in Celsius, e.g. 36.6
  final int? heartRate; // bpm / PR, e.g. 75
  final int? respiratoryRate; // cpm, e.g. 18
  final int? oxygenSaturation; // SpO2 %, e.g. 98
  final double? weight; // in kg, e.g. 65.5
  final double? height; // in cm, e.g. 165.0
  final String? notes; // Additional intake notes

  // Specialized Eye Vitals & Triage (Ophthalmology)
  final String? visualAcuityOD; // VA Right Eye e.g. "20/20"
  final String? visualAcuityOS; // VA Left Eye e.g. "20/20"
  final String? intraocularPressureOD; // IOP Right Eye in mmHg e.g. "15"
  final String? intraocularPressureOS; // IOP Left Eye in mmHg e.g. "15"
  final String? funduscopyOD; // Funduscopy / Retina OD e.g. "Normal disc, CDR 0.3"
  final String? funduscopyOS; // Funduscopy / Retina OS e.g. "Normal disc, CDR 0.3"
  final String? extraocularMuscleMovement; // EOMM e.g. "Full range intact"

  const VitalSigns({
    this.bloodPressure,
    this.temperature,
    this.heartRate,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.weight,
    this.height,
    this.notes,
    this.visualAcuityOD,
    this.visualAcuityOS,
    this.intraocularPressureOD,
    this.intraocularPressureOS,
    this.funduscopyOD,
    this.funduscopyOS,
    this.extraocularMuscleMovement,
  });

  String? get vaOD => visualAcuityOD;
  String? get vaOS => visualAcuityOS;
  String? get iopOD => intraocularPressureOD;
  String? get iopOS => intraocularPressureOS;
  String? get eomm => extraocularMuscleMovement;

  bool get hasEyeVitals =>
      (visualAcuityOD != null && visualAcuityOD!.isNotEmpty) ||
      (visualAcuityOS != null && visualAcuityOS!.isNotEmpty) ||
      (intraocularPressureOD != null && intraocularPressureOD!.isNotEmpty) ||
      (intraocularPressureOS != null && intraocularPressureOS!.isNotEmpty) ||
      (funduscopyOD != null && funduscopyOD!.isNotEmpty) ||
      (funduscopyOS != null && funduscopyOS!.isNotEmpty) ||
      (extraocularMuscleMovement != null && extraocularMuscleMovement!.isNotEmpty);

  bool get isEmpty =>
      (bloodPressure == null || bloodPressure!.isEmpty) &&
      temperature == null &&
      heartRate == null &&
      respiratoryRate == null &&
      oxygenSaturation == null &&
      weight == null &&
      height == null &&
      (notes == null || notes!.isEmpty) &&
      !hasEyeVitals;

  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toJson() {
    return {
      if (bloodPressure != null) 'blood_pressure': bloodPressure,
      if (temperature != null) 'temperature': temperature,
      if (heartRate != null) 'heart_rate': heartRate,
      if (respiratoryRate != null) 'respiratory_rate': respiratoryRate,
      if (oxygenSaturation != null) 'oxygen_saturation': oxygenSaturation,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (notes != null) 'notes': notes,
      if (visualAcuityOD != null) 'visual_acuity_od': visualAcuityOD,
      if (visualAcuityOS != null) 'visual_acuity_os': visualAcuityOS,
      if (intraocularPressureOD != null) 'iop_od': intraocularPressureOD,
      if (intraocularPressureOS != null) 'iop_os': intraocularPressureOS,
      if (funduscopyOD != null) 'funduscopy_od': funduscopyOD,
      if (funduscopyOS != null) 'funduscopy_os': funduscopyOS,
      if (extraocularMuscleMovement != null) 'eomm': extraocularMuscleMovement,
    };
  }

  factory VitalSigns.fromJson(Map<String, dynamic> json) {
    return VitalSigns(
      bloodPressure: json['blood_pressure']?.toString() ?? json['bp']?.toString(),
      temperature: json['temperature'] != null
          ? double.tryParse(json['temperature'].toString())
          : null,
      heartRate: json['heart_rate'] != null
          ? int.tryParse(json['heart_rate'].toString())
          : (json['hr'] != null ? int.tryParse(json['hr'].toString()) : null),
      respiratoryRate: json['respiratory_rate'] != null
          ? int.tryParse(json['respiratory_rate'].toString())
          : (json['rr'] != null ? int.tryParse(json['rr'].toString()) : null),
      oxygenSaturation: json['oxygen_saturation'] != null
          ? int.tryParse(json['oxygen_saturation'].toString())
          : (json['spo2'] != null ? int.tryParse(json['spo2'].toString()) : null),
      weight: json['weight'] != null
          ? double.tryParse(json['weight'].toString())
          : null,
      height: json['height'] != null
          ? double.tryParse(json['height'].toString())
          : null,
      notes: json['notes']?.toString(),
      visualAcuityOD: json['visual_acuity_od']?.toString() ??
          json['va_od']?.toString() ??
          json['vaOD']?.toString(),
      visualAcuityOS: json['visual_acuity_os']?.toString() ??
          json['va_os']?.toString() ??
          json['vaOS']?.toString(),
      intraocularPressureOD: json['iop_od']?.toString() ??
          json['intraocular_pressure_od']?.toString() ??
          json['iopOD']?.toString(),
      intraocularPressureOS: json['iop_os']?.toString() ??
          json['intraocular_pressure_os']?.toString() ??
          json['iopOS']?.toString(),
      funduscopyOD: json['funduscopy_od']?.toString() ??
          json['fundus_od']?.toString() ??
          json['funduscopyOD']?.toString(),
      funduscopyOS: json['funduscopy_os']?.toString() ??
          json['fundus_os']?.toString() ??
          json['funduscopyOS']?.toString(),
      extraocularMuscleMovement: json['eomm']?.toString() ??
          json['extraocular_muscle_movement']?.toString(),
    );
  }

  String get summary {
    final parts = <String>[];
    if (bloodPressure != null && bloodPressure!.isNotEmpty) parts.add('BP: $bloodPressure');
    if (temperature != null) parts.add('Temp: $temperature°C');
    if (heartRate != null) parts.add('PR: $heartRate bpm');
    if (oxygenSaturation != null) parts.add('O₂SAT: $oxygenSaturation%');
    if (weight != null) parts.add('Wt: ${weight}kg');
    if (height != null) parts.add('Ht: ${height}cm');
    if ((visualAcuityOD != null && visualAcuityOD!.isNotEmpty) ||
        (visualAcuityOS != null && visualAcuityOS!.isNotEmpty)) {
      parts.add('VA: OD ${visualAcuityOD ?? "-"} / OS ${visualAcuityOS ?? "-"}');
    }
    if ((intraocularPressureOD != null && intraocularPressureOD!.isNotEmpty) ||
        (intraocularPressureOS != null && intraocularPressureOS!.isNotEmpty)) {
      parts.add('IOP: OD ${intraocularPressureOD ?? "-"} / OS ${intraocularPressureOS ?? "-"} mmHg');
    }
    return parts.join(' | ');
  }
}
