import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config/cloudinary_config.dart';

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

/// Upload failed with a specific [message].
class CloudinaryUploadFailure extends CloudinaryUploadResult {
  final String message;
  CloudinaryUploadFailure(this.message);
}

/// Service that handles signed Cloudinary image uploads and local caching.
///
/// Cloudinary folder structure:
///   koolan/avatars/[userId]
///   koolan/banners/[userId]
///
/// The picked file is also copied to the app documents directory so it renders
/// offline without a network request:
///   [appDocDir]/profile_images/avatars/[userId].jpg
///   [appDocDir]/profile_images/banners/[userId].jpg
class CloudinaryUploadService {
  CloudinaryUploadService._();
  static final CloudinaryUploadService instance = CloudinaryUploadService._();

  // ── Folder helpers ──────────────────────────────────────────────────────────

  static String _cloudFolder(CloudinaryImageType type) {
    return switch (type) {
      CloudinaryImageType.avatar  => 'koolan/avatars',
      CloudinaryImageType.banner  => 'koolan/banners',
      CloudinaryImageType.listing => 'koolan/listings',
    };
  }

  /// Cloudinary public_id, e.g. "koolan/avatars/abc123".
  static String _publicId(CloudinaryImageType type, String userId) =>
      '${_cloudFolder(type)}/$userId';

  /// Cloudinary public_id for a specific listing image slot.
  /// e.g. "koolan/listings/userId/listingId_0"
  static String _listingPublicId(String userId, String listingId, int index) =>
      'koolan/listings/$userId/${listingId}_$index';

  // ── Local cache path ────────────────────────────────────────────────────────

  /// Returns the path where [userId]'s image of [type] is cached locally.
  static Future<String> localCachePath(
      CloudinaryImageType type, String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    final sub = switch (type) {
      CloudinaryImageType.avatar  => 'avatars',
      CloudinaryImageType.banner  => 'banners',
      CloudinaryImageType.listing => 'listings',
    };
    final folder = Directory(p.join(dir.path, 'profile_images', sub));
    if (!folder.existsSync()) folder.createSync(recursive: true);
    return p.join(folder.path, '$userId.jpg');
  }

  // ── Listing image upload ─────────────────────────────────────────────────────

  /// Uploads a single listing image at [index] for [listingId] / [userId].
  /// Returns the [CloudinaryUploadResult].
  Future<CloudinaryUploadResult> uploadListingImage({
    required File imageFile,
    required String userId,
    required String listingId,
    required int index,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      return CloudinaryUploadFailure(
          'Cloudinary not configured — check CLOUD_NAME, CLOUD_API_KEY, '
          'CLOUD_API_SECRET in .env');
    }

    final publicId = _listingPublicId(userId, listingId, index);
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    final paramsToSign = {
      'public_id': publicId,
      'timestamp': timestamp,
    };
    final sortedString = (paramsToSign.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final stringToSign = '$sortedString${CloudinaryConfig.apiSecret}';
    final signature =
        sha1.convert(utf8.encode(stringToSign)).toString();

    final ext = p.extension(imageFile.path).toLowerCase();
    final contentType = switch (ext) {
      '.png'  => 'image/png',
      '.webp' => 'image/webp',
      '.gif'  => 'image/gif',
      _       => 'image/jpeg',
    };

    final uri = Uri.parse(CloudinaryConfig.uploadUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = CloudinaryConfig.apiKey
      ..fields['timestamp'] = timestamp
      ..fields['public_id'] = publicId
      ..fields['signature'] = signature;

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: http.MediaType.parse(contentType),
    ));

    try {
      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        Map<String, dynamic> json = {};
        try {
          json = jsonDecode(body) as Map<String, dynamic>;
        } catch (_) {}
        final errMsg =
            (json['error'] as Map?)?['message'] as String? ?? body;
        return CloudinaryUploadFailure('Upload failed: $errMsg');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;
      if (secureUrl == null) {
        return CloudinaryUploadFailure(
            'Upload succeeded but response contained no secure_url');
      }

      debugPrint('[Cloudinary] listing image ✅ $secureUrl');
      return CloudinaryUploadSuccess(
        secureUrl: secureUrl,
        localCachePath: imageFile.path,
      );
    } on SocketException catch (e) {
      return CloudinaryUploadFailure('network:${e.message}');
    } catch (e) {
      return CloudinaryUploadFailure(e.toString());
    }
  }

  // ── Raw / PDF file upload ────────────────────────────────────────────────────

