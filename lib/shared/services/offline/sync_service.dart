import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/application.dart';
import '../app_state.dart';
import 'hive_sync_store.dart';

part 'parts/sync_service_enqueue.dart';
part 'parts/sync_service_sync.dart';

// ── Sync entity type ──────────────────────────────────────────────────────────

enum SyncEntityType {
  listing,
  profile,
  service,
  serviceDelete,
  chatMessage,
  hiringPost,
  hiringPostDelete,
  application,
  applicationStatusUpdate,
  favorite,
}

extension SyncEntityTypeExt on SyncEntityType {
  String get nameValue {
    switch (this) {
      case SyncEntityType.listing:            return 'listing';
      case SyncEntityType.profile:            return 'profile';
      case SyncEntityType.service:            return 'service';
      case SyncEntityType.serviceDelete:      return 'service_delete';
      case SyncEntityType.chatMessage:        return 'chat_message';
      case SyncEntityType.hiringPost:         return 'hiring_post';
      case SyncEntityType.hiringPostDelete:   return 'hiring_post_delete';
      case SyncEntityType.application:        return 'application';
      case SyncEntityType.applicationStatusUpdate: return 'application_status_update';
      case SyncEntityType.favorite:           return 'favorite';
    }
  }
}

// ── Sync queue entry ──────────────────────────────────────────────────────────

/// Maximum number of sync attempts before an entry is moved to the
/// [kStatusFailedRequiresAttention] terminal state.
const int kMaxSyncAttempts = 8;

const String kStatusPending                = 'pending';
const String kStatusFailed                 = 'failed';
const String kStatusFailedRequiresAttention = 'failed_requires_attention';
const String kStatusSynced                 = 'synced';

class SyncQueueEntry {
  const SyncQueueEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.localUpdatedAt,
    required this.syncStatus,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.nextAttemptAt,
    this.lastError,
  });

  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime localUpdatedAt;
  final String syncStatus;

  /// How many times this entry has been attempted (including the current run).
  final int attemptCount;

  /// When the last attempt (successful or failed) was made.
  final DateTime? lastAttemptAt;

  /// Earliest time at which this entry should be retried.
  /// The sync pass skips entries where nextAttemptAt is in the future.
  final DateTime? nextAttemptAt;

  /// Human-readable error from the last failure, for the debug overlay.
  final String? lastError;

  /// True when this entry has reached the terminal failure state.
  bool get requiresAttention =>
      syncStatus == kStatusFailedRequiresAttention;

  /// True when the entry is not yet due for its next retry attempt.
  bool get isSnoozed {
    final next = nextAttemptAt;
    if (next == null) return false;
    return DateTime.now().toUtc().isBefore(next);
  }

  SyncQueueEntry copyWith({
    String? syncStatus,
    int? attemptCount,
    DateTime? lastAttemptAt,
    DateTime? nextAttemptAt,
    String? lastError,
  }) =>
      SyncQueueEntry(
        id: id,
        entityType: entityType,
        entityId: entityId,
        payload: payload,
        localUpdatedAt: localUpdatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        attemptCount: attemptCount ?? this.attemptCount,
        lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
        lastError: lastError ?? this.lastError,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType.nameValue,
        'entityId': entityId,
        'payload': payload,
        'localUpdatedAt': localUpdatedAt.toUtc().toIso8601String(),
        'syncStatus': syncStatus,
        'attemptCount': attemptCount,
        if (lastAttemptAt != null)
          'lastAttemptAt': lastAttemptAt!.toUtc().toIso8601String(),
        if (nextAttemptAt != null)
          'nextAttemptAt': nextAttemptAt!.toUtc().toIso8601String(),
        if (lastError != null) 'lastError': lastError,
      };

  static SyncQueueEntry? fromJson(String jsonString, SyncEntityType entityType) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final raw = data['localUpdatedAt'] as String? ?? '';
      final ts = DateTime.tryParse(raw)?.toUtc();
      if (ts == null) return null;
      return SyncQueueEntry(
        id: data['id'] as String,
        entityType: entityType,
        entityId: data['entityId'] as String,
        payload: Map<String, dynamic>.from(data['payload'] as Map<String, dynamic>),
        localUpdatedAt: ts,
        syncStatus: data['syncStatus'] as String? ?? kStatusPending,
        // New fields — default gracefully when missing (old Hive entries).
        attemptCount: (data['attemptCount'] as num?)?.toInt() ?? 0,
        lastAttemptAt: data['lastAttemptAt'] != null
            ? DateTime.tryParse(data['lastAttemptAt'] as String)?.toUtc()
            : null,
        nextAttemptAt: data['nextAttemptAt'] != null
            ? DateTime.tryParse(data['nextAttemptAt'] as String)?.toUtc()
            : null,
        lastError: data['lastError'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static SyncQueueEntry? fromJsonAutoType(String jsonString) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final typeStr = data['entityType'] as String? ?? '';
      final entityType = SyncEntityType.values.firstWhere(
        (t) => t.nameValue == typeStr,
        orElse: () => SyncEntityType.listing,
      );
      return fromJson(jsonString, entityType);
    } catch (_) {
      return null;
    }
  }
}

// ── Sync service ──────────────────────────────────────────────────────────────

class SyncService {
  SyncService(this._appState);

  final KoolanAppState _appState;
  final HiveSyncStore _store = HiveSyncStore.instance;
  final _queue = StreamController<void>.broadcast();
  bool _isSyncing = false;

  /// Called when a queued entry is discarded due to an LWW conflict.
  void Function(String entityType, String entityId)? onDiscard;

  /// Called when a queued entry has corrupted JSON and is dropped.
  void Function(String entityType, String entityId)? onCorrupt;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _wasOffline = false;
  Timer? _reconnectDebounce;

  Future<void> init() async {
    await _store.initialize();
    _queue.stream.listen((_) async {
      if (_isSyncing) return;
      _isSyncing = true;
      try {
        await _runSyncPass();
      } finally {
        _isSyncing = false;
      }
    });

    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isOffline =
            results.isEmpty || results.every((r) => r == ConnectivityResult.none);
        if (_wasOffline && !isOffline) {
          _reconnectDebounce?.cancel();
          _reconnectDebounce = Timer(const Duration(milliseconds: 500), () {
            if (kDebugMode) debugPrint('[SyncService] Network reconnected — triggering sync');
            requestSync();
          });
        }
        _wasOffline = isOffline;
      },
    );

    final initial = await Connectivity().checkConnectivity();
    _wasOffline =
        initial.isEmpty || initial.every((r) => r == ConnectivityResult.none);

    requestSync();
  }

  void dispose() {
    _reconnectDebounce?.cancel();
    _connectivitySub?.cancel();
    _queue.close();
  }

  void requestSync() {
    if (!_queue.isClosed) _queue.add(null);
  }
}
