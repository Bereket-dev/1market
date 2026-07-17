import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration loaded from `.env` file at runtime.
class AppSupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';

  static String get publishableKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// OAuth redirect URL registered in Supabase Auth settings.
  static String get redirectUrl =>
      dotenv.env['SUPABASE_REDIRECT_URL'] ??
      dotenv.env['SUPABASE_GOOGLE_CALLBACK'] ??
      'io.supabase.koolan://login-callback/';

  /// Email confirmation / password reset redirect URL.
  ///
  /// For mobile apps, this should normally be a deep link such as:
  ///   io.supabase.koolan://login-callback/
  /// If you want the email confirmation to land on a web page instead,
  /// set this to your web app URL.
  static String get emailRedirectUrl =>
      dotenv.env['SUPABASE_EMAIL_REDIRECT_URL'] ?? redirectUrl;

  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  static String get googleAndroidClientId =>
      dotenv.env['GOOGLE_ANDROID_CLIENT_ID'] ?? '';

  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';

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
