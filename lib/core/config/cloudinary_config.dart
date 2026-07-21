import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cloudinary credentials loaded from the `.env` file at runtime.
///
/// Required keys in `.env`:
///   CLOUD_NAME       – your Cloudinary cloud name
///   CLOUD_API_KEY    – API key (used to sign uploads)
///   CLOUD_API_SECRET – API secret (used to sign uploads, never sent to client
///                      directly — only used to compute the request signature)
class CloudinaryConfig {
  CloudinaryConfig._();

  static String get cloudName => dotenv.env['CLOUD_NAME'] ?? '';
  static String get apiKey    => dotenv.env['CLOUD_API_KEY'] ?? '';
  static String get apiSecret => dotenv.env['CLOUD_API_SECRET'] ?? '';

  /// Base URL for the Cloudinary upload API (signed uploads).
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  static bool get isConfigured =>
      cloudName.isNotEmpty && apiKey.isNotEmpty && apiSecret.isNotEmpty;
}
