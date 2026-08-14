import 'package:flutter/foundation.dart';

/// Priority for background image downloads — metadata sync never awaits these.
enum PrefetchPriority { low, normal, high }

/// Decouples listing/service thumbnail downloads from metadata sync.
///
/// Phase 2 stub: records intent only. Phase 3 will enqueue downloads via
/// [KoolanImageCacheManager] respecting network quality and Data Saver mode.
class ImagePrefetchService {
  ImagePrefetchService._();

  static final ImagePrefetchService instance = ImagePrefetchService._();

  /// Schedule card thumbnails for background download. Non-blocking.
  void scheduleCardImages(
    Iterable<String> imageUrls, {
    PrefetchPriority priority = PrefetchPriority.normal,
  }) {
    final urls = imageUrls.where((u) => u.isNotEmpty).toList();
    if (urls.isEmpty) return;
    if (kDebugMode) {
      debugPrint(
        '[ImagePrefetch] scheduled ${urls.length} urls (priority=$priority)',
      );
    }
  }

  /// Cancel all pending prefetch work (e.g. when entering Data Saver mode).
  void cancelAll() {
    if (kDebugMode) debugPrint('[ImagePrefetch] cancelAll');
  }
}
