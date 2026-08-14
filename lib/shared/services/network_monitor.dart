import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network quality classification used to gate sync frequency,
/// image quality selection, and prefetch behaviour.
///
/// Classification rules
/// ─────────────────────
/// OFFLINE  → no connectivity result
/// POOR     → mobile/wifi present but recent request latency > 2 000 ms
///            or consecutive failures ≥ 3
/// LIMITED  → mobile/wifi present, latency 800–2 000 ms or 1–2 failures
/// GOOD     → wifi/ethernet with latency < 800 ms and no recent failures
///
/// The [NetworkMonitor] does NOT make real HTTP probe requests — it infers
/// quality from two signals:
///   1. [connectivity_plus] connectivity type (wifi / mobile / ethernet / none)
///   2. A lightweight rolling window of latency samples and failure counts
///      reported by the repository layer via [recordSuccess] / [recordFailure].
///
/// This keeps the monitor completely passive and allocation-free during sync.
enum NetworkQuality { good, limited, poor, offline }

class NetworkMonitor {
  NetworkMonitor._();

  static final NetworkMonitor instance = NetworkMonitor._();

  // ── Observable state ──────────────────────────────────────────────────────

  NetworkQuality _quality = NetworkQuality.good;

  NetworkQuality get quality => _quality;

  /// Fires whenever [quality] changes.
  final _controller = StreamController<NetworkQuality>.broadcast();
  Stream<NetworkQuality> get qualityStream => _controller.stream;

  // ── Connectivity type ──────────────────────────────────────────────────────

  List<ConnectivityResult> _results = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // ── Rolling latency window (last 5 samples) ────────────────────────────────

  static const _kWindowSize = 5;
  final _latencySamples = <int>[]; // ms
  int _consecutiveFailures = 0;

  // ── Initialisation ─────────────────────────────────────────────────────────

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Seed with current connectivity type.
    _results = await Connectivity().checkConnectivity();
    _recompute();

    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (results) {
        _results = results;
        _recompute();
      },
    );
  }

  void dispose() {
    _connectivitySub?.cancel();
    _controller.close();
  }

  // ── Reporting API called by repository / sync layer ────────────────────────

  /// Report a successful network request with its round-trip [latencyMs].
  void recordSuccess(int latencyMs) {
    _consecutiveFailures = 0;
    _latencySamples.add(latencyMs);
    if (_latencySamples.length > _kWindowSize) {
      _latencySamples.removeAt(0);
    }
    _recompute();
  }

  /// Report a failed network request (timeout, socket error, etc.).
  void recordFailure() {
    _consecutiveFailures++;
    _recompute();
  }

  // ── Classification ─────────────────────────────────────────────────────────

  void _recompute() {
    final prev = _quality;
    _quality = _classify();
    if (_quality != prev) {
      if (kDebugMode) {
        debugPrint('[NetworkMonitor] quality: $prev → $_quality '
            '(results=$_results, failures=$_consecutiveFailures, '
            'avgLatency=${_avgLatency()}ms)');
      }
      _controller.add(_quality);
    }
  }

  NetworkQuality _classify() {
    final isOffline = _results.isEmpty ||
        _results.every((r) => r == ConnectivityResult.none);
    if (isOffline) return NetworkQuality.offline;

    // Hard failures — always downgrade immediately.
    if (_consecutiveFailures >= 3) return NetworkQuality.poor;

    final avg = _avgLatency();

    // No samples yet — classify by connection type only.
    if (avg == null) {
      final hasWifi = _results.any((r) =>
          r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);
      return hasWifi ? NetworkQuality.good : NetworkQuality.limited;
    }

    if (_consecutiveFailures >= 1 || avg > 2000) return NetworkQuality.poor;
    if (avg > 800) return NetworkQuality.limited;
    return NetworkQuality.good;
  }

  int? _avgLatency() {
    if (_latencySamples.isEmpty) return null;
    final sum = _latencySamples.fold(0, (a, b) => a + b);
    return (sum / _latencySamples.length).round();
  }

  // ── Convenience helpers ────────────────────────────────────────────────────

  bool get isOffline => _quality == NetworkQuality.offline;
  bool get isPoor    => _quality == NetworkQuality.poor;
  bool get isLimited => _quality == NetworkQuality.limited;
  bool get isGood    => _quality == NetworkQuality.good;

  /// True when images should be suppressed or deferred (POOR or OFFLINE).
  bool get suppressImages =>
      _quality == NetworkQuality.poor || _quality == NetworkQuality.offline;

  /// True when background prefetching should be skipped (not GOOD).
  bool get skipPrefetch => _quality != NetworkQuality.good;

  /// Suggested sync polling interval based on network quality.
  Duration get syncInterval {
    return switch (_quality) {
      NetworkQuality.good    => const Duration(minutes: 5),
      NetworkQuality.limited => const Duration(minutes: 15),
      NetworkQuality.poor    => const Duration(minutes: 30),
      NetworkQuality.offline => const Duration(hours: 1),
    };
  }
}
