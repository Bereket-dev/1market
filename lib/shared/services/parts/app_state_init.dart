// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Initialization & Onboarding ───────────────────────────────────────────────

extension AppStateInit on KoolanAppState {
  Future<void> _initialize() async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) debugPrint('[AUTH] _initialize started at ${t0}ms');
    initError = null;
    try {
      final savedLang = await app_local.LocalStorage.getLanguage();
      if (savedLang != null) locale = savedLang;

      final savedDark = await app_local.LocalStorage.getDarkMode();
      if (savedDark != null) isDarkMode = savedDark;

      // Restore preferred category so recommendations work even when logged out.
      final savedCategory = await app_local.LocalStorage.getPreferredCategory();
      if (savedCategory != null) onboardingGoal = savedCategory;

      // Restore notification preferences.
      notifPushEnabled     = await app_local.LocalStorage.getNotifPushEnabled();
      notifMessagesEnabled = await app_local.LocalStorage.getNotifMessagesEnabled();
      notifPriceAlerts     = await app_local.LocalStorage.getNotifPriceAlerts();

      // Wait for Supabase to confirm the auth state (initialSession event).
      await _sessionReadyCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
            '[AUTH] initialSession timed out after '
            '${DateTime.now().millisecondsSinceEpoch - t0}ms — proceeding with current state',
            );
          }
          return null;
        },
      );
      if (kDebugMode) {
        debugPrint(
        '[AUTH] session ready after ${DateTime.now().millisecondsSinceEpoch - t0}ms',
        );
      }
      if (kDebugMode) debugPrint('Repo available: ${_repo != null}');

      if (!isSignedIn || _repo == null) {
        final onboardingDone =
            await app_local.LocalStorage.isOnboardingComplete();
        final sessionPreviouslyRestored =
            await app_local.LocalStorage.wasSessionRestored();
        if (onboardingDone || sessionPreviouslyRestored) {
          final savedLang = await app_local.LocalStorage.getLanguage();
          if (savedLang != null) locale = savedLang;
          onboardingPhase = OnboardingPhase.ready;
        } else {
          onboardingPhase = OnboardingPhase.ready;
        }
        notifyListeners();
        unawaited(loadAllData());
        return;
      }

      // ── Try to restore profile (network first, cache fallback) ──────────────
      UserProfile? resolvedProfile;
      try {
        resolvedProfile = await _repo!.ensureProfile();
        await app_local.LocalStorage.saveProfileCache(resolvedProfile.toJson());
      } catch (networkError) {
        if (kDebugMode) debugPrint('Profile fetch failed (likely offline): $networkError');
        final cached = await app_local.LocalStorage.getProfileCache();
        if (cached != null) {
          resolvedProfile = UserProfile.fromJson(cached);
          if (kDebugMode) debugPrint('Restored profile from local cache');
        }
      }

      if (resolvedProfile != null) {
        profile = resolvedProfile;
        notifMessagesEnabled = resolvedProfile.notifMessagesEnabled;
        await app_local.LocalStorage.saveNotifMessagesEnabled(
          resolvedProfile.notifMessagesEnabled,
        );
        if (resolvedProfile.language != null) {
          locale = resolvedProfile.language!;
          await app_local.LocalStorage.saveLanguage(locale);
        }
      }

      final sessionRestored = await app_local.LocalStorage.wasSessionRestored();
      final savedPhase = await app_local.LocalStorage.getOnboardingPhase();
      final onboardingDone =
          await app_local.LocalStorage.isOnboardingComplete();

      if (onboardingDone || resolvedProfile?.onboardingComplete == true) {
        if (!sessionRestored) {
          await app_local.LocalStorage.markSessionRestored();
        }
        if (!onboardingDone) {
          await app_local.LocalStorage.markOnboardingComplete();
        }
        await _enterApp();
        return;
      }

      if (savedPhase != null) {
        onboardingPhase = _parsePhase(savedPhase) ?? OnboardingPhase.location;
        notifyListeners();
        return;
      }

      if (!sessionRestored || resolvedProfile?.language == null) {
        onboardingPhase = OnboardingPhase.language;
        notifyListeners();
        return;
      }

      if (resolvedProfile == null) {
        onboardingPhase = OnboardingPhase.location;
        notifyListeners();
        return;
      }

      onboardingPhase = OnboardingPhase.location;
      notifyListeners();
    } catch (e) {
      initError = 'init_failed';
      final onboardingDone =
          await app_local.LocalStorage.isOnboardingComplete();
      if (onboardingDone) {
        onboardingPhase = OnboardingPhase.ready;
      } else {
        onboardingPhase = OnboardingPhase.auth;
      }
      notifyListeners();
    } finally {
      if (kDebugMode) {
        debugPrint(
        '[AUTH] _initialize finished after ${DateTime.now().millisecondsSinceEpoch - t0}ms',
        );
      }
    }
  }

  Future<void> retryInitialization() => _initialize();

  OnboardingPhase? _parsePhase(String? phase) {
    return switch (phase) {
      'auth' => OnboardingPhase.auth,
      'language' => OnboardingPhase.language,
      'profileSetup' => OnboardingPhase.profileSetup,
      'location' => OnboardingPhase.location,
      'goal' => OnboardingPhase.goal,
      'ready' => OnboardingPhase.ready,
      _ => null,
    };
  }

  void clearDataError() {
    dataError = null;
    notifyListeners();
  }

  /// Called after fresh sign-in/sign-up (email or OAuth callback).
  Future<void> onFreshAuth() async {
    if (_repo == null) {
      final client = AppSupabaseConfig.clientOrNull();
      if (client == null) {
        onboardingPhase = OnboardingPhase.auth;
        notifyListeners();
        return;
      }
      _repo = SupabaseRepository(client);
    }

    profile = await _repo!.ensureProfile();
    if (profile != null) {
      await app_local.LocalStorage.saveProfileCache(profile!.toJson());
      notifMessagesEnabled = profile!.notifMessagesEnabled;
      await app_local.LocalStorage.saveNotifMessagesEnabled(
        profile!.notifMessagesEnabled,
      );
    }

    final locallyDone = await app_local.LocalStorage.isOnboardingComplete();
    final sessionRestored = await app_local.LocalStorage.wasSessionRestored();
    final profileDone = profile?.onboardingComplete == true;

    if (locallyDone || sessionRestored || profileDone) {
      if (profile?.language != null) {
        locale = profile!.language!;
        await app_local.LocalStorage.saveLanguage(locale);
      }
      await _enterApp();
      return;
    }

    onboardingPhase = OnboardingPhase.language;
    await app_local.LocalStorage.saveOnboardingPhase('language');
    notifyListeners();
  }

  /// Loads [profile] after OAuth while the app is already in guest/ready mode.
  ///
  /// Without this, Facebook (and any other browser OAuth) from the auth gate
  /// leaves `profile == null`: owned posts/services still appear because they
  /// key off `currentUser.id`, but name/bio/phone/avatar stay empty.
  Future<void> hydrateSessionProfile() async {
    if (_repo == null) {
      final client = AppSupabaseConfig.clientOrNull();
      if (client == null) return;
      _repo = SupabaseRepository(client);
    }

    try {
      profile = await _repo!.ensureProfile();
      if (profile != null) {
        await app_local.LocalStorage.saveProfileCache(profile!.toJson());
        notifMessagesEnabled = profile!.notifMessagesEnabled;
        await app_local.LocalStorage.saveNotifMessagesEnabled(
          profile!.notifMessagesEnabled,
        );
        if (profile!.language != null) {
          locale = profile!.language!;
          await app_local.LocalStorage.saveLanguage(locale);
        }
      }
      notifyListeners();
      await loadAllData();
      unawaited(_initPushNotifications());
    } catch (e) {
      if (kDebugMode) debugPrint('[AUTH] hydrateSessionProfile failed: $e');
      reportDataError(e);
      notifyListeners();
    }
  }

  Future<void> completeLanguageOnboarding(String language) async {
    await setLocale(language);
    if (_repo != null) {
      await _repo!.updateLanguage(language);
    }
    profile = profile?.copyWith(language: language);
    await app_local.LocalStorage.markSessionRestored();
    await app_local.LocalStorage.saveOnboardingPhase('location');
    onboardingPhase = OnboardingPhase.location;
    notifyListeners();
  }

  /// Called from [ProfileSetupScreen] for OAuth users who signed in without
  /// a display name or phone number on file.
  Future<void> completeProfileSetup({
    required String displayName,
    required String phone,
  }) async {
    try {
      if (_repo != null) {
        await _repo!.updateProfile({
          'display_name': displayName,
          if (phone.isNotEmpty) 'phone': phone,
        });
      }
      profile = profile?.copyWith(
        displayName: displayName,
        phone: phone.isNotEmpty ? phone : profile?.phone,
      );
      if (profile != null) {
        await app_local.LocalStorage.saveProfileCache(profile!.toJson());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ProfileSetup] profile update failed (non-fatal): $e');
    }
    await app_local.LocalStorage.saveOnboardingPhase('location');
    onboardingPhase = OnboardingPhase.location;
    notifyListeners();
  }

  Future<void> completeLocationOnboarding({
    double? lat,
    double? lng,
  }) async {
    locationPermissionGranted = lat != null && lng != null;
    if (lat != null && lng != null) {
      deviceLat = lat;
      deviceLng = lng;
    }
    await app_local.LocalStorage.saveOnboardingPhase('goal');
    onboardingPhase = OnboardingPhase.goal;
    notifyListeners();
  }

  // ── Location CTA (post-onboarding re-prompt) ──────────────────────────────────

  /// Called once after the first frame to read SharedPreferences without
  /// blocking build.
  Future<void> checkLocationCtaVisibility() async {
    if (locationPermissionGranted) {
      _locationCtaReady = false;
      notifyListeners();
      return;
    }
    final snoozedUntil =
        await app_local.LocalStorage.getLocationCtaSnoozedUntil();
    final now = DateTime.now().millisecondsSinceEpoch;
    _locationCtaReady = now >= snoozedUntil;
    notifyListeners();
  }

  /// Whether the location CTA banner should be shown right now.
  bool get showLocationCta => !locationPermissionGranted && _locationCtaReady;

  Future<void> grantLocationFromCta() async {
    final position =
        await PermissionService.requestLocationPermissionAndGetPosition();
    if (position != null) {
      locationPermissionGranted = true;
      deviceLat = position.latitude;
      deviceLng = position.longitude;
    }
    await snoozeLocationCta();
  }

  Future<void> snoozeLocationCta({int days = 3}) async {
    final until = DateTime.now()
        .add(Duration(days: days))
        .millisecondsSinceEpoch;
    await app_local.LocalStorage.saveLocationCtaSnoozedUntil(until);
    _locationCtaReady = false;
    notifyListeners();
  }

  Future<void> completeGoalSelection(String goal) async {
    onboardingGoal = goal;
    await app_local.LocalStorage.savePreferredCategory(goal);
    if (_repo != null) {
      try {
        await _repo!.updateProfile({'preferred_category': goal});
        profile = profile?.copyWith(
          preferredCategory: goal,
          syncStatus: SyncStatus.synced,
        );
        if (kDebugMode) debugPrint('[GoalSelection] preferred_category saved to DB: $goal');
      } catch (e) {
        profile = profile?.copyWith(
          preferredCategory: goal,
          syncStatus: SyncStatus.pending,
        );
        if (kDebugMode) debugPrint('[GoalSelection] DB write failed (will sync later): $e');
      }
    } else {
      profile = profile?.copyWith(preferredCategory: goal);
    }
    await app_local.LocalStorage.clearOnboardingPhase();
    onboardingPhase = OnboardingPhase.ready;
    notifyListeners();
  }

  Future<void> _enterApp() async {
    onboardingPhase = OnboardingPhase.ready;
    navigationStack
      ..clear()
      ..add(HomeScreenRoute());
    notifyListeners();
    try {
      await syncService.init();
      await refreshSyncQueueCounts();
    } catch (e) {
      if (kDebugMode) debugPrint('syncService.init() failed: $e');
    }
    await app_local.LocalStorage.clearOnboardingPhase();
    await loadAllData();
    unawaited(TranslationService.instance.processRetryQueue());
    unawaited(_initPushNotifications());
  }

  Future<void> _unregisterPushToken() async {
    await PermissionService.disablePushOnDevice(
      messagesEnabled: notifMessagesEnabled,
    );
    if (_repo != null) {
      try {
        await _repo!.updateProfile({
          'fcm_token': null,
          'notif_push_enabled': false,
        });
        if (kDebugMode) debugPrint('[FCM] Token cleared from Supabase profile');
      } catch (e) {
        if (kDebugMode) debugPrint('[FCM] clear token failed: $e');
      }
    }
  }

  Future<void> _registerPushToken() async {
    if (!notifPushEnabled) return;

    final token = await PermissionService.enablePushOnDevice(
      messagesEnabled: notifMessagesEnabled,
    );
    if (token == null) {
      notifPushEnabled = false;
      await app_local.LocalStorage.saveNotifPushEnabled(false);
      notifyListeners();
      return;
    }

    if (_repo != null) {
      try {
        await _repo!.updateProfile({
          'fcm_token': token,
          'notif_push_enabled': true,
        });
        if (kDebugMode) debugPrint('[FCM] Token saved to Supabase profile');
      } catch (e) {
        if (kDebugMode) debugPrint('[FCM] save token failed: $e');
      }
    }
  }

  void _attachFcmListeners() {
    if (_fcmListenersAttached) return;
    _fcmListenersAttached = true;

    _fcmTokenRefreshSub?.cancel();
    _fcmTokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (kDebugMode) debugPrint('[FCM] Token refreshed: $newToken');
      if (!notifPushEnabled || _repo == null) return;
      try {
        await _repo!.updateProfile({'fcm_token': newToken});
      } catch (e) {
        if (kDebugMode) debugPrint('[FCM] token refresh save failed: $e');
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('[FCM] Foreground message: ${message.messageId}');
      }
      if (!PermissionService.shouldDeliverPush(
        message,
        pushEnabled: notifPushEnabled,
        messagesEnabled: notifMessagesEnabled,
      )) {
        return;
      }
      PermissionService.showForegroundNotification(
        message,
        messagesEnabled: notifMessagesEnabled,
      );
      if (_repo != null) {
        _repo!.fetchNotifications().then((list) {
          notifications = list;
          notifyListeners();
        }).catchError((e) {
          if (kDebugMode) {
            debugPrint(
              '[FCM] fetchNotifications on foreground message failed: $e',
            );
          }
        });
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('[FCM] Notification opened app: ${message.messageId}');
      }
      _navigateFromPushPayload(message.data);
      if (_repo != null) {
        _repo!.fetchNotifications().then((list) {
          notifications = list;
          notifyListeners();
        }).catchError((e) {
          if (kDebugMode) {
            debugPrint('[FCM] fetchNotifications after tap failed: $e');
          }
        });
      }
    });
  }

  Future<void> _initPushNotifications() async {
    try {
      _attachFcmListeners();

      if (!notifPushEnabled) {
        await _unregisterPushToken();
        return;
      }

      await _registerPushToken();

      // Also handle the case where the app was fully terminated and launched
      // via a notification tap.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        if (kDebugMode) {
          debugPrint('[FCM] App launched from notification: ${initial.messageId}');
        }
        _navigateFromPushPayload(initial.data);
        if (_repo != null) {
          try {
            notifications = await _repo!.fetchNotifications();
            notifyListeners();
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[FCM] fetchNotifications on launch failed: $e');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] _initPushNotifications error: $e');
    }
  }

  /// Navigates to the appropriate screen based on the FCM data payload.
  void _navigateFromPushPayload(Map<String, dynamic> data) {
    final screen = data['screen'] as String?;
    if (screen == null) return;

    switch (screen) {
      case 'listing_detail':
        final listingId = data['listingId'] as String?;
        if (listingId != null && listingId.isNotEmpty) {
          pushScreen(ListingDetailScreenRoute(listingId));
        }

      case 'chat':
        final threadId = data['threadId'] as String?;
        if (threadId != null && threadId.isNotEmpty) {
          final index =
              chatSessions.indexWhere((s) => s.id == threadId);
          if (index != -1) {
            pushScreen(ActiveChatScreenRoute(index));
          } else {
            // Session not loaded yet — refresh then navigate.
            if (_repo != null) {
              _repo!.fetchChatSessions().then((sessions) async {
                chatSessions = await _enrichChatSessions(sessions);
                notifyListeners();
                final newIndex =
                    chatSessions.indexWhere((s) => s.id == threadId);
                if (newIndex != -1) {
                  pushScreen(ActiveChatScreenRoute(newIndex));
                }
              }).catchError((e) {
                if (kDebugMode) debugPrint('[FCM] fetchChatSessions for deep-link failed: $e');
              });
            }
          }
        }

      case 'applicantList':
        final postId = data['hiringPostId'] as String?;
        if (postId != null && postId.isNotEmpty) {
          pushScreen(HiringApplicantListScreenRoute(postId));
        }

      case 'myApplications':
        pushScreen(MyApplicationsScreenRoute());

      case 'hiring_detail':
        final postId = data['postId'] as String?;
        if (postId != null && postId.isNotEmpty) {
          pushScreen(HiringDetailScreenRoute(postId));
        }

      case 'service_detail':
        final serviceId = data['serviceId'] as String?;
        if (serviceId != null && serviceId.isNotEmpty) {
          pushScreen(ServiceDetailScreenRoute(serviceId));
        }

      case 'notifications':
        pushScreen(NotificationsScreenRoute());

      default:
        if (kDebugMode) debugPrint('[FCM] Unknown screen in payload: $screen');
    }
  }
}
