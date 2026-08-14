// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Services & recommendations ────────────────────────────────────────────────

extension AppStateServices on KoolanAppState {
  // ── Recommendation helpers ────────────────────────────────────────────────────

  /// Records that the user navigated to an item detail screen.
  /// In-memory only — resets on app restart.
  void recordItemViewed(String id) {
    recentlyViewedIds.add(id);
    // No notifyListeners() — background signal, not UI state.
  }

  /// Builds a [UserContext] snapshot from the current app state.
  UserContext buildUserContext() {
    final rawGoal = onboardingGoal ?? profile?.preferredCategory;
    final category = UserContext.categoryFromGoal(rawGoal);

    final savedIds = allListings
        .where((l) => l.isSaved)
        .map((l) => l.id)
        .toSet();

    final appliedIds = myApplications
        .map((a) => a.hiringPostId)
        .toSet();

    final hasGps = deviceLat != null && deviceLng != null;
    final hasCity = profile?.city?.isNotEmpty ?? false;

    return UserContext(
      preferredCategory: category,
      userLocation: profile?.city,
      userLat: deviceLat,
      userLng: deviceLng,
      hasLocation: hasGps || (locationPermissionGranted && hasCity),
      savedIds: savedIds,
      appliedPostIds: appliedIds,
      recentlyViewedIds: Set.unmodifiable(recentlyViewedIds),
    );
  }

  // ── Service helpers ───────────────────────────────────────────────────────────

