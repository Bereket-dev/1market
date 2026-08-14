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
    if (!kDebugMode) return '';
    try {
      return dotenv.env[dotenvKey] ?? '';
    } catch (_) {
      return '';
    }
  }

  static String get cloudName => _env(_defineCloudName, 'CLOUD_NAME');

  /// Local-only fallback — empty in release unless mistakenly passed via define.
  static String get apiKey => _env(_defineApiKey, 'CLOUD_API_KEY');

  /// Local-only fallback — must not be present in release APKs.
  static String get apiSecret => _env(_defineApiSecret, 'CLOUD_API_SECRET');

  /// Base URL for the Cloudinary upload API (signed uploads, images).
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Base URL for raw/PDF file uploads (resource_type = raw).
  static String get rawUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload';

  /// Client only needs the public cloud name; signing is server-side.
  static bool get isConfigured => cloudName.isNotEmpty;

  /// True when a local secret is available (debug / legacy fallback).
  static bool get hasLocalSigningCredentials =>
      apiKey.isNotEmpty && apiSecret.isNotEmpty;
}
