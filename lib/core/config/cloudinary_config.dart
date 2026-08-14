import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cloudinary credentials.
///
/// Reads `--dart-define` first, then `.env` (same pattern as [AppSupabaseConfig]).
/// Required keys:
///   CLOUD_NAME       – your Cloudinary cloud name
///   CLOUD_API_KEY    – API key (used to sign uploads)
///   CLOUD_API_SECRET – API secret (used to sign uploads, never sent to client
///                      directly — only used to compute the request signature)
class CloudinaryConfig {
  CloudinaryConfig._();

  static const String _defineCloudName =
      String.fromEnvironment('CLOUD_NAME');
  static const String _defineApiKey =
      String.fromEnvironment('CLOUD_API_KEY');
  static const String _defineApiSecret =
      String.fromEnvironment('CLOUD_API_SECRET');

  static String _env(String define, String dotenvKey) {
    if (define.isNotEmpty) return define;
    try {
      return dotenv.env[dotenvKey] ?? '';
    } catch (_) {
      return '';
    }
  }

  static String get cloudName => _env(_defineCloudName, 'CLOUD_NAME');
  static String get apiKey => _env(_defineApiKey, 'CLOUD_API_KEY');
  static String get apiSecret => _env(_defineApiSecret, 'CLOUD_API_SECRET');

  /// Base URL for the Cloudinary upload API (signed uploads, images).
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Base URL for raw/PDF file uploads (resource_type = raw).
  static String get rawUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload';

  static bool get isConfigured =>
      cloudName.isNotEmpty && apiKey.isNotEmpty && apiSecret.isNotEmpty;
}