  Listing? getListingById(String id) {
    try {
      return allListings.firstWhere((listing) => listing.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Service> getMyServices() {
    final userId = currentUser?.id;
    if (userId == null) return [];
    return allServices.where((service) => service.ownerId == userId).toList();
  }

  Service? getServiceById(String id) {
    try {
      return allServices.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Service CRUD ──────────────────────────────────────────────────────────────

  Future<String> submitServiceEdit(
    Service service, {
    /// New local file paths to upload (multi-image).
    List<String> newImagePaths = const [],
    /// Already-uploaded URLs to keep (multi-image).
    List<String> existingImageUrls = const [],
    // Legacy single-image path — kept for backward compat.
    String? newImagePath,
  }) async {
    if (currentUser == null) return service.id;

    final now = DateTime.now();
    final isNew = service.id.startsWith('local_');
    final userId = currentUser!.id;

    final allNewPaths = [
      if (newImagePath != null) newImagePath,
      ...newImagePaths,
    ];

    final uploadedUrls = <String>[];
    for (int i = 0; i < allNewPaths.length; i++) {
      final file = File(allNewPaths[i]);
      if (!await file.exists()) continue;
      final result = await CloudinaryUploadService.instance.uploadListingImage(
        imageFile: file,
        userId: userId,
        listingId: service.id,
        index: existingImageUrls.length + i,
      );
      if (result is CloudinaryUploadSuccess) {
        uploadedUrls.add(result.secureUrl);
      }
    }

    final mergedUrls = [...existingImageUrls, ...uploadedUrls];
    final primaryUrl = mergedUrls.isNotEmpty ? mergedUrls.first : service.imageUrl;

    final updated = service.copyWith(
      imageUrl: primaryUrl,
      imageUrls: mergedUrls,
      syncStatus: SyncStatus.pending,
      localUpdatedAt: now,
    );

    final existingIndex = allServices.indexWhere((s) => s.id == updated.id);
    if (existingIndex == -1) {
      allServices.add(updated);
    } else {
      allServices[existingIndex] = updated;
    }
    notifyListeners();

    final fields = {
      'owner_id': updated.ownerId,
      'title': updated.title,
      'category': updated.category,
      'description': updated.description,
      'cover_description': updated.coverDescription,
      'cv_file_url': updated.cvFileUrl,
      'years_of_experience': updated.yearsOfExperience,
      'price_range': updated.priceRange,
      'location': updated.location,
      'availability': updated.availability,
      'image_url': updated.imageUrl,
      'image_urls': updated.imageUrls,
      'created_at': updated.createdAt.toIso8601String(),
    };

    String resolvedId = updated.id;

    try {
      if (isNew) {
        final realId = await _repo!.insertService(fields);
        final idx = allServices.indexWhere((s) => s.id == updated.id);
        if (idx != -1) {
          allServices[idx] = allServices[idx].copyWith(
            id: realId,
            syncStatus: SyncStatus.synced,
          );
        }
        resolvedId = realId;
        await CvUploadService.instance.rekeyPendingUpload(updated.id, realId);
      } else {
        await _repo!.updateService(updated.id, fields);
        final idx = allServices.indexWhere((s) => s.id == updated.id);
        if (idx != -1) {
          allServices[idx] = allServices[idx].copyWith(
            syncStatus: SyncStatus.synced,
          );
        }
      }
    } catch (e) {
      final idx = allServices.indexWhere((s) => s.id == updated.id);
      if (idx != -1) {
        allServices[idx] = allServices[idx].copyWith(
          syncStatus: SyncStatus.failed,
        );
      }
      reportDataError(e);
    }
    notifyListeners();
    return resolvedId;
  }

  /// Called by SyncService to flush queued CV uploads when back online.
  Future<void> flushPendingCvUploads() async {
    await CvUploadService.instance.flushPendingUploads(
      onUploaded: (serviceId, remoteUrl) async {
        var idx = allServices.indexWhere((s) => s.id == serviceId);
        if (idx == -1) return;
        allServices[idx] = allServices[idx].copyWith(cvFileUrl: remoteUrl);
        notifyListeners();
        try {
          await _repo?.updateService(allServices[idx].id, {
            'cv_file_url': remoteUrl,
          });
        } catch (e) {
          if (kDebugMode) debugPrint('[CvUpload] failed to persist URL for $serviceId: $e');
        }
      },
    );
  }

  /// Called by SyncService after each sync pass completes.
  /// Updates [lastSuccessfulSyncAt] and [syncObservability] for the observability model.
  void onSyncPassComplete({
    required Duration duration,
    required bool hadNetworkError,
  }) {
    if (!hadNetworkError) {
      lastSuccessfulSyncAt = DateTime.now();
      syncObservability.recordSuccess(duration: duration);
    } else {
      syncObservability.recordAttempt();
    }
    unawaited(refreshSyncQueueCounts());
    notifyListeners();
  }

  /// Called by SyncService when an entry reaches [kStatusFailedRequiresAttention].
  void onSyncEntryRequiresAttention(SyncEntityType type, String entityId) {
    unawaited(refreshSyncQueueCounts());
    notifyListeners();
    if (kDebugMode) {
      debugPrint(
        '[AppState] Sync entry requires attention: ${type.nameValue} $entityId',
      );
    }
  }

  /// Re-counts pending / failed_requires_attention entries in the Hive queue.
  Future<void> refreshSyncQueueCounts() async {
    try {
      await HiveSyncStore.instance.initialize();
      final stats = await HiveSyncStore.instance.countOutboundQueueStats();
      syncObservability.setQueueCounts(
        pending: stats.pending,
        requiresAttention: stats.requiresAttention,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AppState] refreshSyncQueueCounts failed: $e');
    }
  }

  /// Called by SyncService after a successful push for an existing item.
  void markEntitySynced(SyncEntityType type, String id) {
    switch (type) {
      case SyncEntityType.service:
        final idx = allServices.indexWhere((s) => s.id == id);
        if (idx != -1) {
          allServices[idx] =
              allServices[idx].copyWith(syncStatus: SyncStatus.synced);
          notifyListeners();
        }
        break;
      case SyncEntityType.hiringPost:
        final idx = allHiringPosts.indexWhere((p) => p.id == id);
        if (idx != -1) {
          allHiringPosts[idx] =
              allHiringPosts[idx].copyWith(syncStatus: SyncStatus.synced);
          notifyListeners();
        }
        break;
      default:
        break;
    }
  }

  /// Called by SyncService after a new service is inserted into Supabase.
  void replaceServiceId(String localId, String realId) {
    final idx = allServices.indexWhere((s) => s.id == localId);
    if (idx == -1) return;
    allServices[idx] = allServices[idx].copyWith(
      id: realId,
      syncStatus: SyncStatus.synced,
    );
    notifyListeners();
    unawaited(CvUploadService.instance.rekeyPendingUpload(localId, realId));
  }

  /// Called by SyncService after a new hiring post is inserted into Supabase.
  void replaceHiringPostId(String localId, String realId) {
    final idx = allHiringPosts.indexWhere((p) => p.id == localId);
    if (idx == -1) return;
    allHiringPosts[idx] = allHiringPosts[idx].copyWith(
      id: realId,
      syncStatus: SyncStatus.synced,
    );
    notifyListeners();
  }

  Future<void> deleteService(String id) async {
    final index = allServices.indexWhere((s) => s.id == id);
    if (index == -1) return;
    allServices.removeAt(index);
    notifyListeners();
    try {
      await _repo?.deleteService(id);
    } catch (e) {
      reportDataError(e);
      notifyListeners();
    }
  }

  Future<void> toggleServiceAvailability(String id, bool available) async {
    final index = allServices.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final updated = allServices[index].copyWith(
      availability: available,
      syncStatus: SyncStatus.pending,
      localUpdatedAt: DateTime.now(),
    );
    allServices[index] = updated;
    notifyListeners();
    try {
      await _repo!.updateService(updated.id, {'availability': available});
      allServices[index] = updated.copyWith(syncStatus: SyncStatus.synced);
    } catch (e) {
      allServices[index] = updated.copyWith(syncStatus: SyncStatus.failed);
      reportDataError(e);
    }
    notifyListeners();
  }
}
