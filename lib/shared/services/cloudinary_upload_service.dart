import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/cloudinary_config.dart';
import '../../core/config/supabase_config.dart';
import '../../core/errors/error_reporter.dart';

/// Image type — determines which Cloudinary folder the file lands in.
enum CloudinaryImageType { avatar, banner, listing }

/// Result of a Cloudinary upload attempt.
sealed class CloudinaryUploadResult {}

/// Upload succeeded. [secureUrl] is the `https://` delivery URL returned by
/// Cloudinary. [localCachePath] is where the file was copied locally for
/// offline display.
class CloudinaryUploadSuccess extends CloudinaryUploadResult {
  final String secureUrl;
  final String localCachePath;
  CloudinaryUploadSuccess({
    required this.secureUrl,
    required this.localCachePath,
  });
}

/// Stable failure codes — never leak Cloudinary / network payloads to UI.
enum CloudinaryFailureCode {
  notConfigured,
  network,
  unauthorized,
  uploadFailed,
  unexpected,
}

/// Upload failed with a stable [code] for safe UI mapping.
class CloudinaryUploadFailure extends CloudinaryUploadResult {
  final CloudinaryFailureCode code;

  /// Legacy prefix used by offline queue detection (`network:`).
  String get message => switch (code) {
        CloudinaryFailureCode.network => 'network:unavailable',
        CloudinaryFailureCode.notConfigured => 'not_configured',
        CloudinaryFailureCode.unauthorized => 'unauthorized',
        CloudinaryFailureCode.uploadFailed => 'upload_failed',
        CloudinaryFailureCode.unexpected => 'unexpected',
      };

  CloudinaryUploadFailure(this.code);
}

class _SignedUploadParams {
  const _SignedUploadParams({
    required this.apiKey,
    required this.signature,
    required this.timestamp,
  });

  final String apiKey;
  final String signature;
  final String timestamp;
}

/// Service that handles signed Cloudinary image uploads and local caching.
///
/// Signatures come from the `cloudinary-sign` Edge Function so the API secret
/// never ships in the APK. Debug builds may fall back to local signing when
/// [CloudinaryConfig.hasLocalSigningCredentials] is true.
class CloudinaryUploadService {
  CloudinaryUploadService._();
  static final CloudinaryUploadService instance = CloudinaryUploadService._();

  static String _cloudFolder(CloudinaryImageType type) {
    return switch (type) {
      CloudinaryImageType.avatar => 'koolan/avatars',
      CloudinaryImageType.banner => 'koolan/banners',
      CloudinaryImageType.listing => 'koolan/listings',
    };
  }

  static String _publicId(CloudinaryImageType type, String userId) =>
      '${_cloudFolder(type)}/$userId';

  static String _listingPublicId(String userId, String listingId, int index) =>
      'koolan/listings/$userId/${listingId}_$index';

  static Future<String> localCachePath(
    CloudinaryImageType type,
    String userId,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final sub = switch (type) {
      CloudinaryImageType.avatar => 'avatars',
      CloudinaryImageType.banner => 'banners',
      CloudinaryImageType.listing => 'listings',
    };
    final folder = Directory(p.join(dir.path, 'profile_images', sub));
    if (!folder.existsSync()) folder.createSync(recursive: true);
    return p.join(folder.path, '$userId.jpg');
  }

