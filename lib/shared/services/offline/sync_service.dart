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
    }
  }
}

// ── Sync queue entry ──────────────────────────────────────────────────────────

class SyncQueueEntry {
  const SyncQueueEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.localUpdatedAt,
    required this.syncStatus,
  });

  final String id;
  final SyncEntityType entityType;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime localUpdatedAt;
  final String syncStatus;

  SyncQueueEntry copyWith({String? syncStatus}) => SyncQueueEntry(
        id: id,
        entityType: entityType,
        entityId: entityId,
        payload: payload,
        localUpdatedAt: localUpdatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType.nameValue,
        'entityId': entityId,
        'payload': payload,
        'localUpdatedAt': localUpdatedAt.toUtc().toIso8601String(),
        'syncStatus': syncStatus,
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
        syncStatus: data['syncStatus'] as String? ?? 'pending',
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
