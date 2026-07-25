// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Hiring posts, applications & notifications ────────────────────────────────

extension AppStateHiring on KoolanAppState {
  // ── Hiring post helpers ───────────────────────────────────────────────────────

  List<HiringPost> getMyHiringPosts() {
    final userId = currentUser?.id;
    if (userId == null) return [];
    return allHiringPosts.where((p) => p.posterId == userId).toList();
  }

  List<HiringPost> getBrowsableHiringPosts() =>
      allHiringPosts.where((p) => p.isOpen).toList();

  HiringPost? getHiringPostById(String id) {
    try {
      return allHiringPosts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Updates the in-memory applicant count badge on a hiring post.
  void updateHiringPostApplicantCount(String postId, int count) {
    final idx = allHiringPosts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    allHiringPosts[idx] =
        allHiringPosts[idx].copyWith(applicantCount: count);
    notifyListeners();
  }

  // ── Hiring post CRUD ──────────────────────────────────────────────────────────

  Future<String> submitHiringPostEdit(
    HiringPost post, {
    List<String> newImagePaths = const [],
    List<String> existingImageUrls = const [],
  }) async {
    if (currentUser == null) return post.id;

    final now = DateTime.now();
    final isNew = post.id.startsWith('local_');
    final userId = currentUser!.id;

    final uploadedUrls = <String>[];
    for (int i = 0; i < newImagePaths.length; i++) {
      final file = File(newImagePaths[i]);
      if (!await file.exists()) continue;
      final result = await CloudinaryUploadService.instance.uploadListingImage(
        imageFile: file,
        userId: userId,
        listingId: post.id,
        index: existingImageUrls.length + i,
      );
      if (result is CloudinaryUploadSuccess) {
        uploadedUrls.add(result.secureUrl);
      }
    }

    final mergedUrls = [...existingImageUrls, ...uploadedUrls];
    final imageUrl =
        mergedUrls.isNotEmpty ? mergedUrls.first : post.imageUrl;

    final updated = post.copyWith(
      imageUrl: imageUrl,
      imageUrls: mergedUrls,
      syncStatus: SyncStatus.pending,
      localUpdatedAt: now,
    );

    final existingIndex = allHiringPosts.indexWhere((p) => p.id == updated.id);
    if (existingIndex == -1) {
      allHiringPosts.add(updated);
    } else {
      allHiringPosts[existingIndex] = updated;
    }
    notifyListeners();

    final fields = {
      'poster_id': updated.posterId,
      'title': updated.title,
      'description': updated.description,
      'category': updated.category,
      'location': updated.location,
      'price_range': updated.priceRange,
      'status': updated.status,
      'image_url': updated.imageUrl,
      'image_urls': updated.imageUrls,
      'created_at': updated.createdAt.toIso8601String(),
    };

    String resolvedId = updated.id;

    try {
      if (isNew) {
        final realId = await _repo!.insertHiringPost(fields);
        final idx = allHiringPosts.indexWhere((p) => p.id == updated.id);
        if (idx != -1) {
          allHiringPosts[idx] = allHiringPosts[idx].copyWith(
            id: realId,
            syncStatus: SyncStatus.synced,
          );
        }
        resolvedId = realId;
      } else {
        await _repo!.updateHiringPost(updated.id, fields);
        final idx = allHiringPosts.indexWhere((p) => p.id == updated.id);
        if (idx != -1) {
          allHiringPosts[idx] = allHiringPosts[idx].copyWith(
            syncStatus: SyncStatus.synced,
          );
        }
      }
    } catch (e) {
      final idx = allHiringPosts.indexWhere((p) => p.id == updated.id);
      if (idx != -1) {
        allHiringPosts[idx] = allHiringPosts[idx].copyWith(
          syncStatus: SyncStatus.failed,
        );
      }
      dataError = e.toString();
    }
    notifyListeners();
    return resolvedId;
  }

  Future<void> deleteHiringPost(String id) async {
    allHiringPosts.removeWhere((p) => p.id == id);
    notifyListeners();
    try {
      await _repo?.deleteHiringPost(id);
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleHiringPostStatus(String id, String newStatus) async {
    final index = allHiringPosts.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final updated = allHiringPosts[index].copyWith(
      status: newStatus,
      syncStatus: SyncStatus.pending,
      localUpdatedAt: DateTime.now(),
    );
    allHiringPosts[index] = updated;
    notifyListeners();
    try {
      await _repo!.updateHiringPost(updated.id, {'status': newStatus});
      allHiringPosts[index] = updated.copyWith(syncStatus: SyncStatus.synced);
    } catch (e) {
      allHiringPosts[index] = updated.copyWith(syncStatus: SyncStatus.failed);
      dataError = e.toString();
    }
    notifyListeners();
  }

  // ── Applications ──────────────────────────────────────────────────────────────

  List<Application> getApplicationsForPost(String hiringPostId) =>
      _applicantsCache[hiringPostId] ?? [];

  Future<List<Application>> loadApplicationsForPost(
    String hiringPostId,
  ) async {
    if (_repo == null) return [];
    try {
      final apps = await _repo!.fetchApplicationsForPost(hiringPostId);
      _applicantsCache[hiringPostId] = apps;
      notifyListeners();
      return apps;
    } catch (e) {
      debugPrint('loadApplicationsForPost error: $e');
      return _applicantsCache[hiringPostId] ?? [];
    }
  }

  /// Returns the applicant's own applications grouped by serviceId.
  Map<String, List<Application>> getMyApplicationsGroupedByService() {
    final result = <String, List<Application>>{};
    for (final app in myApplications) {
      result.putIfAbsent(app.serviceId, () => []).add(app);
    }
    return result;
  }

  /// Submits an application (applicant action). Writes directly to Supabase.
  Future<void> submitApplication({
    required String hiringPostId,
    required String serviceId,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now();
    final tempId = 'local_${now.millisecondsSinceEpoch}';

    final application = Application(
      id: tempId,
      hiringPostId: hiringPostId,
      applicantId: userId,
      serviceId: serviceId,
      status: ApplicationStatus.submitted,
      submittedAt: now,
      localUpdatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    myApplications.add(application);
    notifyListeners();

    try {
      final realId = await _repo!.insertApplication({
        'hiring_post_id': hiringPostId,
        'applicant_id': userId,
        'service_id': serviceId,
        'status': 'submitted',
        'submitted_at': now.toIso8601String(),
      });
      final idx = myApplications.indexWhere((a) => a.id == tempId);
      if (idx != -1) {
        myApplications[idx] = application.copyWith(
          id: realId,
          syncStatus: SyncStatus.synced,
        );
      }
      unawaited(_notifyNewApplication(
        hiringPostId: hiringPostId,
        application: myApplications[idx < 0 ? myApplications.length - 1 : idx],
      ));
    } catch (e) {
      final idx = myApplications.indexWhere((a) => a.id == tempId);
      if (idx != -1) {
        myApplications[idx] = application.copyWith(
          syncStatus: SyncStatus.failed,
        );
      }
      dataError = e.toString();
    }
    notifyListeners();
  }

  /// Updates application status (poster action). Writes directly to Supabase.
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String hiringPostId,
    required ApplicationStatus newStatus,
  }) async {
    final now = DateTime.now();

    final postApps = _applicantsCache[hiringPostId];
    if (postApps != null) {
      final idx = postApps.indexWhere((a) => a.id == applicationId);
      if (idx != -1) {
        postApps[idx] = postApps[idx].copyWith(
          status: newStatus,
          statusUpdatedAt: now,
          syncStatus: SyncStatus.pending,
        );
        notifyListeners();
      }
    }

    try {
      await _repo!.updateApplicationStatus(
        applicationId: applicationId,
        newStatus: newStatus.name,
      );
      final postApps2 = _applicantsCache[hiringPostId];
      if (postApps2 != null) {
        final idx = postApps2.indexWhere((a) => a.id == applicationId);
        if (idx != -1) {
          postApps2[idx] = postApps2[idx].copyWith(
            syncStatus: SyncStatus.synced,
          );
        }
      }
      onApplicationStatusSynced(
        applicationId: applicationId,
        newStatus: newStatus,
        statusUpdatedAt: now,
      );
      unawaited(_notifyStatusChanged(
        applicationId: applicationId,
        hiringPostId: hiringPostId,
        newStatus: newStatus,
      ));
    } catch (e) {
      final postApps2 = _applicantsCache[hiringPostId];
      if (postApps2 != null) {
        final idx = postApps2.indexWhere((a) => a.id == applicationId);
        if (idx != -1) {
          postApps2[idx] = postApps2[idx].copyWith(
            syncStatus: SyncStatus.failed,
          );
        }
      }
      dataError = e.toString();
      notifyListeners();
    }
    notifyListeners();
  }

  void onApplicationStatusSynced({
    required String applicationId,
    required ApplicationStatus newStatus,
    required DateTime statusUpdatedAt,
  }) {
    final idx = myApplications.indexWhere((a) => a.id == applicationId);
    if (idx != -1) {
      myApplications[idx] = myApplications[idx].copyWith(
        status: newStatus,
        statusUpdatedAt: statusUpdatedAt,
        syncStatus: SyncStatus.synced,
      );
      notifyListeners();
    }
    for (final postApps in _applicantsCache.values) {
      final cidx = postApps.indexWhere((a) => a.id == applicationId);
      if (cidx != -1) {
        postApps[cidx] = postApps[cidx].copyWith(
          status: newStatus,
          statusUpdatedAt: statusUpdatedAt,
          syncStatus: SyncStatus.synced,
        );
      }
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────────

  int get unreadNotificationCount =>
      notifications.where((n) => n['is_read'] != true).length;

  Future<void> markNotificationRead(String notificationId) async {
    final idx = notifications.indexWhere((n) => n['id'] == notificationId);
    if (idx != -1) {
      notifications[idx] = Map<String, dynamic>.from(notifications[idx])
        ..['is_read'] = true;
      notifyListeners();
    }
    try {
      await _repo?.markNotificationRead(notificationId);
    } catch (e) {
      debugPrint('markNotificationRead error: $e');
    }
  }

  Future<void> _notifyNewApplication({
    required String hiringPostId,
    required Application application,
  }) async {
    if (_repo == null) return;
    try {
      final post = getHiringPostById(hiringPostId);
      if (post == null) return;
      await _repo!.insertNotification(
        recipientUserId: post.posterId,
        type: 'new_application',
        title: s.notificationNewApplication,
        body: post.title,
        payload: {
          'hiringPostId': hiringPostId,
          'applicationId': application.id,
          'screen': 'applicantList',
        },
      );
      if (post.posterId == currentUser?.id) {
        notifications = await _repo!.fetchNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('_notifyNewApplication error: $e');
    }
  }

  Future<void> _notifyStatusChanged({
    required String applicationId,
    required String hiringPostId,
    required ApplicationStatus newStatus,
  }) async {
    if (_repo == null) return;
    try {
      final postApps = _applicantsCache[hiringPostId] ?? [];
      final app = postApps.firstWhere(
        (a) => a.id == applicationId,
        orElse: () => Application(
          id: applicationId,
          hiringPostId: hiringPostId,
          applicantId: '',
          serviceId: '',
        ),
      );
      if (app.applicantId.isEmpty) return;
      final post = getHiringPostById(hiringPostId);
      await _repo!.insertNotification(
        recipientUserId: app.applicantId,
        type: 'status_changed',
        title: s.notificationStatusChanged,
        body: post?.title ?? '',
        payload: {
          'applicationId': applicationId,
          'hiringPostId': hiringPostId,
          'serviceId': app.serviceId,
          'status': newStatus.name,
          'screen': 'myApplications',
        },
      );
      if (app.applicantId == currentUser?.id) {
        notifications = await _repo!.fetchNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('_notifyStatusChanged error: $e');
    }
  }
}