  /// Obtains a signature from the Edge Function, or local secret in debug.
  Future<_SignedUploadParams?> _sign(
    Map<String, String> paramsToSign,
  ) async {
    final client = AppSupabaseConfig.clientOrNull();
    final session = client?.auth.currentSession;
    if (client != null && session != null) {
      try {
        final response = await client.functions
            .invoke(
              'cloudinary-sign',
              body: {'paramsToSign': paramsToSign},
            )
            .timeout(const Duration(seconds: 15));
        final data = response.data;
        if (data is Map) {
          final signature = data['signature'] as String?;
          final apiKey = data['apiKey'] as String?;
          final timestamp = data['timestamp'] as String? ??
              paramsToSign['timestamp'] ??
              '';
          if (signature != null && apiKey != null && timestamp.isNotEmpty) {
            return _SignedUploadParams(
              apiKey: apiKey,
              signature: signature,
              timestamp: timestamp,
            );
          }
        }
        if (kDebugMode) {
          debugPrint(
            '[Cloudinary] edge sign unexpected response: ${response.data}',
          );
        }
      } on FunctionException catch (e, st) {
        await ErrorReporter.recordError(e, st, reason: 'cloudinary_sign');
        if (e.status == 401) return null;
      } catch (e, st) {
        await ErrorReporter.recordError(e, st, reason: 'cloudinary_sign');
      }
    }

    // Debug / local fallback only — never rely on this in release APKs.
    if (CloudinaryConfig.hasLocalSigningCredentials) {
      final sortedString = (paramsToSign.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key)))
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      final signature = sha1
          .convert(utf8.encode('$sortedString${CloudinaryConfig.apiSecret}'))
          .toString();
      return _SignedUploadParams(
        apiKey: CloudinaryConfig.apiKey,
        signature: signature,
        timestamp: paramsToSign['timestamp'] ?? '',
      );
    }
    return null;
  }

  Future<CloudinaryUploadResult> uploadListingImage({
    required File imageFile,
    required String userId,
    required String listingId,
    required int index,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      return CloudinaryUploadFailure(CloudinaryFailureCode.notConfigured);
    }

    final publicId = _listingPublicId(userId, listingId, index);
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final paramsToSign = {
      'public_id': publicId,
      'timestamp': timestamp,
    };
    final signed = await _sign(paramsToSign);
    if (signed == null) {
      return CloudinaryUploadFailure(CloudinaryFailureCode.unauthorized);
    }

    final ext = p.extension(imageFile.path).toLowerCase();
    final contentType = switch (ext) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };

    final uri = Uri.parse(CloudinaryConfig.uploadUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = signed.apiKey
      ..fields['timestamp'] = signed.timestamp
      ..fields['public_id'] = publicId
      ..fields['signature'] = signed.signature;

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: http.MediaType.parse(contentType),
    ));

    return _sendUpload(request, localCachePath: imageFile.path);
  }

  Future<CloudinaryUploadResult> uploadRawFile({
    required File file,
    required String userId,
    required String serviceId,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      return CloudinaryUploadFailure(CloudinaryFailureCode.notConfigured);
    }

    final ext = p.extension(file.path).toLowerCase();
    final safeExt = switch (ext) {
      '.pdf' => '.pdf',
      '.png' => '.png',
      '.jpeg' || '.jpg' => '.jpg',
      '.webp' => '.webp',
      _ => ext.isNotEmpty ? ext : '.pdf',
    };
    final publicId = 'koolan/cvs/$userId/$serviceId/cv$safeExt';
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    final paramsToSign = {
      'invalidate': 'true',
      'overwrite': 'true',
      'public_id': publicId,
      'timestamp': timestamp,
    };
    final signed = await _sign(paramsToSign);
    if (signed == null) {
      return CloudinaryUploadFailure(CloudinaryFailureCode.unauthorized);
    }

    final contentType = switch (safeExt) {
      '.pdf' => http.MediaType('application', 'pdf'),
      '.png' => http.MediaType('image', 'png'),
      '.webp' => http.MediaType('image', 'webp'),
      '.jpg' => http.MediaType('image', 'jpeg'),
      _ => http.MediaType('application', 'octet-stream'),
    };

    final uri = Uri.parse(CloudinaryConfig.rawUploadUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = signed.apiKey
      ..fields['timestamp'] = signed.timestamp
      ..fields['public_id'] = publicId
      ..fields['overwrite'] = 'true'
      ..fields['invalidate'] = 'true'
      ..fields['signature'] = signed.signature;

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: contentType,
    ));

    return _sendUpload(request, localCachePath: file.path);
  }

  Future<CloudinaryUploadResult> upload({
    required File imageFile,
    required CloudinaryImageType type,
    required String userId,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      return CloudinaryUploadFailure(CloudinaryFailureCode.notConfigured);
    }

    final publicId = _publicId(type, userId);
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final paramsToSign = {
      'public_id': publicId,
      'timestamp': timestamp,
    };
    final signed = await _sign(paramsToSign);
    if (signed == null) {
      return CloudinaryUploadFailure(CloudinaryFailureCode.unauthorized);
    }

    final ext = p.extension(imageFile.path).toLowerCase();
    final contentType = switch (ext) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };

    final uri = Uri.parse(CloudinaryConfig.uploadUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = signed.apiKey
      ..fields['timestamp'] = signed.timestamp
      ..fields['public_id'] = publicId
      ..fields['signature'] = signed.signature;

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: http.MediaType.parse(contentType),
    ));

    final cachePath = await localCachePath(type, userId);
    final result = await _sendUpload(request, localCachePath: cachePath);
    if (result is CloudinaryUploadSuccess) {
      try {
        await imageFile.copy(cachePath);
      } catch (e, st) {
        await ErrorReporter.recordError(e, st, reason: 'cloudinary_cache');
      }
      return CloudinaryUploadSuccess(
        secureUrl: result.secureUrl,
        localCachePath: cachePath,
      );
    }
    return result;
  }

  Future<CloudinaryUploadResult> _sendUpload(
    http.MultipartRequest request, {
    required String localCachePath,
  }) async {
    try {
      final streamed = await request.send().timeout(
            const Duration(seconds: 60),
          );
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        await ErrorReporter.recordError(
          'cloudinary_http_${streamed.statusCode}',
          null,
          reason: 'cloudinary_upload',
        );
        return CloudinaryUploadFailure(CloudinaryFailureCode.uploadFailed);
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;
      if (secureUrl == null) {
        return CloudinaryUploadFailure(CloudinaryFailureCode.uploadFailed);
      }

      if (kDebugMode) debugPrint('[Cloudinary] ✅ $secureUrl');
      return CloudinaryUploadSuccess(
        secureUrl: secureUrl,
        localCachePath: localCachePath,
      );
    } on SocketException catch (e, st) {
      await ErrorReporter.recordError(e, st, reason: 'cloudinary_network');
      return CloudinaryUploadFailure(CloudinaryFailureCode.network);
    } on TimeoutException catch (e, st) {
      await ErrorReporter.recordError(e, st, reason: 'cloudinary_timeout');
      return CloudinaryUploadFailure(CloudinaryFailureCode.network);
    } catch (e, st) {
      await ErrorReporter.recordError(e, st, reason: 'cloudinary_upload');
      return CloudinaryUploadFailure(CloudinaryFailureCode.unexpected);
    }
  }
}
