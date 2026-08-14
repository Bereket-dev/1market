part of '../sync_service.dart';

// ── Sync pass ──────────────────────────────────────────────────────────────

extension SyncServiceSyncpass on SyncService {
  // ── Entry point ───────────────────────────────────────────────────────────

  Future<void> _runSyncPass() async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) return;

    final t0 = DateTime.now();

    // ── P0: Media uploads (avatar, CV, listing images) ─────────────────────
    await _appState.flushPendingPhotoUploads();
    await _appState.flushPendingCvUploads();
    await _appState.flushPendingListingImages();

    // ── Load queue, grouped by priority ────────────────────────────────────
    // P1: listings
    // P2: favorites, profile
    // P3: services, hiring posts, applications, chat
    final p1 = await _loadPendingByTypes([
      SyncEntityType.listing,
    ]);
    final p2 = await _loadPendingByTypes([
      SyncEntityType.favorite,
      SyncEntityType.profile,
    ]);
    final p3 = await _loadPendingByTypes([
      SyncEntityType.service,
      SyncEntityType.serviceDelete,
      SyncEntityType.hiringPost,
      SyncEntityType.hiringPostDelete,
      SyncEntityType.application,
      SyncEntityType.applicationStatusUpdate,
      SyncEntityType.chatMessage,
    ]);

    // Process in order; stop at first permanent network failure.
    for (final group in [p1, p2, p3]) {
      for (final entry in group) {
        final success = await _processEntry(client, entry);
        if (!success) {
          // Network down — bail out of entire pass; will retry on reconnect.
          _appState.onSyncPassComplete(
            duration: DateTime.now().difference(t0),
            hadNetworkError: true,
          );
          await _store.clearExpiredConflicts();
          return;
        }
      }
    }

    _appState.onSyncPassComplete(
      duration: DateTime.now().difference(t0),
      hadNetworkError: false,
    );
    await _store.clearExpiredConflicts();
  }

  // ── Queue loaders ─────────────────────────────────────────────────────────

  Future<List<SyncQueueEntry>> _loadPendingByTypes(
    List<SyncEntityType> types,
  ) async {
    final entries = <SyncQueueEntry>[];

    Future<void> load(
      SyncEntityType type,
      Future<List<String>> Function() getIds,
      Future<void> Function(String) deleteFn,
      String? Function(String) readFn,
    ) async {
      final ids = await getIds();
      for (final id in ids) {
        final payload = readFn(id);
        if (payload == null) continue;
        final entry = SyncQueueEntry.fromJson(payload, type);
        if (entry == null) {
          await deleteFn(id);
          onCorrupt?.call(type.nameValue, id);
          continue;
        }
        // Skip terminal states.
        if (entry.syncStatus == kStatusSynced ||
            entry.syncStatus == kStatusFailedRequiresAttention) {
          continue;
        }
        // Skip entries snoozed by nextAttemptAt.
        if (entry.isSnoozed) continue;
        entries.add(entry);
      }
    }

    for (final type in types) {
      switch (type) {
        case SyncEntityType.listing:
          await load(
            type,
            _store.getDraftListingIds,
            _store.deleteDraftListing,
            _store.readDraftListing,
          );
        case SyncEntityType.profile:
          await load(
            type,
            _store.getPendingProfileEditIds,
            _store.deletePendingProfileEdit,
            _store.readPendingProfileEdit,
          );
        case SyncEntityType.service:
          await load(
            type,
            _store.getPendingServiceEditIds,
            _store.deletePendingServiceEdit,
            _store.readPendingServiceEdit,
          );
        case SyncEntityType.serviceDelete:
          await load(
            type,
            _store.getPendingServiceDeleteIds,
            _store.deletePendingServiceDelete,
            _store.readPendingServiceDelete,
          );
        case SyncEntityType.chatMessage:
          await load(
            type,
            _store.getPendingMessageIds,
            _store.deletePendingMessage,
            _store.readPendingMessage,
          );
        case SyncEntityType.hiringPost:
          await load(
            type,
            _store.getPendingHiringPostEditIds,
            _store.deletePendingHiringPostEdit,
            _store.readPendingHiringPostEdit,
          );
        case SyncEntityType.hiringPostDelete:
          await load(
            type,
            _store.getPendingHiringPostDeleteIds,
            _store.deletePendingHiringPostDelete,
            _store.readPendingHiringPostDelete,
          );
        case SyncEntityType.application:
          await load(
            type,
            _store.getPendingApplicationIds,
            _store.deletePendingApplication,
            _store.readPendingApplication,
          );
        case SyncEntityType.applicationStatusUpdate:
          await load(
            type,
            _store.getPendingApplicationStatusUpdateIds,
            _store.deletePendingApplicationStatusUpdate,
            _store.readPendingApplicationStatusUpdate,
          );
        case SyncEntityType.favorite:
          await load(
            type,
            _store.getPendingFavoriteIds,
            _store.deletePendingFavorite,
            _store.readPendingFavorite,
          );
      }
    }

    entries.sort((a, b) => a.localUpdatedAt.compareTo(b.localUpdatedAt));
    return entries;
  }

  // ── Process a single entry ────────────────────────────────────────────────

  Future<bool> _processEntry(
    SupabaseClient client,
    SyncQueueEntry entry,
  ) async {
    final isDelete = entry.entityType == SyncEntityType.serviceDelete ||
        entry.entityType == SyncEntityType.hiringPostDelete;

    final isAuthoritative =
        entry.entityType == SyncEntityType.applicationStatusUpdate;

    final isNewLocalItem = entry.entityId.startsWith('local_');

    // Favorites are idempotent — no conflict check needed.
    final isFavorite = entry.entityType == SyncEntityType.favorite;

    if (!isDelete && !isAuthoritative && !isNewLocalItem && !isFavorite) {
      final remoteUpdatedAt = await _fetchRemoteUpdatedAt(client, entry);
      if (remoteUpdatedAt != null &&
          remoteUpdatedAt.toUtc().isAfter(
            entry.localUpdatedAt.toUtc().add(const Duration(seconds: 2)),
          )) {
        await _discardEntry(entry, remoteUpdatedAt);
        return true;
      }
    }

    try {
      await _pushEntry(client, entry);
      await _deleteQueueEntry(entry);

      if (!entry.entityId.startsWith('local_')) {
        _appState.markEntitySynced(entry.entityType, entry.entityId);
      }

      if (entry.entityType == SyncEntityType.applicationStatusUpdate) {
        final statusStr = entry.payload['status'] as String?;
        final updatedAtStr = entry.payload['status_updated_at'] as String?;
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
      if (kDebugMode) debugPrint('[SyncService] Network error: $error');
      await _recordAttemptAndScheduleRetry(entry, error.toString());
      return false; // Stop the pass — no network
    } on TimeoutException catch (error) {
      if (kDebugMode) debugPrint('[SyncService] Timeout: $error');
      await _recordAttemptAndScheduleRetry(entry, error.toString());
      return false;
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[SyncService] Failure for ${entry.entityType.nameValue}: $error',
        );
      }
      await _recordAttemptAndScheduleRetry(entry, error.toString());
      // Non-network errors: continue processing other entries.
      return true;
    }
  }

  // ── Exponential backoff with jitter ───────────────────────────────────────
  //
  // Delay schedule (base): 10s, 30s, 1m, 5m, 15m, 15m, 15m, 15m
  // Jitter: ±20% of base delay, random
  // After kMaxSyncAttempts (8): status = failed_requires_attention

  static final _kBackoffDelays = [
    const Duration(seconds: 10),
    const Duration(seconds: 30),
    const Duration(minutes: 1),
    const Duration(minutes: 5),
    const Duration(minutes: 15),
    const Duration(minutes: 15),
    const Duration(minutes: 15),
    const Duration(minutes: 15),
  ];

  /// Records a failed attempt on [entry] and persists a [nextAttemptAt]
  /// delay. After [kMaxSyncAttempts] moves to [kStatusFailedRequiresAttention].
  Future<void> _recordAttemptAndScheduleRetry(
    SyncQueueEntry entry,
    String error,
  ) async {
    final newCount = entry.attemptCount + 1;

    if (newCount >= kMaxSyncAttempts) {
      final terminal = entry.copyWith(
        syncStatus: kStatusFailedRequiresAttention,
        attemptCount: newCount,
        lastAttemptAt: DateTime.now().toUtc(),
        lastError: error,
      );
      await _updateQueueEntry(terminal);
      // Notify AppState so the UI can surface the count.
      _appState.onSyncEntryRequiresAttention(entry.entityType, entry.entityId);
      if (kDebugMode) {
        debugPrint(
          '[SyncService] Entry ${entry.entityType.nameValue} ${entry.entityId} '
          'requires attention after $newCount attempts.',
        );
      }
      return;
    }

    // Pick base delay for this attempt index (clamp to last bucket).
    final idx = (newCount - 1).clamp(0, _kBackoffDelays.length - 1);
    final base = _kBackoffDelays[idx];

    // Apply ±20% jitter.
    final jitterMs = (base.inMilliseconds * 0.2 *
            (DateTime.now().microsecond / 1000000 * 2 - 1))
        .round();
    final jittered = Duration(
      milliseconds: (base.inMilliseconds + jitterMs).clamp(
        (base.inMilliseconds * 0.8).round(),
        (base.inMilliseconds * 1.2).round(),
      ),
    );

    final nextAt = DateTime.now().toUtc().add(jittered);

    final updated = entry.copyWith(
      syncStatus: kStatusFailed,
      attemptCount: newCount,
      lastAttemptAt: DateTime.now().toUtc(),
      nextAttemptAt: nextAt,
      lastError: error,
    );
    await _updateQueueEntry(updated);
    if (kDebugMode) {
      debugPrint(
        '[SyncService] Entry ${entry.entityType.nameValue} ${entry.entityId} '
        'attempt $newCount/${kMaxSyncAttempts}, retry at $nextAt',
      );
    }
  }

  // ── Remote helpers ────────────────────────────────────────────────────────

  Future<DateTime?> _fetchRemoteUpdatedAt(
    SupabaseClient client,
    SyncQueueEntry entry,
  ) async {
    final table = _tableFor(entry.entityType);
    if (table == null) return null;
    final response = await client
        .from(table)
        .select('updated_at')
        .eq('id', entry.entityId)
        .maybeSingle();

    if (response is! Map<String, dynamic>) return null;
    final raw = response['updated_at'];
    if (raw is! String) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> _pushEntry(SupabaseClient client, SyncQueueEntry entry) async {
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

      case SyncEntityType.profile:
        final p = Map<String, dynamic>.from(entry.payload);
        final exists =
            await _remoteExists(client, 'profiles', entry.entityId);
        if (exists) {
          await client.from('profiles').update(p).eq('id', entry.entityId);
        } else {
          await client.from('profiles').insert(p);
        }

      case SyncEntityType.service:
        final p = Map<String, dynamic>.from(entry.payload);
        if (!isLocalId) p['id'] = entry.entityId;
        final exists =
            !isLocalId && await _remoteExists(client, 'services', entry.entityId);
        if (exists) {
          await client.from('services').update(p).eq('id', entry.entityId);
        } else {
          final row = await client
              .from('services')
              .insert(p)
              .select('id')
              .single();
          final realId = row['id'] as String;
          if (isLocalId) _appState.replaceServiceId(entry.entityId, realId);
        }

      case SyncEntityType.serviceDelete:
        await client.from('services').delete().eq('id', entry.entityId);

      case SyncEntityType.chatMessage:
        final p = Map<String, dynamic>.from(entry.payload);
        if (!isLocalId) p['id'] = entry.entityId;
        final exists =
            !isLocalId && await _remoteExists(client, 'chat_messages', entry.entityId);
        if (exists) {
          await client.from('chat_messages').update(p).eq('id', entry.entityId);
        } else {
          await client.from('chat_messages').insert(p);
        }

      case SyncEntityType.hiringPost:
        final p = Map<String, dynamic>.from(entry.payload);
        if (!isLocalId) p['id'] = entry.entityId;
        final exists =
            !isLocalId && await _remoteExists(client, 'hiring_posts', entry.entityId);
        if (exists) {
          await client.from('hiring_posts').update(p).eq('id', entry.entityId);
        } else {
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

      case SyncEntityType.hiringPostDelete:
        await client.from('hiring_posts').delete().eq('id', entry.entityId);

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

      case SyncEntityType.applicationStatusUpdate:
        await client
            .from('applications')
            .update(entry.payload)
            .eq('id', entry.entityId);

      case SyncEntityType.favorite:
        final listingId = entry.payload['listing_id'] as String;
        final userId    = entry.payload['user_id'] as String;
        final isSaved   = entry.payload['is_saved'] as bool? ?? false;
        if (isSaved) {
          // Upsert so rapid toggling doesn't create duplicates.
          await client.from('favorites').upsert({
            'listing_id': listingId,
            'user_id': userId,
          });
        } else {
          await client
              .from('favorites')
              .delete()
              .eq('listing_id', listingId)
              .eq('user_id', userId);
        }
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

  Future<void> _discardEntry(
    SyncQueueEntry entry,
    DateTime remoteUpdatedAt,
  ) async {
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

  // ── Queue CRUD ────────────────────────────────────────────────────────────

  Future<void> _deleteQueueEntry(SyncQueueEntry entry) async {
    switch (entry.entityType) {
      case SyncEntityType.listing:
        await _store.deleteDraftListing(entry.id);
      case SyncEntityType.profile:
        await _store.deletePendingProfileEdit(entry.id);
      case SyncEntityType.service:
        await _store.deletePendingServiceEdit(entry.id);
      case SyncEntityType.serviceDelete:
        await _store.deletePendingServiceDelete(entry.id);
      case SyncEntityType.chatMessage:
        await _store.deletePendingMessage(entry.id);
      case SyncEntityType.hiringPost:
        await _store.deletePendingHiringPostEdit(entry.id);
      case SyncEntityType.hiringPostDelete:
        await _store.deletePendingHiringPostDelete(entry.id);
      case SyncEntityType.application:
        await _store.deletePendingApplication(entry.id);
      case SyncEntityType.applicationStatusUpdate:
        await _store.deletePendingApplicationStatusUpdate(entry.id);
      case SyncEntityType.favorite:
        await _store.deletePendingFavorite(entry.id);
    }
  }

  Future<void> _updateQueueEntry(SyncQueueEntry entry) async {
    final payload = jsonEncode(entry.toJson());
    switch (entry.entityType) {
      case SyncEntityType.listing:
        await _store.saveDraftListing(entry.id, payload);
      case SyncEntityType.profile:
        await _store.savePendingProfileEdit(entry.id, payload);
      case SyncEntityType.service:
        await _store.savePendingServiceEdit(entry.id, payload);
      case SyncEntityType.serviceDelete:
        await _store.savePendingServiceDelete(entry.id, payload);
      case SyncEntityType.chatMessage:
        await _store.savePendingMessage(entry.id, payload);
      case SyncEntityType.hiringPost:
        await _store.savePendingHiringPostEdit(entry.id, payload);
      case SyncEntityType.hiringPostDelete:
        await _store.savePendingHiringPostDelete(entry.id, payload);
      case SyncEntityType.application:
        await _store.savePendingApplication(entry.id, payload);
      case SyncEntityType.applicationStatusUpdate:
        await _store.savePendingApplicationStatusUpdate(entry.id, payload);
      case SyncEntityType.favorite:
        await _store.savePendingFavorite(entry.id, payload);
    }
  }

  String? _tableFor(SyncEntityType entityType) {
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
      case SyncEntityType.favorite:
        return null; // favorites use composite key — no single-row conflict check
    }
  }
}
