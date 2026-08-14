part of '../sync_service.dart';

// ── Enqueue helpers ──────────────────────────────────────────────────────────────

extension SyncServiceEnqueuehelpers on SyncService {
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
      syncStatus: kStatusPending,
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
      syncStatus: kStatusPending,
    );
    await _store.savePendingServiceEdit(serviceId, jsonEncode(entry.toJson()));
    requestSync();
  }

  Future<void> enqueueServiceDelete({required String serviceId}) async {
    await _store.initialize();
    final now = DateTime.now().toUtc();
    final entry = SyncQueueEntry(
      id: serviceId,
      entityType: SyncEntityType.serviceDelete,
      entityId: serviceId,
      payload: {'deleted_at': now.toIso8601String()},
      localUpdatedAt: now,
      syncStatus: kStatusPending,
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
      syncStatus: kStatusPending,
    );
    await _store.savePendingHiringPostEdit(
      postId,
      jsonEncode(entry.toJson()),
    );
    requestSync();
  }

  Future<void> enqueueHiringPostDelete({required String postId}) async {
    await _store.initialize();
    final now = DateTime.now().toUtc();
    final entry = SyncQueueEntry(
      id: postId,
      entityType: SyncEntityType.hiringPostDelete,
      entityId: postId,
      payload: {'deleted_at': now.toIso8601String()},
      localUpdatedAt: now,
      syncStatus: kStatusPending,
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
      syncStatus: kStatusPending,
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
      syncStatus: kStatusPending,
    );
    await _store.savePendingApplicationStatusUpdate(
      applicationId,
      jsonEncode(entry.toJson()),
    );
    requestSync();
  }

  // ── Favorite toggle queue helper ─────────────────────────────────────────────
  //
  // Favorites are idempotent: only the latest intent for a given listingId
  // matters. Enqueueing a new intent overwrites the previous one (same key =
  // listingId) so rapid on/off toggles collapse to a single write.

  Future<void> enqueueFavoriteToggle({
    required String listingId,
    required bool isSaved,          // true = add, false = remove
    required String userId,
    required DateTime localUpdatedAt,
  }) async {
    await _store.initialize();
    final entry = SyncQueueEntry(
      id: listingId,
      entityType: SyncEntityType.favorite,
      entityId: listingId,
      payload: {
        'listing_id': listingId,
        'user_id': userId,
        'is_saved': isSaved,
      },
      localUpdatedAt: localUpdatedAt,
      syncStatus: kStatusPending,
    );
    await _store.savePendingFavorite(listingId, jsonEncode(entry.toJson()));
    requestSync();
  }

}
