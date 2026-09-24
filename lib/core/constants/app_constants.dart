/// App-wide constants for OLOF Queueing System
class AppConstants {
  AppConstants._();

  // ── APP INFO ──────────────────────────────────────────
  static const String appName = 'OLOF Queueing System';
  static const String clinicName = 'Our Lady of Fatima';
  static const String clinicSubtitle = 'Eye Ear Nose Throat Center';
  static const String clinicAddress =
      'Barangay 82 Baybay Road, Marasbaras, Tacloban City, Philippines';
  static const String clinicPhone = '+639687216039';
  static const String clinicEmail = 'olof.eentcenter@yahoo.com';
  static const String clinicTagline =
      '"Because every SENSE deserves CLARITY"';

  // ── DEPARTMENTS ───────────────────────────────────────
  static const String deptEnt = 'ENT';
  static const String deptEyes = 'EYES';
  static const List<String> departments = [deptEnt, deptEyes];

  // ── DOCTORS (shown on display screen instead of patient name) ─────────────
  static const Map<String, String> departmentDoctors = {
    deptEnt: 'Dr. DR. LORENZO VERA CRUZ',
    deptEyes: 'Dr. DR. IAN J. DAGUMAN',
  };

  // ── ROOMS (matching Supabase clinic_rooms) ──────────────
  static const Map<String, List<String>> rooms = {
    deptEnt: ['ENT ROOM 1', 'ENT ROOM 2'],
    deptEyes: [
      'OPHTHA ROOM 1',
      'OPHTHA ROOM 2',
      'OPHTHA ROOM 3',
      'OPHTHA ROOM 4'
    ],
  };

  // ── QUEUE NUMBER FORMAT ───────────────────────────────
  static const String entPrefix = 'ENT';
  static const String eyesPrefix = 'EYE';

  // ── VISIT PURPOSES ────────────────────────────────────
  static const List<String> visitPurposes = [
    'Consultation',
    'Follow-up',
    'Pre-operative',
    'Post-operative',
    'Lab Results',
    'Fitting / Adjustment',
    'Other',
  ];

  // ── CIVIL STATUS OPTIONS ──────────────────────────────
  static const List<String> civilStatusOptions = [
    'Single',
    'Married',
    'Widowed',
    'Separated',
  ];

  // ── SEX OPTIONS ───────────────────────────────────────
  static const List<String> sexOptions = ['Male', 'Female'];

  // ── PATIENT ID FORMAT ─────────────────────────────────
  static const String patientIdPrefix = 'OLOF';

  // ── QUEUE STATUS ──────────────────────────────────────
  static const String statusWaiting = 'waiting';
  static const String statusServing = 'serving';
  static const String statusCompleted = 'completed';
  static const String statusSkipped = 'skipped';
  static const String statusOnHold = 'on_hold';

  // ── TUTORIAL FLAGS ────────────────────────────────────
  static const String tutorialReceptionist = 'tutorial_receptionist_seen';
  static const String tutorialSecretary = 'tutorial_secretary_seen';

  // ── SUPABASE ──────────────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://llrantgicpbtudktoxwt.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_NCKavfjT82C3fxccYUMNWA_q_wkU85N',
  );
}
