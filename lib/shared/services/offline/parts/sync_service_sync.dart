part of '../sync_service.dart';

// ── Sync pass ──────────────────────────────────────────────────────────────

extension SyncServiceSyncpass on SyncService {
  // ── Sync pass ────────────────────────────────────────────────────────────────

  Future<void> _runSyncPass() async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) return;

    // Flush any pending profile photo uploads first (avatar / banner).
    await _appState.flushPendingPhotoUploads();
    await _appState.flushPendingCvUploads();
    await _appState.flushPendingListingImages();

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

    Future<void> discardCorrupt(
      SyncEntityType type,
      String id,
      Future<void> Function(String) deleteFn,
      String? payload,
    ) async {
      if (payload == null) return;
      final entry = SyncQueueEntry.fromJson(payload, type);
      if (entry == null) {
        await deleteFn(id);
        onCorrupt?.call(type.nameValue, id);
      } else {
        entries.add(entry);
      }
    }

    final listingIds = await _store.getDraftListingIds();
    for (final id in listingIds) {
      await discardCorrupt(
        SyncEntityType.listing,
        id,
        _store.deleteDraftListing,
        _store.readDraftListing(id),
      );
    }

    final profileIds = await _store.getPendingProfileEditIds();
    for (final id in profileIds) {
      await discardCorrupt(
        SyncEntityType.profile,
        id,
        _store.deletePendingProfileEdit,
        _store.readPendingProfileEdit(id),
      );
    }

    final serviceIds = await _store.getPendingServiceEditIds();
    for (final id in serviceIds) {
      await discardCorrupt(
        SyncEntityType.service,
        id,
        _store.deletePendingServiceEdit,
        _store.readPendingServiceEdit(id),
      );
    }

    final serviceDeleteIds = await _store.getPendingServiceDeleteIds();
    for (final id in serviceDeleteIds) {
      await discardCorrupt(
        SyncEntityType.serviceDelete,
        id,
        _store.deletePendingServiceDelete,
        _store.readPendingServiceDelete(id),
      );
    }

    final messageIds = await _store.getPendingMessageIds();
    for (final id in messageIds) {
      await discardCorrupt(
        SyncEntityType.chatMessage,
        id,
        _store.deletePendingMessage,
        _store.readPendingMessage(id),
      );
    }

    final hiringPostIds = await _store.getPendingHiringPostEditIds();
    for (final id in hiringPostIds) {
      await discardCorrupt(
        SyncEntityType.hiringPost,
        id,
        _store.deletePendingHiringPostEdit,
        _store.readPendingHiringPostEdit(id),
      );
    }

    final hiringPostDeleteIds =
        await _store.getPendingHiringPostDeleteIds();
    for (final id in hiringPostDeleteIds) {
      await discardCorrupt(
        SyncEntityType.hiringPostDelete,
        id,
        _store.deletePendingHiringPostDelete,
        _store.readPendingHiringPostDelete(id),
      );
    }

    final applicationIds = await _store.getPendingApplicationIds();
    for (final id in applicationIds) {
      await discardCorrupt(
        SyncEntityType.application,
        id,
        _store.deletePendingApplication,
        _store.readPendingApplication(id),
      );
    }

    final appStatusIds =
        await _store.getPendingApplicationStatusUpdateIds();
    for (final id in appStatusIds) {
      await discardCorrupt(
        SyncEntityType.applicationStatusUpdate,
        id,
        _store.deletePendingApplicationStatusUpdate,
        _store.readPendingApplicationStatusUpdate(id),
      );
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
      //
      // Both sides are normalised to UTC before comparing.  localUpdatedAt is
      // stored as a local-time DateTime (DateTime.now(), no Z suffix) so its
      // .toUtc() call converts it correctly regardless of device timezone.
      // remoteUpdatedAt comes from Supabase with a Z suffix so it is already
      // UTC, but .toUtc() is a no-op in that case — safe to call always.
      if (remoteUpdatedAt != null &&
          remoteUpdatedAt.toUtc().isAfter(
            entry.localUpdatedAt.toUtc().add(const Duration(seconds: 2)),
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
      if (kDebugMode) debugPrint('Network error during sync: $error');
      await _markEntryFailed(entry);
      return false;
    } on TimeoutException catch (error) {
      if (kDebugMode) debugPrint('Timeout during sync: $error');
      await _markEntryFailed(entry);
      return false;
    } catch (error) {
      if (kDebugMode) debugPrint('Sync failure for ${entry.entityType.nameValue}: $error');
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
    // Supabase always returns updated_at with a Z suffix (UTC).
    // DateTime.tryParse correctly marks these as UTC (isUtc == true).
    // We call .toUtc() defensively in case a row somehow has a tz-naive value.
    return DateTime.tryParse(raw)?.toUtc();
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
    // the queue. Notify via callback so the UI can show a SnackBar without
    // using any popup or overlay pattern.
    await _deleteQueueEntry(entry);
    if (kDebugMode) {
      debugPrint(
        '[SyncService] discarded stale ${entry.entityType.nameValue} '
        '${entry.entityId}: remote=${remoteUpdatedAt.toIso8601String()} '
        'local=${entry.localUpdatedAt.toIso8601String()}',
      );
    }
    onDiscard?.call(entry.entityType.nameValue, entry.entityId);
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
}
