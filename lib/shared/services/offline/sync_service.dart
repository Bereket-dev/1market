import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/application.dart';
import '../app_state.dart';
import 'hive_sync_store.dart';

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
      case SyncEntityType.listing:
        return 'listing';
      case SyncEntityType.profile:
        return 'profile';
      case SyncEntityType.service:
        return 'service';
      case SyncEntityType.serviceDelete:
        return 'service_delete';
      case SyncEntityType.chatMessage:
        return 'chat_message';
      case SyncEntityType.hiringPost:
        return 'hiring_post';
      case SyncEntityType.hiringPostDelete:
        return 'hiring_post_delete';
      case SyncEntityType.application:
        return 'application';
      case SyncEntityType.applicationStatusUpdate:
        return 'application_status_update';
    }
  }
}

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

  SyncQueueEntry copyWith({String? syncStatus}) {
    return SyncQueueEntry(
      id: id,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      localUpdatedAt: localUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType.nameValue,
      'entityId': entityId,
      'payload': payload,
      'localUpdatedAt': localUpdatedAt.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  static SyncQueueEntry? fromJson(
    String jsonString,
    SyncEntityType entityType,
  ) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final localUpdatedAt =
          DateTime.tryParse(data['localUpdatedAt'] as String? ?? '');
      if (localUpdatedAt == null) return null;
      return SyncQueueEntry(
        id: data['id'] as String,
        entityType: entityType,
        entityId: data['entityId'] as String,
        payload: Map<String, dynamic>.from(
          data['payload'] as Map<String, dynamic>,
        ),
        localUpdatedAt: localUpdatedAt,
        syncStatus: data['syncStatus'] as String? ?? 'pending',
      );
    } catch (_) {
      return null;
    }
  }

  /// Deserializes from JSON string, inferring [SyncEntityType] from the stored
  /// 'entityType' field. Useful when the caller doesn't know the type ahead of time.
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

class SyncService {
  SyncService(this._appState);

  final KoolanAppState _appState;
  final HiveSyncStore _store = HiveSyncStore.instance;
  final _queue = StreamController<void>.broadcast();
  bool _isSyncing = false;

  // ── Connectivity listener ────────────────────────────────────────────────────
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  // Tracks the previous connectivity state so we only fire on offline→online
  // transitions, not on every connectivity-changed event.
  bool _wasOffline = false;
  // Debounce timer — prevents rapid-fire sync requests when the radio flaps.
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

    // ── Subscribe to connectivity changes ────────────────────────────────────
    // connectivity_plus 6+ delivers a List<ConnectivityResult>.
    // We treat "none" as offline; anything else (wifi, mobile, ethernet) as online.
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isOffline =
            results.isEmpty || results.every((r) => r == ConnectivityResult.none);

