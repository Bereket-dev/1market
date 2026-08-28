// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Profile ───────────────────────────────────────────────────────────────────

extension AppStateProfile on OnemarketAppState {
  /// Writes a profile update directly to Supabase and updates local state.
  Future<void> submitProfileUpdate({
    required String displayName,
    required String bio,
    required String phone,
    required String city,
    String? preferredCategory,
  }) async {
    final current = profile;
    if (current == null) return;

    // Optimistic local update immediately.
    profile = current.copyWith(
      displayName: displayName,
      bio: bio,
      phone: phone,
      city: city,
      preferredCategory: preferredCategory ?? current.preferredCategory,
      syncStatus: SyncStatus.pending,
      localUpdatedAt: DateTime.now().toUtc(),
    );
    notifyListeners();

    final fields = <String, dynamic>{
      'display_name': displayName,
      'bio': bio,
      'phone': phone,
      'city': city,
    };
    if (preferredCategory != null) {
      fields['preferred_category'] = preferredCategory;
      // Persist to device so it survives logout.
      await app_local.LocalStorage.savePreferredCategory(preferredCategory);
    }

    try {
      await _repo?.updateProfile(fields);
      profile = profile?.copyWith(syncStatus: SyncStatus.synced);
      notifyListeners();
    } catch (e) {
      profile = profile?.copyWith(syncStatus: SyncStatus.failed);
      reportDataError(e);
      notifyListeners();
      rethrow; // Let callers (EditProfileScreen._save) show the error to the user.
    }
  }

  // ── Profile image uploads ─────────────────────────────────────────────────

  /// Maximum profile/banner image size: 5 MB.
  static const _photoMaxBytes = 5 * 1024 * 1024;

  /// Lets the user pick an image from their gallery and uploads it as their
  /// profile avatar. Updates [profile.avatarUrl] optimistically on success.
  Future<String?> uploadAvatarImage() async {
    return _pickAndUploadProfileImage(
      imageType: CloudinaryImageType.avatar,
      onSuccess: (url) async {
        profile = profile?.copyWith(avatarUrl: url);
        await _syncProfileField('avatar_url', url);
      },
    );
  }

  /// Lets the user pick an image from their gallery and uploads it as their
  /// profile banner. Updates [profile.bannerUrl] optimistically on success.
  Future<String?> uploadBannerImage() async {
    return _pickAndUploadProfileImage(
      imageType: CloudinaryImageType.banner,
      onSuccess: (url) async {
        profile = profile?.copyWith(bannerUrl: url);
        await _syncProfileField('banner_url', url);
      },
    );
  }

  Future<String?> _pickAndUploadProfileImage({
    required CloudinaryImageType imageType,
    required Future<void> Function(String secureUrl) onSuccess,
  }) async {
    final current = profile;
    if (current == null) return s.errorUnauthorized;

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false,
        withReadStream: false,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[PhotoUpload] picker error: $e');
      unawaited(ErrorReporter.recordError(e, st, reason: 'photo_pick'));
      return s.editProfilePhotoError;
    }

    if (result == null || result.files.isEmpty) return null;

    final localPath = result.files.first.path;
    if (localPath == null) return s.editProfilePhotoError;

    final file = File(localPath);
    int fileSize;
    try {
      fileSize = await file.length();
    } catch (e) {
      fileSize = result.files.first.size;
    }
    if (fileSize > _photoMaxBytes) {
      return s.servicesCvTooLarge;
    }

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id ?? current.id;

    if (client.auth.currentSession != null) {
      final uploadResult = await CloudinaryUploadService.instance.upload(
        imageFile: file,
        type: imageType,
        userId: userId,
      );

      switch (uploadResult) {
        case CloudinaryUploadSuccess(:final secureUrl):
          await onSuccess(secureUrl);
          notifyListeners();
          return null;

        case CloudinaryUploadFailure(:final code):
          if (code == CloudinaryFailureCode.network) {
            if (kDebugMode) {
              debugPrint('[PhotoUpload] network error, queueing');
            }
            break;
          }
          if (kDebugMode) debugPrint('[PhotoUpload] cloudinary error: $code');
          return switch (code) {
            CloudinaryFailureCode.unauthorized => s.errorUnauthorized,
            CloudinaryFailureCode.notConfigured => s.errorSupabaseUnavailable,
            CloudinaryFailureCode.network => s.errorNetwork,
            _ => s.errorUnknown,
          };
      }
    }

