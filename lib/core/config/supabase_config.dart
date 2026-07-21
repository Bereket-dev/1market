import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration loaded from `.env` file at runtime.
class AppSupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  
  static String get publishableKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// OAuth redirect URL registered in Supabase Auth settings.
  static String get redirectUrl =>
      dotenv.env['SUPABASE_REDIRECT_URL'] ?? 'io.supabase.koolan://login-callback/';

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static bool isAvailable() {
    if (!isConfigured) return false;

    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient? clientOrNull() {
    if (!isAvailable()) return null;

    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