        if (_wasOffline && !isOffline) {
          // Offline → online transition detected. Debounce to avoid rapid-fire
          // triggers from radio flapping.
          _reconnectDebounce?.cancel();
          _reconnectDebounce = Timer(const Duration(milliseconds: 500), () {
            debugPrint('[SyncService] Network reconnected — triggering sync');
            requestSync();
          });
        }
        _wasOffline = isOffline;
      },
    );

    // Seed the initial offline state so the first real transition is correct.
    final initial = await Connectivity().checkConnectivity();
    _wasOffline =
        initial.isEmpty || initial.every((r) => r == ConnectivityResult.none);

    requestSync();
  }

  /// Cancel subscriptions and timers. Call this when the app is signing out or
  /// the SyncService is being torn down.
  void dispose() {
    _reconnectDebounce?.cancel();
    _connectivitySub?.cancel();
    _queue.close();
  }

  void requestSync() {
    if (!_queue.isClosed) {
      _queue.add(null);
    }
  }

  // ── Enqueue helpers ──────────────────────────────────────────────────────────

  /// Persists a profile edit to the Hive queue and triggers a sync pass.
  Future<void> enqueueProfileEdit({
    required String userId,
    required Map<String, dynamic> payload,
    required DateTime localUpdatedAt,
  }) async {
    await _store.initialize();
    final entry = SyncQueueEntry(
      id: userId,
      entityType: SyncEntityType.profile,
      entityId: userId,
      payload: payload,
      localUpdatedAt: localUpdatedAt,
      syncStatus: 'pending',
    );
    await _store.savePendingProfileEdit(userId, jsonEncode(entry.toJson()));
    requestSync();
  }

  Future<void> enqueueServiceEdit({
    required String serviceId,
    required Map<String, dynamic> payload,
    required DateTime localUpdatedAt,
  }) async {
    await _store.initialize();
    final entry = SyncQueueEntry(
      id: serviceId,
      entityType: SyncEntityType.service,
      entityId: serviceId,
      payload: payload,
      localUpdatedAt: localUpdatedAt,
      syncStatus: 'pending',
    );
    await _store.savePendingServiceEdit(serviceId, jsonEncode(entry.toJson()));
    requestSync();
  }

  Future<void> enqueueServiceDelete({required String serviceId}) async {
    await _store.initialize();
    final now = DateTime.now();
    final entry = SyncQueueEntry(
      id: serviceId,
      entityType: SyncEntityType.serviceDelete,
      entityId: serviceId,
      payload: {'deleted_at': now.toIso8601String()},
      localUpdatedAt: now,
      syncStatus: 'pending',
    );
    await _store.savePendingServiceDelete(
      serviceId,
      jsonEncode(entry.toJson()),
    );
    requestSync();
  }

  // ── Hiring post queue helpers ────────────────────────────────────────────────

  Future<void> enqueueHiringPostEdit({
    required String postId,
    required Map<String, dynamic> payload,
    required DateTime localUpdatedAt,
  }) async {
    await _store.initialize();
    final entry = SyncQueueEntry(
      id: postId,
      entityType: SyncEntityType.hiringPost,
      entityId: postId,
      payload: payload,
      localUpdatedAt: localUpdatedAt,
      syncStatus: 'pending',
    );
    await _store.savePendingHiringPostEdit(
      postId,
      jsonEncode(entry.toJson()),
    );
    requestSync();
  }

  Future<void> enqueueHiringPostDelete({required String postId}) async {
    await _store.initialize();
    final now = DateTime.now();
    final entry = SyncQueueEntry(
      id: postId,
      entityType: SyncEntityType.hiringPostDelete,
      entityId: postId,
      payload: {'deleted_at': now.toIso8601String()},
      localUpdatedAt: now,
      syncStatus: 'pending',
    );
    await _store.savePendingHiringPostDelete(
      postId,
      jsonEncode(entry.toJson()),
    );
    requestSync();
  }

  // ── Application queue helpers ────────────────────────────────────────────────

  Future<void> enqueueApplication({
    required String applicationId,
    required Map<String, dynamic> payload,
    required DateTime localUpdatedAt,
  }) async {
    await _store.initialize();
    final entry = SyncQueueEntry(
      id: applicationId,
      entityType: SyncEntityType.application,
      entityId: applicationId,
      payload: payload,
      localUpdatedAt: localUpdatedAt,
      syncStatus: 'pending',
    );
    await _store.savePendingApplication(
      applicationId,
      jsonEncode(entry.toJson()),
    );
    requestSync();
  }

  Future<void> enqueueApplicationStatusUpdate({
    required String applicationId,
    required String newStatus,
    required DateTime localUpdatedAt,
  }) async {
    await _store.initialize();
    final entry = SyncQueueEntry(
      id: applicationId,
      entityType: SyncEntityType.applicationStatusUpdate,
      entityId: applicationId,
      payload: {
        'status': newStatus,
        'status_updated_at': localUpdatedAt.toIso8601String(),
        'updated_at': localUpdatedAt.toIso8601String(),
      },
      localUpdatedAt: localUpdatedAt,
      syncStatus: 'pending',
    );
    await _store.savePendingApplicationStatusUpdate(
      applicationId,
      jsonEncode(entry.toJson()),
    );
    requestSync();
  }

  // ── Sync pass ────────────────────────────────────────────────────────────────

  Future<void> _runSyncPass() async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) return;

    final entries = await _loadPendingQueueEntries();
    for (final entry in entries) {
      if (entry.syncStatus == 'synced' || entry.syncStatus == 'failed') {
        continue;
      }
      final success = await _processEntry(client, entry);
      if (!success) break;
    }
    await _store.clearExpiredConflicts();
  }

  Future<List<SyncQueueEntry>> _loadPendingQueueEntries() async {
    final entries = <SyncQueueEntry>[];

    final listingIds = await _store.getDraftListingIds();
    for (final id in listingIds) {
      final payload = _store.readDraftListing(id);
      if (payload == null) continue;
      final entry = SyncQueueEntry.fromJson(payload, SyncEntityType.listing);
      if (entry != null) entries.add(entry);
    }

    final profileIds = await _store.getPendingProfileEditIds();
    for (final id in profileIds) {
      final payload = _store.readPendingProfileEdit(id);
      if (payload == null) continue;
      final entry = SyncQueueEntry.fromJson(payload, SyncEntityType.profile);
      if (entry != null) entries.add(entry);
    }

    final serviceIds = await _store.getPendingServiceEditIds();
    for (final id in serviceIds) {
      final payload = _store.readPendingServiceEdit(id);
      if (payload == null) continue;
      final entry = SyncQueueEntry.fromJson(payload, SyncEntityType.service);
      if (entry != null) entries.add(entry);
    }

    final serviceDeleteIds = await _store.getPendingServiceDeleteIds();
    for (final id in serviceDeleteIds) {
      final payload = _store.readPendingServiceDelete(id);
      if (payload == null) continue;
      final entry =
          SyncQueueEntry.fromJson(payload, SyncEntityType.serviceDelete);
      if (entry != null) entries.add(entry);
    }

    final messageIds = await _store.getPendingMessageIds();
    for (final id in messageIds) {
      final payload = _store.readPendingMessage(id);
      if (payload == null) continue;
      final entry =
          SyncQueueEntry.fromJson(payload, SyncEntityType.chatMessage);
      if (entry != null) entries.add(entry);
    }

    final hiringPostIds = await _store.getPendingHiringPostEditIds();
    for (final id in hiringPostIds) {
      final payload = _store.readPendingHiringPostEdit(id);
      if (payload == null) continue;
      final entry =
          SyncQueueEntry.fromJson(payload, SyncEntityType.hiringPost);
      if (entry != null) entries.add(entry);
    }

    final hiringPostDeleteIds =
        await _store.getPendingHiringPostDeleteIds();
    for (final id in hiringPostDeleteIds) {
      final payload = _store.readPendingHiringPostDelete(id);
      if (payload == null) continue;
      final entry =
          SyncQueueEntry.fromJson(payload, SyncEntityType.hiringPostDelete);
      if (entry != null) entries.add(entry);
    }

    final applicationIds = await _store.getPendingApplicationIds();
    for (final id in applicationIds) {
      final payload = _store.readPendingApplication(id);
      if (payload == null) continue;
      final entry =
          SyncQueueEntry.fromJson(payload, SyncEntityType.application);
      if (entry != null) entries.add(entry);
    }

    final appStatusIds =
        await _store.getPendingApplicationStatusUpdateIds();
    for (final id in appStatusIds) {
      final payload = _store.readPendingApplicationStatusUpdate(id);
      if (payload == null) continue;
      final entry = SyncQueueEntry.fromJson(
        payload,
        SyncEntityType.applicationStatusUpdate,
      );
      if (entry != null) entries.add(entry);
    }

    entries.sort((a, b) => a.localUpdatedAt.compareTo(b.localUpdatedAt));
    return entries;
  }

  Future<bool> _processEntry(
    SupabaseClient client,
    SyncQueueEntry entry,
  ) async {
    // For deletes, skip the conflict-check — just execute unconditionally.
    final isDelete = entry.entityType == SyncEntityType.serviceDelete ||
        entry.entityType == SyncEntityType.hiringPostDelete;

    // Status updates by the poster are always authoritative (RLS enforces that
    // only the poster can write this). Skip the conflict check so a recent
    // submission timestamp never causes the update to be silently discarded.
    final isAuthoritative =
        entry.entityType == SyncEntityType.applicationStatusUpdate;

    // Skip conflict check for brand-new local items (local_* ids). They don't
    // exist remotely yet, so there is nothing to conflict with.
    final isNewLocalItem = entry.entityId.startsWith('local_');

    if (!isDelete && !isAuthoritative && !isNewLocalItem) {
      final remoteUpdatedAt = await _fetchRemoteUpdatedAt(client, entry);
      // Only treat as a conflict when the remote timestamp is *meaningfully*
      // newer than what we saved locally (> 2 s tolerance covers clock skew
      // and the lag between a successful insert and the next sync pass).
      if (remoteUpdatedAt != null &&
          remoteUpdatedAt.isAfter(
            entry.localUpdatedAt.add(const Duration(seconds: 2)),
          )) {
        await _discardEntry(entry, remoteUpdatedAt);
        return true;
      }
    }

    try {
      await _retryWithBackoff(() async {
        await _pushEntry(client, entry);
        await _deleteQueueEntry(entry);
      });
      // For existing items (real UUID), mark synced in-memory now.
      // For new items (local_*), replaceServiceId / replaceHiringPostId
      // already handled the synced state inside _pushEntry.
      if (!entry.entityId.startsWith('local_')) {
        _appState.markEntitySynced(entry.entityType, entry.entityId);
      }
      // After a status update reaches Supabase, patch myApplications in-memory
      // so the applicant sees the new status immediately without a reload.
      if (entry.entityType == SyncEntityType.applicationStatusUpdate) {
        final statusStr = entry.payload['status'] as String?;
        final updatedAtStr =
            entry.payload['status_updated_at'] as String?;
        if (statusStr != null) {
          _appState.onApplicationStatusSynced(
            applicationId: entry.entityId,
            newStatus: ApplicationStatus.fromString(statusStr),
            statusUpdatedAt: updatedAtStr != null
                ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
                : DateTime.now(),
          );
        }
      }
      return true;
    } on SocketException catch (error) {
      debugPrint('Network error during sync: $error');
      await _markEntryFailed(entry);
      return false;
    } on TimeoutException catch (error) {
      debugPrint('Timeout during sync: $error');
      await _markEntryFailed(entry);
      return false;
    } catch (error) {
      debugPrint('Sync failure for ${entry.entityType.nameValue}: $error');
      await _markEntryFailed(entry);
      return false;
    }
  }

  Future<DateTime?> _fetchRemoteUpdatedAt(
    SupabaseClient client,
    SyncQueueEntry entry,
  ) async {
    final table = _tableFor(entry.entityType);
    final response = await client
        .from(table)
        .select('updated_at')
        .eq('id', entry.entityId)
        .maybeSingle();

    if (response is! Map<String, dynamic>) return null;
    final raw = response['updated_at'];
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _pushEntry(SupabaseClient client, SyncQueueEntry entry) async {
    // A 'local_*' id means this is a brand-new item that has never been
    // inserted into Supabase. We must NOT send that id — let Supabase generate
    // a real UUID. After the insert we capture the UUID and update the
    // in-memory list so every subsequent operation (edit, delete) targets the
    // correct row.
    final isLocalId = entry.entityId.startsWith('local_');

    switch (entry.entityType) {
      case SyncEntityType.listing:
        final p = Map<String, dynamic>.from(entry.payload);
        if (!isLocalId) p['id'] = entry.entityId;
        final exists =
            !isLocalId && await _remoteExists(client, 'listings', entry.entityId);
        if (exists) {
          await client.from('listings').update(p).eq('id', entry.entityId);
        } else {
          await client.from('listings').insert(p);
        }
        break;
      case SyncEntityType.profile:
        final p = Map<String, dynamic>.from(entry.payload);
        final exists =
            await _remoteExists(client, 'profiles', entry.entityId);
        if (exists) {
          await client.from('profiles').update(p).eq('id', entry.entityId);
        } else {
          await client.from('profiles').insert(p);
        }
        break;
      case SyncEntityType.service:
        final p = Map<String, dynamic>.from(entry.payload);
        if (!isLocalId) p['id'] = entry.entityId;
        final exists =
            !isLocalId && await _remoteExists(client, 'services', entry.entityId);
        if (exists) {
          await client.from('services').update(p).eq('id', entry.entityId);
        } else {
          // New service — let Supabase assign a real UUID.
          final row = await client
              .from('services')
              .insert(p)
              .select('id')
              .single();
          final realId = row['id'] as String;
          if (isLocalId) {
            _appState.replaceServiceId(entry.entityId, realId);
          }
        }
        break;
      case SyncEntityType.serviceDelete:
        // Hard-delete — if row doesn't exist, treat as already deleted (no-op).
        await client.from('services').delete().eq('id', entry.entityId);
        break;
      case SyncEntityType.chatMessage:
        final p = Map<String, dynamic>.from(entry.payload);
        if (!isLocalId) p['id'] = entry.entityId;
        final exists =
            !isLocalId && await _remoteExists(client, 'chat_messages', entry.entityId);
        if (exists) {
          await client
              .from('chat_messages')
              .update(p)
              .eq('id', entry.entityId);
        } else {
          await client.from('chat_messages').insert(p);
        }
        break;
      case SyncEntityType.hiringPost:
        final p = Map<String, dynamic>.from(entry.payload);
        if (!isLocalId) p['id'] = entry.entityId;
        final exists =
            !isLocalId && await _remoteExists(client, 'hiring_posts', entry.entityId);
        if (exists) {
          await client.from('hiring_posts').update(p).eq('id', entry.entityId);
        } else {
          // New hiring post — let Supabase assign a real UUID.
          final row = await client
              .from('hiring_posts')
              .insert(p)
              .select('id')
              .single();
          final realId = row['id'] as String;
          if (isLocalId) {
            _appState.replaceHiringPostId(entry.entityId, realId);
          }
        }
        break;
      case SyncEntityType.hiringPostDelete:
        await client.from('hiring_posts').delete().eq('id', entry.entityId);
        break;
      case SyncEntityType.application:
        final p = Map<String, dynamic>.from(entry.payload);
        if (!isLocalId) p['id'] = entry.entityId;
        final exists =
            !isLocalId && await _remoteExists(client, 'applications', entry.entityId);
        if (exists) {
          await client.from('applications').update(p).eq('id', entry.entityId);
        } else {
          await client.from('applications').insert(p);
        }
        break;
      case SyncEntityType.applicationStatusUpdate:
        // Only updates the status field — poster action only.
        await client
            .from('applications')
            .update(entry.payload)
            .eq('id', entry.entityId);
        break;
    }
  }

  Future<bool> _remoteExists(
    SupabaseClient client,
    String table,
    String id,
  ) async {
    final row =
        await client.from(table).select('id').eq('id', id).maybeSingle();
    return row != null;
  }

  Future<void> _retryWithBackoff(Future<void> Function() action) async {
    const delays = [
      Duration(seconds: 5),
      Duration(seconds: 15),
      Duration(seconds: 60),
    ];
    for (var attempt = 0; attempt < delays.length; attempt++) {
      try {
        await action();
        return;
      } catch (error) {
        if (error is SocketException || error is TimeoutException) {
          if (attempt == delays.length - 1) rethrow;
          await Future<void>.delayed(delays[attempt]);
          continue;
        }
        rethrow;
      }
    }
  }

  Future<void> _discardEntry(
    SyncQueueEntry entry,
    DateTime remoteUpdatedAt,
  ) async {
    // The remote record is newer — our local change is stale. Remove it from
    // the queue silently. On a single-device setup this normally means the
    // insert already went through on a previous pass; showing an error here
    // would be confusing and cause false data-loss reports.
    await _deleteQueueEntry(entry);
    debugPrint(
      '[SyncService] discarded stale ${entry.entityType.nameValue} '
      '${entry.entityId}: remote=${remoteUpdatedAt.toIso8601String()} '
      'local=${entry.localUpdatedAt.toIso8601String()}',
    );
  }

  Future<void> _markEntryFailed(SyncQueueEntry entry) async {
    await _updateQueueEntry(entry.copyWith(syncStatus: 'failed'));
  }

  Future<void> _deleteQueueEntry(SyncQueueEntry entry) async {
    switch (entry.entityType) {
      case SyncEntityType.listing:
        await _store.deleteDraftListing(entry.id);
        break;
      case SyncEntityType.profile:
        await _store.deletePendingProfileEdit(entry.id);
        break;
      case SyncEntityType.service:
        await _store.deletePendingServiceEdit(entry.id);
        break;
      case SyncEntityType.serviceDelete:
        await _store.deletePendingServiceDelete(entry.id);
        break;
      case SyncEntityType.chatMessage:
        await _store.deletePendingMessage(entry.id);
        break;
      case SyncEntityType.hiringPost:
        await _store.deletePendingHiringPostEdit(entry.id);
        break;
      case SyncEntityType.hiringPostDelete:
        await _store.deletePendingHiringPostDelete(entry.id);
        break;
      case SyncEntityType.application:
        await _store.deletePendingApplication(entry.id);
        break;
      case SyncEntityType.applicationStatusUpdate:
        await _store.deletePendingApplicationStatusUpdate(entry.id);
        break;
    }
  }

  Future<void> _updateQueueEntry(SyncQueueEntry entry) async {
    final payload = jsonEncode(entry.toJson());
    switch (entry.entityType) {
      case SyncEntityType.listing:
        await _store.saveDraftListing(entry.id, payload);
        break;
      case SyncEntityType.profile:
        await _store.savePendingProfileEdit(entry.id, payload);
        break;
      case SyncEntityType.service:
        await _store.savePendingServiceEdit(entry.id, payload);
        break;
      case SyncEntityType.serviceDelete:
        await _store.savePendingServiceDelete(entry.id, payload);
        break;
      case SyncEntityType.chatMessage:
        await _store.savePendingMessage(entry.id, payload);
        break;
      case SyncEntityType.hiringPost:
        await _store.savePendingHiringPostEdit(entry.id, payload);
        break;
      case SyncEntityType.hiringPostDelete:
        await _store.savePendingHiringPostDelete(entry.id, payload);
        break;
      case SyncEntityType.application:
        await _store.savePendingApplication(entry.id, payload);
        break;
      case SyncEntityType.applicationStatusUpdate:
        await _store.savePendingApplicationStatusUpdate(entry.id, payload);
        break;
    }
  }

  String _tableFor(SyncEntityType entityType) {
    switch (entityType) {
      case SyncEntityType.listing:
        return 'listings';
      case SyncEntityType.profile:
        return 'profiles';
      case SyncEntityType.service:
      case SyncEntityType.serviceDelete:
        return 'services';
      case SyncEntityType.chatMessage:
        return 'chat_messages';
      case SyncEntityType.hiringPost:
      case SyncEntityType.hiringPostDelete:
        return 'hiring_posts';
      case SyncEntityType.application:
      case SyncEntityType.applicationStatusUpdate:
        return 'applications';
    }
  }

  String _itemLabel(SyncQueueEntry entry) {
    switch (entry.entityType) {
      case SyncEntityType.listing:
        return 'listing';
      case SyncEntityType.profile:
        return 'profile';
      case SyncEntityType.service:
      case SyncEntityType.serviceDelete:
        return 'service';
      case SyncEntityType.chatMessage:
        return 'message';
      case SyncEntityType.hiringPost:
      case SyncEntityType.hiringPostDelete:
        return 'job post';
      case SyncEntityType.application:
      case SyncEntityType.applicationStatusUpdate:
        return 'application';
    }
  }
}
