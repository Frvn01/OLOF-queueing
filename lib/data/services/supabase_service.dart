import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';

/// Supabase client initialization and helper
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  /// Check if Supabase is configured
  static bool get isConfigured =>
      AppConstants.supabaseUrl.isNotEmpty &&
      AppConstants.supabaseAnonKey.isNotEmpty;
}
