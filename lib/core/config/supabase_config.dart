/// Supabase configuration loaded from `--dart-define` at build time.
class AppSupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String publishableKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// OAuth redirect URL registered in Supabase Auth settings.
  /// Override via `--dart-define=SUPABASE_REDIRECT_URL=...` if needed.
  static const String redirectUrl = String.fromEnvironment(
    'SUPABASE_REDIRECT_URL',
    defaultValue: 'io.supabase.koolan://login-callback/',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static void validate() {
    if (!isConfigured) {
      throw StateError(
        'Missing Supabase configuration. Pass SUPABASE_URL and '
        'SUPABASE_ANON_KEY via --dart-define.',
      );
    }
  }
}
