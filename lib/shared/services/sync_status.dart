import 'package:flutter/foundation.dart';

/// Observable sync status model — tracks aggregate metrics across all sync passes.
///
/// Exposed on [KoolanAppState.syncObservability] and consumed by [SyncDebugOverlay]
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
