import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'views/landing/landing_screen.dart';
import 'views/receptionist/receptionist_screen.dart';
import 'views/receptionist/register_screen.dart';
import 'views/receptionist/checkin_screen.dart';
import 'views/receptionist/patient_profile_screen.dart';
import 'views/secretary/secretary_screen.dart';
import 'views/display/display_screen.dart';
import 'views/archive/queue_archive_screen.dart';
import 'views/nurse/nurse_station_screen.dart';
import 'views/nurse/nurse_patient_exams_screen.dart';
import 'views/nurse/nurse_drawing_screen.dart';
import 'views/admin/admin_shell.dart';
import 'views/doctor/doctor_shell.dart';
import 'views/doctor/doctor_patient_detail_screen.dart';
import 'views/doctor/doctor_consultation_screen.dart';
import 'data/models/queue_entry.dart';

/// App router configuration
/// - Web: Strictly Client TV Display Screen
/// - Desktop: TV Display + Unlocked Nurse & Staff Modules
/// - Mobile / Tablet: Receptionist, Ophtha Dept & Nurse Staff Kiosks
final GoRouter appRouter = GoRouter(
  initialLocation: kIsWeb ? '/display' : '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          kIsWeb ? const DisplayScreen() : const LandingScreen(),
    ),
    // Display route (Dedicated for Web / TV projection)
    GoRoute(
      path: '/display',
      builder: (context, state) => const DisplayScreen(),
    ),
    // Staff kiosk routes (Mobile / Tablet only)
    GoRoute(
      path: '/receptionist',
      builder: (context, state) => const ReceptionistScreen(),
    ),
    GoRoute(
      path: '/receptionist/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/receptionist/checkin',
      builder: (context, state) {
        final patientId = state.uri.queryParameters['patientId'];
        final doctor = state.uri.queryParameters['doctor'];
        final room = state.uri.queryParameters['room'];
        final dept = state.uri.queryParameters['dept'];
        return CheckinScreen(
          patientId: patientId,
          initialDoctor: doctor,
          initialRoom: room,
          initialDept: dept,
        );
      },
    ),
    GoRoute(
      path: '/receptionist/patient/:id',
      builder: (context, state) {
        final patientId = state.pathParameters['id']!;
        return PatientProfileScreen(patientId: patientId);
      },
    ),
    GoRoute(
      path: '/secretary',
      builder: (context, state) => const SecretaryScreen(),
    ),
    GoRoute(
      path: '/archive',
      builder: (context, state) => const QueueArchiveScreen(),
    ),
    // Nurse Clinical Station routes
    GoRoute(
      path: '/nurse',
      builder: (context, state) => const NurseStationScreen(),
    ),
    GoRoute(
      path: '/nurse/exams',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final patientId = extra['patientId']?.toString() ??
            state.uri.queryParameters['patientId'] ??
            '';
        final patientName = extra['patientName']?.toString() ??
            state.uri.queryParameters['patientName'] ??
            'Patient';
        final queueNumber = extra['queueNumber']?.toString() ??
            state.uri.queryParameters['queueNumber'];
        final department = extra['department']?.toString() ??
            state.uri.queryParameters['department'];
        final queueEntryId = extra['queueEntryId']?.toString() ??
            state.uri.queryParameters['queueEntryId'];
        final chiefComplaint = extra['chiefComplaint']?.toString();
        final historyOfPresentIllness = extra['historyOfPresentIllness']?.toString();
        final pastMedicalHistory = extra['pastMedicalHistory']?.toString();
        final assignedDoctor = extra['assignedDoctor']?.toString();
        final assignedRoom = extra['assignedRoom']?.toString();

        return NursePatientExamsScreen(
          patientId: patientId,
          patientName: patientName,
          queueNumber: queueNumber,
          department: department,
          queueEntryId: queueEntryId,
          chiefComplaint: chiefComplaint,
          historyOfPresentIllness: historyOfPresentIllness,
          pastMedicalHistory: pastMedicalHistory,
          assignedDoctor: assignedDoctor,
          assignedRoom: assignedRoom,
        );
      },
    ),
    GoRoute(
      path: '/nurse/drawing',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final patientId = extra['patientId']?.toString() ?? '';
        final patientName = extra['patientName']?.toString() ?? 'Patient';
        final examType = extra['examType']?.toString() ?? 'eyes';
        final department = extra['department']?.toString() ?? 'ENT';
        final queueNumber = extra['queueNumber']?.toString();
        final queueEntryId = extra['queueEntryId']?.toString();
        final examinationUuid = extra['examinationUuid']?.toString();
        final savedDiagram = extra['savedDiagram'];
        final viewMode = extra['viewMode'] == true;
        final chiefComplaint = extra['chiefComplaint']?.toString();
        final historyOfPresentIllness = extra['historyOfPresentIllness']?.toString();
        final pastMedicalHistory = extra['pastMedicalHistory']?.toString();

        return NurseDrawingScreen(
          patientId: patientId,
          patientName: patientName,
          examType: examType,
          department: department,
          queueNumber: queueNumber,
          queueEntryId: queueEntryId,
          examinationUuid: examinationUuid,
          savedDiagram: savedDiagram,
          viewMode: viewMode,
          chiefComplaint: chiefComplaint,
          historyOfPresentIllness: historyOfPresentIllness,
          pastMedicalHistory: pastMedicalHistory,
        );
      },
    ),
    // Admin Desktop routes
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminShell(initialTab: 0),
    ),
    GoRoute(
      path: '/admin/queue',
      builder: (context, state) => const AdminShell(initialTab: 1),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const AdminShell(initialTab: 2),
    ),
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => const AdminShell(initialTab: 3),
    ),
    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => const AdminShell(initialTab: 4),
    ),
    // Doctor Mobile / Tablet kiosk routes
    GoRoute(
      path: '/doctor',
      builder: (context, state) => const DoctorShell(initialTab: 0),
    ),
    GoRoute(
      path: '/doctor/patients',
      builder: (context, state) => const DoctorShell(initialTab: 1),
    ),
    GoRoute(
      path: '/doctor/queue',
      builder: (context, state) => const DoctorShell(initialTab: 2),
    ),
    GoRoute(
      path: '/doctor/appointments',
      builder: (context, state) => const DoctorShell(initialTab: 3),
    ),
    GoRoute(
      path: '/doctor/schedule',
      builder: (context, state) => const DoctorShell(initialTab: 4),
    ),
    GoRoute(
      path: '/doctor/reports',
      builder: (context, state) => const DoctorShell(initialTab: 5),
    ),
    GoRoute(
      path: '/doctor/profile',
      builder: (context, state) => const DoctorShell(initialTab: 6),
    ),
    GoRoute(
      path: '/doctor/patients/:id',
      builder: (context, state) {
        final patientId = state.pathParameters['id']!;
        return DoctorPatientDetailScreen(patientId: patientId);
      },
    ),
    GoRoute(
      path: '/doctor/consultation/:id',
      builder: (context, state) {
        final patientId = state.pathParameters['id']!;
        final entry = state.extra as QueueEntry?;
        return DoctorConsultationScreen(patientId: patientId, queueEntry: entry);
      },
    ),
  ],
);
