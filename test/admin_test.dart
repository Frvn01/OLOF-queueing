import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:olof_queueing/providers/theme_provider.dart';
import 'package:olof_queueing/providers/queue_provider.dart';
import 'package:olof_queueing/providers/patient_provider.dart';
import 'package:olof_queueing/providers/clinic_provider.dart';
import 'package:olof_queueing/providers/nurse_provider.dart';
import 'package:olof_queueing/providers/doctor_provider.dart';
import 'package:olof_queueing/providers/admin_provider.dart';
import 'package:olof_queueing/app_router.dart';

void main() {
  testWidgets('Find overflowing RenderFlex in admin', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      print('=== CAUGHT ERROR ===');
      print(details.toString());
      print('=== END ERROR ===');
    };

    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => PatientProvider()),
          ChangeNotifierProvider(create: (_) => QueueProvider()),
          ChangeNotifierProvider(create: (_) => ClinicProvider()),
          ChangeNotifierProvider(create: (_) => NurseProvider()),
          ChangeNotifierProvider(create: (_) => DoctorProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: createAppRouter(initialLocation: '/admin'),
        ),
      ),
    );
    await tester.pump();
  });
}
