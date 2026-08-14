import 'package:flutter/foundation.dart';

import 'network_monitor.dart';

/// Priority for background image downloads — metadata sync never awaits these.
enum PrefetchPriority { low, normal, high }

/// Decouples listing/service thumbnail downloads from metadata sync.
///
/// Phase 3: gates downloads on [NetworkMonitor.quality] and [dataSaverEnabled].
///
/// Rules:
///   - OFFLINE or Data Saver → skip all prefetch.
///   - POOR  → skip prefetch (images load on-demand via CachedNetworkImage).
///   - LIMITED → schedule only high-priority (e.g. first-visible row).
///   - GOOD  → schedule all priorities.
class ImagePrefetchService {
  ImagePrefetchService._();

  static final ImagePrefetchService instance = ImagePrefetchService._();

  bool dataSaverEnabled = false;

  /// Schedule card thumbnails for background download. Non-blocking.
  void scheduleCardImages(
    Iterable<String> imageUrls, {
    PrefetchPriority priority = PrefetchPriority.normal,
  }) {
    if (dataSaverEnabled) {
      if (kDebugMode) {
        debugPrint('[ImagePrefetch] skipped (Data Saver on)');
      }
      return;
    }

    final monitor = NetworkMonitor.instance;

    if (monitor.isOffline) return;

    if (monitor.isPoor) {
      if (kDebugMode) {
        debugPrint('[ImagePrefetch] skipped (POOR network)');
      }
      return;
    }

    if (monitor.isLimited && priority != PrefetchPriority.high) {
      if (kDebugMode) {
        debugPrint(
          '[ImagePrefetch] skipped non-high priority on LIMITED network',
        );
      }
      return;
    }

    final urls = imageUrls.where((u) => u.isNotEmpty).toList();
    if (urls.isEmpty) return;

    // Phase 3 stub: actual warm-up via CachedNetworkImage.downloadFile()
    // will be added when we wire in the cache manager here.
    if (kDebugMode) {
      debugPrint(
        '[ImagePrefetch] scheduled ${urls.length} urls '
        '(priority=$priority, quality=${monitor.quality})',
      );
    }
  }

  /// Cancel all pending prefetch work (e.g. when entering Data Saver mode).
  void cancelAll() {
    if (kDebugMode) debugPrint('[ImagePrefetch] cancelAll');
  }
}
