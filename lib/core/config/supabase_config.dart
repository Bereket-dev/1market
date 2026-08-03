import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration.
///
/// Reads values from `--dart-define` compile-time variables first.
/// Falls back to `.env` file (dotenv) so local debug runs without extra flags,
/// but the `.env` file is NOT bundled as a Flutter asset in release builds.
///
/// CI / Play Store builds must pass:
///   --dart-define=SUPABASE_URL=...
///   --dart-define=SUPABASE_ANON_KEY=...
class AppSupabaseConfig {
  // ── Compile-time constants (injected via --dart-define) ───────────────────
  static const String _defineUrl =
      String.fromEnvironment('SUPABASE_URL');
  static const String _defineAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _defineRedirectUrl =
      String.fromEnvironment('SUPABASE_REDIRECT_URL');
  static const String _defineEmailRedirectUrl =
      String.fromEnvironment('SUPABASE_EMAIL_REDIRECT_URL');
  static const String _defineGoogleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const String _defineGoogleAndroidClientId =
      String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID');
  static const String _defineGoogleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the dart-define value if non-empty, otherwise falls back to
  /// dotenv (debug only). On release builds the .env is not bundled, so
  /// dotenv will simply return null/empty — that's intentional.
  static String _env(String define, String dotenvKey) {
    if (define.isNotEmpty) return define;
    // dotenv is only loaded in debug runs; safe to call regardless.
    try {
      return dotenv.env[dotenvKey] ?? '';
    } catch (_) {
      return '';
    }
  }

  // ── Public accessors ──────────────────────────────────────────────────────

  static String get url => _env(_defineUrl, 'SUPABASE_URL');

  static String get publishableKey => _env(_defineAnonKey, 'SUPABASE_ANON_KEY');

  static String get redirectUrl {
    final v = _env(_defineRedirectUrl, 'SUPABASE_REDIRECT_URL');
    if (v.isNotEmpty) return v;
    // Try the legacy dotenv key too.
    try {
      return dotenv.env['SUPABASE_GOOGLE_CALLBACK'] ?? 'io.supabase.koolan://login-callback/';
    } catch (_) {
      return 'io.supabase.koolan://login-callback/';
    }
  }

  static String get emailRedirectUrl {
    final v = _env(_defineEmailRedirectUrl, 'SUPABASE_EMAIL_REDIRECT_URL');
    return v.isNotEmpty ? v : redirectUrl;
  }

  static String get googleWebClientId =>
      _env(_defineGoogleWebClientId, 'GOOGLE_WEB_CLIENT_ID');

  static String get googleAndroidClientId =>
      _env(_defineGoogleAndroidClientId, 'GOOGLE_ANDROID_CLIENT_ID');

  static String get googleIosClientId =>
      _env(_defineGoogleIosClientId, 'GOOGLE_IOS_CLIENT_ID');

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

  /// Logs the effective config source in debug builds.
  static void debugLogSource() {
    if (!kDebugMode) return;
    final source = _defineUrl.isNotEmpty ? '--dart-define' : '.env / unset';
    debugPrint('[Config] Supabase URL source: $source');
    debugPrint('[Config] isConfigured: $isConfigured');
  }
}