    await _queuePhotoUpload(
      userId: userId,
      imageType: imageType,
      localPath: localPath,
    );
    return null;
  }

  Future<void> _queuePhotoUpload({
    required String userId,
    required CloudinaryImageType imageType,
    required String localPath,
  }) async {
    final store = HiveSyncStore.instance;
    await store.initialize();
    final typeStr =
        imageType == CloudinaryImageType.avatar ? 'avatar' : 'banner';
    final key = '$userId:$typeStr';
    final payload = jsonEncode({
      'userId': userId,
      'imageType': typeStr,
      'localPath': localPath,
    });
    await store.savePendingPhotoUpload(key, payload);
    if (kDebugMode) debugPrint('[PhotoUpload] queued for later: $key');
  }

  /// Called by SyncService to flush any queued photo uploads when back online.
  Future<void> flushPendingPhotoUploads() async {
    final store = HiveSyncStore.instance;
    await store.initialize();
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) return;

    final keys = await store.getPendingPhotoUploadKeys();
    for (final key in keys) {
      final raw = store.readPendingPhotoUpload(key);
      if (raw == null) continue;
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final userId = data['userId'] as String;
        final localPath = data['localPath'] as String;

        final CloudinaryImageType imageType;
        if (data.containsKey('imageType')) {
          imageType = data['imageType'] == 'avatar'
              ? CloudinaryImageType.avatar
              : CloudinaryImageType.banner;
        } else {
          final bucket = data['bucket'] as String? ?? '';
          imageType = bucket.contains('avatar')
              ? CloudinaryImageType.avatar
              : CloudinaryImageType.banner;
        }

        final file = File(localPath);
        if (!await file.exists()) {
          await store.deletePendingPhotoUpload(key);
          continue;
        }

        final uploadResult = await CloudinaryUploadService.instance.upload(
          imageFile: file,
          type: imageType,
          userId: userId,
        );

        switch (uploadResult) {
          case CloudinaryUploadSuccess(:final secureUrl):
            if (imageType == CloudinaryImageType.avatar) {
              profile = profile?.copyWith(avatarUrl: secureUrl);
              await _syncProfileField('avatar_url', secureUrl);
            } else {
              profile = profile?.copyWith(bannerUrl: secureUrl);
              await _syncProfileField('banner_url', secureUrl);
            }
            notifyListeners();
            await store.deletePendingPhotoUpload(key);
            if (kDebugMode) {
              debugPrint('[PhotoUpload] flushed: $key → $secureUrl');
            }

          case CloudinaryUploadFailure(:final code):
            if (kDebugMode) {
              debugPrint('[PhotoUpload] flush failed for $key: $code');
            }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[PhotoUpload] flush error for $key: $e');
      }
    }
  }

  Future<void> _syncProfileField(String column, String value) async {
    if (profile == null) return;
    try {
      await _repo?.updateProfile({column: value});
      if (kDebugMode) {
        debugPrint('[ProfileSync] $column updated in Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProfileSync] direct update failed ($column): $e');
      }
      reportDataError(e);
      notifyListeners();
    }
  }

  // ── Locale ────────────────────────────────────────────────────────────────────

  Future<void> setLocale(String newLocale) async {
    locale = newLocale;
    await app_local.LocalStorage.saveLanguage(newLocale);
    profile = profile?.copyWith(language: newLocale, syncStatus: SyncStatus.pending);
    notifyListeners();
    if (isSignedIn && _repo != null) {
      try {
        await _repo!.updateLanguage(newLocale);
        profile = profile?.copyWith(syncStatus: SyncStatus.synced);
      } catch (e) {
        profile = profile?.copyWith(syncStatus: SyncStatus.failed);
        reportDataError(e);
      }
      notifyListeners();
    }
  }

  /// Cycles EN → Amharic → Somali (used by the home language pill).
  Future<void> toggleLocale() async {
    final next = switch (locale) {
      'en' => 'am',
      'am' => 'so',
      _ => 'en',
    };
    await setLocale(next);
  }

  // ── Theme ─────────────────────────────────────────────────────────────────────

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    app_local.LocalStorage.saveDarkMode(isDarkMode);
    notifyListeners();
  }

  // ── Notification preferences ──────────────────────────────────────────────────

  /// Reconcile app prefs with OS permission (e.g. after returning from Settings).
  ///
  /// When the device is offline we skip any FCM token operations entirely.
  /// FCM.getToken() hangs or throws when there is no network, which would
  /// either time-out the resume callback or — worse — set notifPushEnabled=false
  /// and persist that, creating a permission-prompt loop on every cold start.
  Future<void> refreshNotificationPermissionState() async {
    // Skip all FCM network calls when offline. The channels and OS permission
    // state are purely local and can still be reconciled, but we must not call
    // FirebaseMessaging.getToken() or deleteToken() without connectivity.
    final isOffline = NetworkMonitor.instance.isOffline;

    final osGranted = await PermissionService.isNotificationPermissionGranted();

    if (!osGranted) {
      if (notifPushEnabled) {
        notifPushEnabled = false;
        await app_local.LocalStorage.saveNotifPushEnabled(false);
      }
      // Only attempt to deregister the FCM token when we are online — the
      // deleteToken() call will fail silently offline and we don't want to
      // put the device into a bad state.
      if (!isOffline) {
        await _unregisterPushToken();
      }
      notifyListeners();
      return;
    }

    if (notifPushEnabled) {
      await PermissionService.setAndroidChannelsEnabled(
        pushEnabled: true,
        messagesEnabled: notifMessagesEnabled,
      );
      // Only refresh the FCM token when online — avoids getToken() failures
      // that reset notifPushEnabled to false on every offline resume.
      if (!isOffline) {
        await _registerPushToken();
      }
    } else {
      await PermissionService.setMessageNotificationsEnabled(
        notifMessagesEnabled,
      );
    }
  }

  /// Returns [NotifPushToggleResult.permissionDenied] when the OS blocks alerts.
  /// When disabling, opens the system notification settings screen.
  Future<NotifPushToggleResult> toggleNotifPush(bool value) async {
    if (value) {
      final token = await PermissionService.enablePushOnDevice(
        messagesEnabled: notifMessagesEnabled,
      );
      if (token == null) {
        notifPushEnabled = false;
        await app_local.LocalStorage.saveNotifPushEnabled(false);
        notifyListeners();
        return NotifPushToggleResult.permissionDenied;
      }

      notifPushEnabled = true;
      await app_local.LocalStorage.saveNotifPushEnabled(true);
      notifyListeners();

      if (_repo != null) {
        try {
          await _repo!.updateProfile({
            'fcm_token': token,
            'notif_push_enabled': true,
          });
        } catch (e) {
          if (kDebugMode) debugPrint('[FCM] save token on enable failed: $e');
        }
      }
      return NotifPushToggleResult.enabled;
    }

    notifPushEnabled = false;
    await app_local.LocalStorage.saveNotifPushEnabled(false);
    notifyListeners();
    await _unregisterPushToken();
    await PermissionService.openNotificationSettings();
    return NotifPushToggleResult.disabled;
  }

  Future<void> toggleNotifMessages(bool value) async {
    notifMessagesEnabled = value;
    await app_local.LocalStorage.saveNotifMessagesEnabled(value);
    profile = profile?.copyWith(notifMessagesEnabled: value);
    notifyListeners();

    await PermissionService.setMessageNotificationsEnabled(value);

    if (_repo != null) {
      try {
        await _repo!.updateProfile({'notif_messages_enabled': value});
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[FCM] save notif_messages_enabled failed: $e');
        }
      }
    }
  }

  Future<void> openNotificationSettings() =>
      PermissionService.openNotificationSettings();

  void toggleNotifPriceAlerts(bool value) {
    notifPriceAlerts = value;
    app_local.LocalStorage.saveNotifPriceAlerts(value);
    notifyListeners();
  }
}
