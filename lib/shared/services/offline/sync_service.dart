import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import 'hive_sync_store.dart';

enum SyncEntityType { listing, profile, chatMessage }

extension SyncEntityTypeExt on SyncEntityType {
  String get nameValue {
    switch (this) {
      case SyncEntityType.listing:
        return 'listing';
      case SyncEntityType.profile:
        return 'profile';
      case SyncEntityType.chatMessage:
        return 'chat_message';
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

  static SyncQueueEntry? fromJson(String jsonString, SyncEntityType entityType) {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final localUpdatedAt = DateTime.tryParse(data['localUpdatedAt'] as String? ?? '');
      if (localUpdatedAt == null) return null;
      return SyncQueueEntry(
        id: data['id'] as String,
        entityType: entityType,
        entityId: data['entityId'] as String,
        payload: Map<String, dynamic>.from(data['payload'] as Map<String, dynamic>),
        localUpdatedAt: localUpdatedAt,
        syncStatus: data['syncStatus'] as String? ?? 'pending',
      );
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
    requestSync();
  }

  void requestSync() {
    if (!_queue.isClosed) {
      _queue.add(null);
    }
  }

  /// Persists a profile edit to the Hive queue and triggers a sync pass.
  /// [userId] is the profile's id. [payload] must contain the fields to push
  /// to Supabase (snake_case column names). [localUpdatedAt] stamps the edit.
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

  Future<void> _runSyncPass() async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      return;
    }

    final entries = await _loadPendingQueueEntries();
    for (final entry in entries) {
      if (entry.syncStatus == 'synced' || entry.syncStatus == 'failed') {
        continue;
      }

      final success = await _processEntry(client, entry);
      if (!success) {
        break;
      }
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

    final messageIds = await _store.getPendingMessageIds();
    for (final id in messageIds) {
      final payload = _store.readPendingMessage(id);
      if (payload == null) continue;
      final entry = SyncQueueEntry.fromJson(payload, SyncEntityType.chatMessage);
      if (entry != null) entries.add(entry);
    }

    entries.sort((a, b) => a.localUpdatedAt.compareTo(b.localUpdatedAt));
    return entries;
  }

  Future<bool> _processEntry(SupabaseClient client, SyncQueueEntry entry) async {
    final remoteUpdatedAt = await _fetchRemoteUpdatedAt(client, entry);
    if (remoteUpdatedAt != null && !entry.localUpdatedAt.isAfter(remoteUpdatedAt)) {
      await _discardEntry(entry, remoteUpdatedAt);
      return true;
    }

    try {
      await _retryWithBackoff(() async {
        await _pushEntry(client, entry, remoteUpdatedAt != null);
        await _deleteQueueEntry(entry);
      });
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

    if (response is! Map<String, dynamic>) {
      return null;
    }

    final raw = response['updated_at'];
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _pushEntry(
    SupabaseClient client,
    SyncQueueEntry entry,
    bool remoteExists,
  ) async {
    switch (entry.entityType) {
      case SyncEntityType.listing:
        final listingPayload = Map<String, dynamic>.from(entry.payload)
          ..['id'] = entry.entityId;
        if (remoteExists) {
          await client.from('listings').update(listingPayload).eq('id', entry.entityId);
        } else {
          await client.from('listings').insert(listingPayload);
        }
        break;
      case SyncEntityType.profile:
        final profilePayload = Map<String, dynamic>.from(entry.payload);
        if (remoteExists) {
          await client.from('profiles').update(profilePayload).eq('id', entry.entityId);
        } else {
          await client.from('profiles').insert(profilePayload);
        }
        break;
      case SyncEntityType.chatMessage:
        final messagePayload = Map<String, dynamic>.from(entry.payload)
          ..['id'] = entry.entityId;
        if (remoteExists) {
          await client.from('chat_messages').update(messagePayload).eq('id', entry.entityId);
        } else {
          await client.from('chat_messages').insert(messagePayload);
        }
        break;
    }
  }

  Future<void> _retryWithBackoff(Future<void> Function() action) async {
    const delays = [Duration(seconds: 5), Duration(seconds: 15), Duration(seconds: 60)];
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
    final discardedEntry = entry.copyWith(syncStatus: 'discarded');
    await _updateQueueEntry(discardedEntry);
    final conflictPayload = jsonEncode({
      'entityType': entry.entityType.nameValue,
      'entityId': entry.entityId,
      'payload': entry.payload,
      'localUpdatedAt': entry.localUpdatedAt.toIso8601String(),
      'remoteUpdatedAt': remoteUpdatedAt.toIso8601String(),
    });
    await _store.saveConflict(entry.id, '${DateTime.now().millisecondsSinceEpoch}|$conflictPayload');
    _appState.dataError =
        'Your recent change to ${_itemLabel(entry)} was overwritten by a newer update.';
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
      case SyncEntityType.chatMessage:
        await _store.deletePendingMessage(entry.id);
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
      case SyncEntityType.chatMessage:
        await _store.savePendingMessage(entry.id, payload);
        break;
    }
  }

  String _tableFor(SyncEntityType entityType) {
    switch (entityType) {
      case SyncEntityType.listing:
        return 'listings';
      case SyncEntityType.profile:
        return 'profiles';
      case SyncEntityType.chatMessage:
        return 'chat_messages';
    }
  }

  String _itemLabel(SyncQueueEntry entry) {
    switch (entry.entityType) {
      case SyncEntityType.listing:
        return 'listing';
      case SyncEntityType.profile:
        return 'profile';
      case SyncEntityType.chatMessage:
        return 'message';
    }
  }
}
