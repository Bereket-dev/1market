import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Observable sync status model — tracks aggregate metrics across all sync passes.
///
/// Exposed on [OnemarketAppState.syncObservability] and consumed by [SyncDebugOverlay]
/// in debug builds and by [SyncStatusBanner] for the "Updated X min ago" label.
///
/// Named [SyncObservabilityStatus] to avoid collision with the [SyncStatus]
/// enum from [SyncableEntity] which tracks per-entity write states (local /
/// pending / synced / failed).
class SyncObservabilityStatus extends ChangeNotifier {
  DateTime? lastSuccessfulSync;
  DateTime? lastAttempt;
  int pendingOperations = 0;
  int failedOperations = 0;
  int bytesDownloaded = 0;
  int bytesUploaded = 0;
  Duration? lastSyncDuration;

  // ── Mutators called by SyncService / AppState ─────────────────────────────

  void recordSuccess({required Duration duration}) {
    lastSuccessfulSync = DateTime.now();
    lastAttempt = DateTime.now();
    lastSyncDuration = duration;
    notifyListeners();
    reportToCrashlytics();
  }

  void recordAttempt() {
    lastAttempt = DateTime.now();
    notifyListeners();
  }

  void setQueueCounts({
    required int pending,
    required int requiresAttention,
  }) {
    pendingOperations = pending;
    failedOperations = requiresAttention;
    notifyListeners();
  }

  void incrementFailed() {
    failedOperations++;
    notifyListeners();
  }

  void addBytesDownloaded(int bytes) {
    bytesDownloaded += bytes;
    notifyListeners();
  }

  void addBytesUploaded(int bytes) {
    bytesUploaded += bytes;
    notifyListeners();
  }

  void reset() {
    lastSuccessfulSync = null;
    lastAttempt = null;
    pendingOperations = 0;
    failedOperations = 0;
    bytesDownloaded = 0;
    bytesUploaded = 0;
    lastSyncDuration = null;
    notifyListeners();
  }

  // Bandwidth targets from docs/low_bandwidth_offline_sync_plan.md.
  // Used for production sampling / breach flags in Crashlytics.
  static const int targetNormalRefreshBytes = 100 * 1024; // 100 KB
  static const int targetNoChangeDeltaBytes = 10 * 1024; // 10 KB
  static const int targetInitialSyncBytes = 2 * 1024 * 1024; // 2 MB

  /// Reports key sync metrics to Firebase Crashlytics as custom keys so they
  /// appear alongside crash reports in the Firebase console.
  ///
  /// Only runs in release builds — debug and profile builds skip this to
  /// avoid polluting the Crashlytics dashboard during development.
  ///
  /// Also sets breach flags when session download totals exceed the plan
  /// targets (normal refresh / no-change delta / initial sync) so excess
  /// bandwidth is visible next to any crash without a separate analytics
  /// pipeline.
  ///
  /// Wrapped in try/catch so telemetry can never crash the app.
  void reportToCrashlytics() {
    if (kDebugMode || kProfileMode) return;
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      crashlytics.setCustomKey('sync_bytes_downloaded', bytesDownloaded);
      crashlytics.setCustomKey('sync_bytes_uploaded', bytesUploaded);
      crashlytics.setCustomKey(
        'sync_last_duration_ms',
        lastSyncDuration?.inMilliseconds ?? 0,
      );
      crashlytics.setCustomKey('sync_failed_ops', failedOperations);
      crashlytics.setCustomKey(
        'sync_last_at',
        lastSuccessfulSync?.toIso8601String() ?? '',
      );
      // Breach flags — true when session totals exceed documented targets.
      crashlytics.setCustomKey(
        'sync_breach_normal_refresh',
        bytesDownloaded > targetNormalRefreshBytes,
      );
      crashlytics.setCustomKey(
        'sync_breach_no_change_delta',
        bytesDownloaded > targetNoChangeDeltaBytes,
      );
      crashlytics.setCustomKey(
        'sync_breach_initial_sync',
        bytesDownloaded > targetInitialSyncBytes,
      );
    } catch (_) {
      // Never let telemetry errors surface to the user.
    }
  }

  // ── Convenience getters ──────────────────────────────────────────────────

  bool get hasFailures => failedOperations > 0;

  String get lastSyncLabel {
    final t = lastSuccessfulSync;
    if (t == null) return 'Never';
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Human-readable throughput summary for the debug overlay.
  String get bandwidthLabel {
    String fmt(int bytes) {
      if (bytes < 1024) return '${bytes}B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
    }
    return '↓${fmt(bytesDownloaded)} ↑${fmt(bytesUploaded)}';
  }
}