  /// Uploads a PDF or other raw file to Cloudinary using `resource_type: raw`.
  ///
  /// Folder: `koolan/cvs/[userId]/[serviceId]/[fileName]`
  ///
  /// Returns a [CloudinaryUploadResult]. The delivery URL is a standard CDN
  /// HTTPS URL — publicly accessible by URL, not guessable without the path.
  /// If you need private delivery, generate signed URLs server-side.
  Future<CloudinaryUploadResult> uploadRawFile({
    required File file,
    required String userId,
    required String serviceId,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      return CloudinaryUploadFailure(
          'Cloudinary not configured — check CLOUD_NAME, CLOUD_API_KEY, '
          'CLOUD_API_SECRET in .env');
    }

    final fileName = p.basename(file.path);
    final publicId = 'koolan/cvs/$userId/$serviceId/$fileName';
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    // Sign using the same sorted-params + secret SHA-1 scheme.
    final paramsToSign = {
      'public_id': publicId,
      'timestamp': timestamp,
    };
    final sortedString = (paramsToSign.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final signature =
        sha1.convert(utf8.encode('$sortedString${CloudinaryConfig.apiSecret}'))
            .toString();

    final uri = Uri.parse(CloudinaryConfig.rawUploadUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = CloudinaryConfig.apiKey
      ..fields['timestamp'] = timestamp
      ..fields['public_id'] = publicId
      ..fields['signature'] = signature;

    // Use application/octet-stream for all raw files (PDF, DOC, etc.)
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: http.MediaType('application', 'octet-stream'),
    ));

    try {
      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        Map<String, dynamic> json = {};
        try { json = jsonDecode(body) as Map<String, dynamic>; } catch (_) {}
        final errMsg =
            (json['error'] as Map?)?['message'] as String? ?? body;
        return CloudinaryUploadFailure('CV upload failed: $errMsg');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;
      if (secureUrl == null) {
        return CloudinaryUploadFailure(
            'CV upload succeeded but response contained no secure_url');
      }

      debugPrint('[Cloudinary] CV raw ✅ $secureUrl');
      return CloudinaryUploadSuccess(
        secureUrl: secureUrl,
        localCachePath: file.path,
      );
    } on SocketException catch (e) {
      return CloudinaryUploadFailure('network:${e.message}');
    } catch (e) {
      return CloudinaryUploadFailure(e.toString());
    }
  }

  // ── Upload ──────────────────────────────────────────────────────────────────

  /// Uploads [imageFile] to Cloudinary, caches it locally, and returns a
  /// [CloudinaryUploadResult].
  ///
  /// Uses a **signed upload** (HMAC-SHA256 of sorted params + API secret).
  /// No upload preset is required — the signature authenticates the request.
  Future<CloudinaryUploadResult> upload({
    required File imageFile,
    required CloudinaryImageType type,
    required String userId,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      return CloudinaryUploadFailure(
          'Cloudinary not configured — check CLOUD_NAME, CLOUD_API_KEY, '
          'CLOUD_API_SECRET in .env');
    }

    final publicId = _publicId(type, userId);
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    // Build the signature string: sorted params joined by & then appended
    // with the API secret (no separator), then SHA-1 hashed.
    final paramsToSign = {
      'public_id': publicId,
      'timestamp': timestamp,
    };
    final sortedString = (paramsToSign.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final stringToSign = '$sortedString${CloudinaryConfig.apiSecret}';
    final signature =
        sha1.convert(utf8.encode(stringToSign)).toString();

    // Determine content-type from file extension.
    final ext = p.extension(imageFile.path).toLowerCase();
    final contentType = switch (ext) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };

    // Build the multipart POST.
    final uri = Uri.parse(CloudinaryConfig.uploadUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = CloudinaryConfig.apiKey
      ..fields['timestamp'] = timestamp
      ..fields['public_id'] = publicId
      ..fields['signature'] = signature;

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: http.MediaType.parse(contentType),
    ));

    try {
      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        Map<String, dynamic> json = {};
        try {
          json = jsonDecode(body) as Map<String, dynamic>;
        } catch (_) {}
        final errMsg =
            (json['error'] as Map?)?['message'] as String? ?? body;
        debugPrint(
            '[Cloudinary] HTTP ${streamed.statusCode}: $errMsg');
        return CloudinaryUploadFailure('Upload failed: $errMsg');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;
      if (secureUrl == null) {
        return CloudinaryUploadFailure(
            'Upload succeeded but response contained no secure_url');
      }

      // Copy the picked file to local cache for offline display.
      final cachePath = await localCachePath(type, userId);
      await imageFile.copy(cachePath);
      debugPrint('[Cloudinary] ✅ $secureUrl  cached → $cachePath');

      return CloudinaryUploadSuccess(
        secureUrl: secureUrl,
        localCachePath: cachePath,
      );
    } on SocketException catch (e) {
      // Network error — caller should queue for retry.
      debugPrint('[Cloudinary] network error: $e');
      return CloudinaryUploadFailure('network:${e.message}');
    } catch (e) {
      debugPrint('[Cloudinary] unexpected error: $e');
      return CloudinaryUploadFailure(e.toString());
    }
  }
}
