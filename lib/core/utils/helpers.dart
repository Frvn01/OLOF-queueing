import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

/// Utility helpers for ID generation, date formatting, age calculation
class IdGenerator {
  static const _uuid = Uuid();

  /// Generate a unique patient ID: OLOF-YYYY-XXXX
  static String generatePatientId() {
    final year = DateTime.now().year;
    final short = _uuid.v4().substring(0, 4).toUpperCase();
    return 'OLOF-$year-$short';
  }

  /// Generate a UUID v4
  static String generateUuid() => _uuid.v4();
}

class DateHelper {
  /// Calculate age from birthday
  static int calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  /// Format date for display
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date + time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy – hh:mm a').format(date);
  }

  /// Format time only
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// Get today as string key for queue reset
  static String todayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}

class QueueNumberGenerator {
  /// Generate queue number: ENT-001, EYE-001, etc.
  static String generate(String department, int sequence) {
    final prefix = department == 'ENT' ? 'ENT' : 'EYE';
    return '$prefix-${sequence.toString().padLeft(3, '0')}';
  }
}
