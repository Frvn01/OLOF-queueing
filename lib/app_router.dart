import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'views/landing/landing_screen.dart';
import 'views/receptionist/receptionist_screen.dart';
import 'views/receptionist/register_screen.dart';
import 'views/receptionist/checkin_screen.dart';
import 'views/receptionist/patient_profile_screen.dart';
import 'views/secretary/secretary_screen.dart';
import 'views/display/display_screen.dart';

/// App router configuration
/// - Web: Strictly Client TV Display Screen
/// - Mobile / Tablet: Strictly Receptionist & Secretary Staff Kiosks
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
  ],
);
