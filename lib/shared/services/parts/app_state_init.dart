// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Initialization & Onboarding ───────────────────────────────────────────────

extension AppStateInit on KoolanAppState {
  Future<void> _initialize() async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    debugPrint('[AUTH] _initialize started at ${t0}ms');
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
          debugPrint(
            '[AUTH] initialSession timed out after '
            '${DateTime.now().millisecondsSinceEpoch - t0}ms — proceeding with current state',
          );
          return null;
        },
      );
      debugPrint(
        '[AUTH] session ready after ${DateTime.now().millisecondsSinceEpoch - t0}ms',
      );
      debugPrint('Repo available: ${_repo != null}');

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
        debugPrint('Profile fetch failed (likely offline): $networkError');
        final cached = await app_local.LocalStorage.getProfileCache();
        if (cached != null) {
          resolvedProfile = UserProfile.fromJson(cached);
          debugPrint('Restored profile from local cache');
        }
      }

      if (resolvedProfile != null) {
        profile = resolvedProfile;
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
      initError = e.toString();
      final onboardingDone =
          await app_local.LocalStorage.isOnboardingComplete();
      if (onboardingDone) {
        onboardingPhase = OnboardingPhase.ready;
      } else {
        onboardingPhase = OnboardingPhase.auth;
      }
      notifyListeners();
    } finally {
      debugPrint(
        '[AUTH] _initialize finished after ${DateTime.now().millisecondsSinceEpoch - t0}ms',
      );
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
      debugPrint('[ProfileSetup] profile update failed (non-fatal): $e');
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
        debugPrint('[GoalSelection] preferred_category saved to DB: $goal');
      } catch (e) {
        profile = profile?.copyWith(
          preferredCategory: goal,
          syncStatus: SyncStatus.pending,
        );
        debugPrint('[GoalSelection] DB write failed (will sync later): $e');
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
    } catch (e) {
      debugPrint('syncService.init() failed: $e');
    }
    await app_local.LocalStorage.clearOnboardingPhase();
    await loadAllData();
    unawaited(TranslationService.instance.processRetryQueue());
    unawaited(_initPushNotifications());
  }

  Future<void> _initPushNotifications() async {
    try {
      final token = await PermissionService
          .requestNotificationPermissionAndGetToken();
      if (token == null) return;

      // Persist token to Supabase profile so the Edge Function can target this device.
      if (_repo != null) {
        await _repo!.updateProfile({'fcm_token': token});
        debugPrint('[FCM] Token saved to Supabase profile');
      }

      // Keep token fresh — save new token whenever Firebase rotates it.
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('[FCM] Token refreshed: $newToken');
        if (_repo != null) {
          await _repo!.updateProfile({'fcm_token': newToken});
        }
      });

      // Show foreground messages as local heads-up notifications.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground message: ${message.messageId}');
        PermissionService.showForegroundNotification(message);
      });

      // Refresh in-app notification list when user taps a push and opens the app.
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Notification opened app: ${message.messageId}');
        if (_repo != null) {
          _repo!.fetchNotifications().then((list) {
            notifications = list;
            notifyListeners();
          }).catchError((e) {
            debugPrint('[FCM] fetchNotifications after tap failed: $e');
          });
        }
      });

      // Also handle the case where the app was fully terminated and launched
      // via a notification tap.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        debugPrint('[FCM] App launched from notification: ${initial.messageId}');
        if (_repo != null) {
          try {
            notifications = await _repo!.fetchNotifications();
            notifyListeners();
          } catch (e) {
            debugPrint('[FCM] fetchNotifications on launch failed: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[FCM] _initPushNotifications error: $e');
    }
  }
}
