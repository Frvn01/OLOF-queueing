import 'dart:convert';

/// Daily schedule setting for a doctor
class DaySchedule {
  final bool isAvailable;
  final String startTime; // e.g. '09:00'
  final String endTime; // e.g. '17:00'
  final String breakStart; // e.g. '12:00'
  final String breakEnd; // e.g. '13:00'
  final int slotDurationMinutes; // e.g. 30
  final int maxPatientsPerSlot; // e.g. 1
  final String location; // e.g. 'Room 1'
  final String notes;

  DaySchedule({
    this.isAvailable = true,
    this.startTime = '09:00',
    this.endTime = '17:00',
    this.breakStart = '12:00',
    this.breakEnd = '13:00',
    this.slotDurationMinutes = 30,
    this.maxPatientsPerSlot = 1,
    this.location = 'ENT ROOM 1',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'is_available': isAvailable,
        'start_time': startTime,
        'end_time': endTime,
        'break_start': breakStart,
        'break_end': breakEnd,
        'slot_duration_minutes': slotDurationMinutes,
        'max_patients_per_slot': maxPatientsPerSlot,
        'location': location,
        'notes': notes,
      };

  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
        isAvailable: json['is_available'] as bool? ?? true,
        startTime: json['start_time'] as String? ?? '09:00',
        endTime: json['end_time'] as String? ?? '17:00',
        breakStart: json['break_start'] as String? ?? '12:00',
        breakEnd: json['break_end'] as String? ?? '13:00',
        slotDurationMinutes: json['slot_duration_minutes'] as int? ?? 30,
        maxPatientsPerSlot: json['max_patients_per_slot'] as int? ?? 1,
        location: json['location'] as String? ?? 'ENT ROOM 1',
        notes: json['notes'] as String? ?? '',
      );

  DaySchedule copyWith({
    bool? isAvailable,
    String? startTime,
    String? endTime,
    String? breakStart,
    String? breakEnd,
    int? slotDurationMinutes,
    int? maxPatientsPerSlot,
    String? location,
    String? notes,
  }) {
    return DaySchedule(
      isAvailable: isAvailable ?? this.isAvailable,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakStart: breakStart ?? this.breakStart,
      breakEnd: breakEnd ?? this.breakEnd,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      maxPatientsPerSlot: maxPatientsPerSlot ?? this.maxPatientsPerSlot,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }
}

/// Full weekly schedule for a doctor (Monday - Sunday)
class DoctorSchedule {
  final String doctorId;
  final String doctorName;
  final Map<String, DaySchedule> days;

  DoctorSchedule({
    required this.doctorId,
    required this.doctorName,
    required this.days,
  });

  static const List<String> dayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const Map<String, String> dayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  factory DoctorSchedule.defaultSchedule({
    required String doctorId,
    required String doctorName,
    String room = 'ENT ROOM 1',
  }) {
    final map = <String, DaySchedule>{};
    for (final day in dayKeys) {
      final isWeekend = day == 'saturday' || day == 'sunday';
      map[day] = DaySchedule(
        isAvailable: !isWeekend,
        startTime: '09:00',
        endTime: isWeekend ? '13:00' : '17:00',
        breakStart: isWeekend ? '' : '12:00',
        breakEnd: isWeekend ? '' : '13:00',
        slotDurationMinutes: 30,
        maxPatientsPerSlot: 1,
        location: room,
        notes: isWeekend ? 'Half day clinic' : 'Regular clinic hours',
      );
    }
    return DoctorSchedule(
      doctorId: doctorId,
      doctorName: doctorName,
      days: map,
    );
  }

  Map<String, dynamic> toJson() => {
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'days': days.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory DoctorSchedule.fromJson(Map<String, dynamic> json) {
    final daysMap = <String, DaySchedule>{};
    if (json['days'] is Map) {
      (json['days'] as Map).forEach((k, v) {
        if (v is Map<String, dynamic>) {
          daysMap[k.toString()] = DaySchedule.fromJson(v);
        } else if (v is Map) {
          daysMap[k.toString()] =
              DaySchedule.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }
    return DoctorSchedule(
      doctorId: json['doctor_id'] as String? ?? 'default',
      doctorName: json['doctor_name'] as String? ?? 'Doctor',
      days: daysMap.isNotEmpty
          ? daysMap
          : DoctorSchedule.defaultSchedule(
              doctorId: json['doctor_id'] as String? ?? 'default',
              doctorName: json['doctor_name'] as String? ?? 'Doctor',
            ).days,
    );
  }

  String encode() => jsonEncode(toJson());

  static DoctorSchedule decode(String jsonStr) =>
      DoctorSchedule.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
}
