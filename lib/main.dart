import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/services/supabase_service.dart';
import 'providers/clinic_provider.dart';
import 'providers/nurse_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/queue_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/admin_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if configured, otherwise fallback gracefully to local mode
  if (SupabaseService.isConfigured) {
    try {
      await SupabaseService.initialize();
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization error, running in local fallback: $e');
    }
  } else {
    debugPrint('Supabase credentials not set, running in local in-memory/cache mode');
  }

  runApp(const OlofQueueingApp());
}

class OlofQueueingApp extends StatelessWidget {
  const OlofQueueingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => QueueProvider()),
        ChangeNotifierProvider(create: (_) => ClinicProvider()),
        ChangeNotifierProvider(create: (_) => NurseProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProv.themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
