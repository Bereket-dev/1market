import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cloudinary **public** config for the client.
///
/// Release builds must only ship [cloudName] (via `--dart-define`).
/// Upload signatures are produced by the `cloudinary-sign` Edge Function so
/// [apiSecret] never ships in the APK.
///
/// Local debug may still supply key/secret via dart-define / dotenv as a
/// fallback when the Edge Function is unavailable.
/// Release builds can use local signing only when the credentials are explicitly
/// passed via `--dart-define` in CI.
class CloudinaryConfig {
  CloudinaryConfig._();

  static const String _defineCloudName =
      String.fromEnvironment('CLOUD_NAME');
  static const String _defineApiKey =
      String.fromEnvironment('CLOUD_API_KEY');
  static const String _defineApiSecret =
      String.fromEnvironment('CLOUD_API_SECRET');

  static String _env(String define, String dotenvKey) {
    // dart-define values work in both debug and release.
    if (define.isNotEmpty) return define;
    // dotenv fallback is debug-only (local .env file).
    if (!kDebugMode) return '';
    try {
      return dotenv.env[dotenvKey] ?? '';
    } catch (_) {
      return '';
    }
  }

  static String get cloudName => _env(_defineCloudName, 'CLOUD_NAME');

  /// Available in release only when explicitly passed via --dart-define in CI.
  static String get apiKey => _env(_defineApiKey, 'CLOUD_API_KEY');

  /// Available in release only when explicitly passed via --dart-define in CI.
  static String get apiSecret => _env(_defineApiSecret, 'CLOUD_API_SECRET');

  /// Base URL for the Cloudinary upload API (signed uploads, images).
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Base URL for raw/PDF file uploads (resource_type = raw).
  static String get rawUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload';

  /// Client only needs the public cloud name; signing is server-side.
  static bool get isConfigured => cloudName.isNotEmpty;

  /// True when a local signing credential pair is available.
  static bool get hasLocalSigningCredentials =>
      apiKey.isNotEmpty && apiSecret.isNotEmpty;
}
