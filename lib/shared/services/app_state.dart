import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/router/routes.dart';
import 'cloudinary_upload_service.dart';
import '../models/app_strings.dart';
import '../models/application.dart';
import '../models/chat.dart';
import '../models/hiring_post.dart';
import '../models/listing.dart';
import '../models/profile.dart';
import '../models/service.dart';
import '../models/service_review.dart';
import '../models/syncable_entity.dart';
import 'local_storage.dart' as app_local;
import 'offline/hive_sync_store.dart' hide SyncStatus;
import 'offline/sync_service.dart';
import 'recommendation_engine.dart';
import 'supabase_repository.dart';
import 'translation_service.dart';

enum OnboardingPhase {
  initializing,
  auth,
  language,
  location,
  goal,
  verification,
  ready,
}

/// Central application state. Shared via [KoolanAppStateScope].
class KoolanAppState extends ChangeNotifier {
  KoolanAppState() {
    syncService = SyncService(this);
    // When the SyncService discards a stale queue entry (LWW conflict), surface
    // it through dataError so the SnackBar listener in _ShellScaffold picks it
    // up. This replaces the old _DataErrorBanner overlay approach and avoids
    // any popup/dialog for conflict feedback.
    syncService.onDiscard = (entityType, entityId) {
      dataError = 'Your recent $entityType edit was overwritten by a newer change.';
      notifyListeners();
    };
    final client = AppSupabaseConfig.clientOrNull();
    if (client != null) {
      try {
        _repo = SupabaseRepository(client);
        debugPrint('Supabase repository created');
      } catch (e, st) {
        debugPrint('Supabase repository unavailable: $e');
        debugPrint(st.toString());
        _repo = null;
      }

      try {
        client.auth.onAuthStateChange.listen((event) async {
          debugPrint('Auth event: ${event.event}');

          // initialSession fires once on startup when the persisted session is
          // restored (or when there is no session). This is the correct signal
          // that the auth state is known and settled.
          if (event.event == AuthChangeEvent.initialSession) {
            debugPrint(
              '[AUTH] initialSession received at ${DateTime.now().millisecondsSinceEpoch}ms',
            );
            if (!_sessionReadyCompleter.isCompleted) {
              _sessionReadyCompleter.complete(event.session);
            }
            return;
          }

          if (event.event == AuthChangeEvent.signedIn &&
              event.session != null &&
              _pendingOAuthCompletion) {
            _pendingOAuthCompletion = false;
            await onFreshAuth();
            return;
          }

          // tokenRefreshed fires when supabase_flutter silently renews the
          // access token using the refresh token.  autoRefreshToken is true by
          // default in FlutterAuthClientOptions, so this will fire automatically
          // before each access-token expiry while the app is foregrounded.
          // When the app resumes after a long background gap, the client fires
          // this event on the first foreground tick if the access token needs
          // renewal.  No action needed — the new token is stored automatically
          // by supabase_flutter's GoTrueClient.
          if (event.event == AuthChangeEvent.tokenRefreshed) {
            debugPrint('[AUTH] Token silently refreshed — session extended');
            return;
          }

          // signedOut covers both explicit sign-out AND expired/invalid refresh
          // tokens (gotrue emits SIGNED_OUT in both cases).  Per the
          // WhatsApp-style session spec we drop the user to guest mode rather
          // than the auth screen, preserving onboarding flags so the
          // first-install flow is not re-triggered.  The user will be prompted
          // to sign in again the next time they attempt an auth-gated action.
          if (event.event == AuthChangeEvent.signedOut) {
            debugPrint(
              '[AUTH] signedOut event — entering guest mode. '
              'User will be prompted to sign in again if they attempt an '
              'auth-gated action.',
            );
            await _enterGuestMode(clearOnboardingData: false);
            return;
          }

          notifyListeners();
        });
      } catch (e, st) {
        debugPrint('Auth listener setup failed: $e');
        debugPrint(st.toString());
        // Ensure _initialize() is never left hanging if listener setup fails.
        if (!_sessionReadyCompleter.isCompleted) {
          _sessionReadyCompleter.complete(null);
        }
      }
    } else {
      debugPrint('Supabase not initialized yet; skipping repo/auth setup');
      _repo = null;
      // No Supabase client — complete immediately so _initialize() doesn't hang.
      if (!_sessionReadyCompleter.isCompleted) {
        _sessionReadyCompleter.complete(null);
      }
    }
    _initialize();
  }

  SupabaseRepository? _repo;

  /// Completes when Supabase fires [AuthChangeEvent.initialSession], meaning
  /// the auth state is fully known. All data fetches must wait for this.
  final Completer<Session?> _sessionReadyCompleter = Completer<Session?>();

  bool _pendingOAuthCompletion = false;
  late final SyncService syncService;

  // ── Auth & onboarding ───────────────────────────────────────────────────────
  OnboardingPhase onboardingPhase = OnboardingPhase.initializing;
  String? onboardingGoal;
  bool locationPermissionGranted = false;
  UserProfile? profile;
  String? initError;
  bool isLoadingData = false;
  String? dataError;

  User? get currentUser {
    try {
      final client = AppSupabaseConfig.clientOrNull();
      return client?.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isSignedIn => currentUser != null;

  // ── Navigation ─────────────────────────────────────────────────────────────
  final List<KoolanScreen> navigationStack = [HomeScreenRoute()];

  // ── Locale ──────────────────────────────────────────────────────────────────
  String locale = 'en';
  AppStrings get s => AppStrings(locale);

  Locale get materialLocale {
    // Flutter's built-in Material localization delegates do not provide
    // translations for the custom 'am'/'so' codes used by the app. Falling
    // back to English for framework widgets avoids the runtime crash while
    // the app's own strings continue to switch correctly via AppStrings.
    return const Locale('en');
  }

  // ── Profile ──────────────────────────────────────────────────────────────────

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
    } catch (e) {
      profile = profile?.copyWith(syncStatus: SyncStatus.failed);
      dataError = e.toString();
    }
    notifyListeners();
  }

  // ── Profile image uploads ─────────────────────────────────────────────────

  /// Maximum profile/banner image size: 5 MB.
  static const _photoMaxBytes = 5 * 1024 * 1024;

  /// Lets the user pick an image from their gallery and uploads it as their
  /// profile avatar. Updates [profile.avatarUrl] optimistically on success.
  ///
  /// Returns a user-facing error string if something goes wrong, or null on
  /// success / cancellation (cancelled is not an error).
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
  ///
  /// Returns a user-facing error string if something goes wrong, or null on
  /// success / cancellation.
  Future<String?> uploadBannerImage() async {
    return _pickAndUploadProfileImage(
      imageType: CloudinaryImageType.banner,
      onSuccess: (url) async {
        profile = profile?.copyWith(bannerUrl: url);
        await _syncProfileField('banner_url', url);
      },
    );
  }

  /// Shared implementation for avatar and banner uploads via Cloudinary.
  ///
  /// Flow:
  ///   1. Open the system image picker.
  ///   2. Enforce a 5 MB size limit — return a clear human-readable error
  ///      if exceeded.
  ///   3. If a Supabase session exists: attempt immediate Cloudinary upload.
  ///      On success call [onSuccess] with the secure_url and return null.
  ///   4. If offline (SocketException) or network-class error: save the
  ///      local file path to the Hive queue. The SyncService flush will
  ///      retry when connectivity returns. Returns null (queuing is not an
  ///      error).
  ///   5. Any other error: return a user-facing message.
  Future<String?> _pickAndUploadProfileImage({
    required CloudinaryImageType imageType,
    required Future<void> Function(String secureUrl) onSuccess,
  }) async {
    final current = profile;
    if (current == null) return 'Not signed in';

    // ── 1. Pick image ────────────────────────────────────────────────────────
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false,
        withReadStream: false,
      );
    } catch (e) {
      debugPrint('[PhotoUpload] picker error: $e');
      return e.toString();
    }

    if (result == null || result.files.isEmpty) return null; // user cancelled

    final localPath = result.files.first.path;
    if (localPath == null) return 'Could not read file path from picker';

    // ── 2. Size check ────────────────────────────────────────────────────────
    final file = File(localPath);
    int fileSize;
    try {
      fileSize = await file.length();
    } catch (e) {
      fileSize = result.files.first.size;
    }
    if (fileSize > _photoMaxBytes) {
      final mb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      return 'Photo is too large ($mb MB) — maximum allowed is 5 MB';
    }

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id ?? current.id;

    // ── 3. Attempt online upload via Cloudinary ──────────────────────────────
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
          return null; // success

        case CloudinaryUploadFailure(:final message):
          // Network errors start with "network:" — queue for retry.
          if (message.startsWith('network:')) {
            debugPrint('[PhotoUpload] network error, queueing: $message');
            break; // fall through to offline queue
          }
          // All other Cloudinary errors (misconfiguration, API rejection, etc.)
          // are reported directly — don't queue them.
          debugPrint('[PhotoUpload] cloudinary error: $message');
          return 'Upload failed: $message';
      }
    }

    // ── 4. Offline queue ─────────────────────────────────────────────────────
    await _queuePhotoUpload(
      userId: userId,
      imageType: imageType,
      localPath: localPath,
    );
    // Queuing is not an error; SyncService will flush when back online.
    return null;
  }

  /// Persists a pending photo upload to the Hive queue so it can be retried
  /// on the next connectivity-restored sync pass.
  ///
  /// Payload keys: userId, imageType ('avatar'|'banner'), localPath.
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
    debugPrint('[PhotoUpload] queued for later: $key');
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

        // Support both old-format queued entries (bucket key) and new
        // imageType-based entries written by the Cloudinary path.
        final CloudinaryImageType imageType;
        if (data.containsKey('imageType')) {
          imageType = data['imageType'] == 'avatar'
              ? CloudinaryImageType.avatar
              : CloudinaryImageType.banner;
        } else {
          // Legacy queue entry that used 'bucket' — derive type from bucket name.
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
            debugPrint('[PhotoUpload] flushed: $key → $secureUrl');

          case CloudinaryUploadFailure(:final message):
            debugPrint('[PhotoUpload] flush failed for $key: $message');
            // Leave in queue for next pass.
        }
      } catch (e) {
        debugPrint('[PhotoUpload] flush error for $key: $e');
        // Leave in queue for next pass.
      }
    }
  }

  /// Immediately persists a single profile field to Supabase.
  /// Used after a successful Cloudinary upload.
  Future<void> _syncProfileField(String column, String value) async {
    if (profile == null) return;
    try {
      await _repo?.updateProfile({column: value});
      debugPrint('[ProfileSync] $column updated in Supabase ✅');
    } catch (e) {
      debugPrint('[ProfileSync] direct update failed ($column): $e');
      dataError = e.toString();
      notifyListeners();
    }
  }

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
        dataError = e.toString();
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

  // ── Theme ────────────────────────────────────────────────────────────────────
  bool isDarkMode = false;

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    app_local.LocalStorage.saveDarkMode(isDarkMode);
    notifyListeners();
  }

  // ── Notification preferences (persisted device-level) ────────────────────────
  bool notifPushEnabled    = true;
  bool notifMessagesEnabled = true;
  bool notifPriceAlerts    = false;

  void toggleNotifPush(bool value) {
    notifPushEnabled = value;
    app_local.LocalStorage.saveNotifPushEnabled(value);
    notifyListeners();
  }

  void toggleNotifMessages(bool value) {
    notifMessagesEnabled = value;
    app_local.LocalStorage.saveNotifMessagesEnabled(value);
    notifyListeners();
  }

  void toggleNotifPriceAlerts(bool value) {
    notifPriceAlerts = value;
    app_local.LocalStorage.saveNotifPriceAlerts(value);
    notifyListeners();
  }

  // ── Filters ─────────────────────────────────────────────────────────────────
  String selectedCategory = 'ALL';
  String searchQuery = '';

  // ── Comparison ──────────────────────────────────────────────────────────────
  bool compareModeEnabled = false;
  Set<String> selectedCompareIds = {};

  // ── Data ────────────────────────────────────────────────────────────────────
  List<Listing> allListings = [];
  List<Service> allServices = [];
  List<ChatSession> chatSessions = [];
  List<HiringPost> allHiringPosts = [];
  List<Application> myApplications = [];
  List<Map<String, dynamic>> notifications = [];

  /// In-memory set of item IDs the user has viewed this session.
  /// Not persisted — signals collected across phases A–C (save/apply) are the
  /// primary durable signals. This is the minimal addition for the "viewed"
  /// interaction penalty described in Phase D spec.
  final Set<String> recentlyViewedIds = {};

  // ── Post-wizard state ────────────────────────────────────────────────────────
  int postStep = 1;
  String postCategory = 'CARS';
  String postTitle = '';
  String postPrice = '';
  String postDescription = '';
  String postLocation = 'Kebele 06';
  String postPhysicalAddress = '';
  bool postMainPhotoAttached = false;
  /// Condition / status selected by the user (e.g. "Brand New", "For Rent").
  /// Empty string means the user has not yet chosen one.
  String postCondition = '';
  String postSpec1 = '';
  String postSpec2 = '';
  String postSpec3 = '';
  String postSpec4 = '';

  /// Local file paths picked by the user in the wizard (up to 8 images).
  List<String> postImagePaths = [];

  /// Set while listing images are being uploaded in submitPost().
  bool isUploadingListingImages = false;

  /// Non-null when one or more listing images fail to upload.
  String? listingImageUploadError;

  // ── Initialization ──────────────────────────────────────────────────────────

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
      notifPushEnabled    = await app_local.LocalStorage.getNotifPushEnabled();
      notifMessagesEnabled = await app_local.LocalStorage.getNotifMessagesEnabled();
      notifPriceAlerts    = await app_local.LocalStorage.getNotifPriceAlerts();

      // Wait for Supabase to confirm the auth state (initialSession event).
      // This prevents fetching data before the session is actually settled.
      // Times out after 5 s to avoid hanging forever if Supabase is misconfigured.
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
        // ── Decide: first-install auth gate vs. guest mode ────────────────
        // A user who has never completed onboarding (brand new install with no
        // prior session) must see the mandatory auth + onboarding flow.
        // A returning user who signed out (or whose refresh token expired) has
        // already completed onboarding, so we drop them into guest/browse mode
        // rather than forcing them back through the full onboarding screens.
        final onboardingDone =
            await app_local.LocalStorage.isOnboardingComplete();
        final sessionPreviouslyRestored =
            await app_local.LocalStorage.wasSessionRestored();
        if (onboardingDone || sessionPreviouslyRestored) {
          // Post-first-install: stay on Home in guest mode.
          // Restore the locale so the UI language is correct even without a
          // profile (language was persisted separately in wasSessionRestored flow).
          final savedLang = await app_local.LocalStorage.getLanguage();
          if (savedLang != null) locale = savedLang;
          onboardingPhase = OnboardingPhase.ready;
        } else {
          // True first install — drop straight into guest/browse mode.
          // Auth is no longer mandatory upfront; the soft-gate bottom sheet
          // will prompt sign-in when the user attempts any auth-gated action
          // (post, save, message, apply, etc.).
          onboardingPhase = OnboardingPhase.ready;
        }
        notifyListeners();
        return;
      }

      // ── Try to restore profile (network first, cache fallback) ──────────────
      UserProfile? resolvedProfile;
      try {
        resolvedProfile = await _repo!.ensureProfile();
        // Cache the freshly loaded profile for offline use.
        await app_local.LocalStorage.saveProfileCache(resolvedProfile.toJson());
      } catch (networkError) {
        debugPrint('Profile fetch failed (likely offline): $networkError');
        // Fall back to locally cached profile.
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

      // ── Decide which onboarding phase to show ───────────────────────────────

      // No language chosen yet (first auth ever).
      if (!sessionRestored || resolvedProfile?.language == null) {
        onboardingPhase = OnboardingPhase.language;
        notifyListeners();
        return;
      }

      // Mid-onboarding: resume from where they left off.
      if (savedPhase != null) {
        onboardingPhase = _parsePhase(savedPhase) ?? OnboardingPhase.location;
        notifyListeners();
        return;
      }

      // Onboarding already finished (local flag or profile flag).
      if (onboardingDone || resolvedProfile?.onboardingComplete == true) {
        await _enterApp();
        return;
      }

      // No profile loaded and no local flag — go to location step.
      if (resolvedProfile == null) {
        onboardingPhase = OnboardingPhase.location;
        notifyListeners();
        return;
      }

      // Profile exists but onboarding not complete → resume from location.
      onboardingPhase = OnboardingPhase.location;
      notifyListeners();
    } catch (e) {
      initError = e.toString();
      // Only force the full auth/onboarding flow if this looks like a true
      // first-install scenario (onboarding not yet completed).  Otherwise show
      // the error inline on the Home screen so the user can retry without being
      // kicked back to the auth flow.
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
      'location' => OnboardingPhase.location,
      'goal' => OnboardingPhase.goal,
      'verification' => OnboardingPhase.verification,
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
    // _repo is nulled on logout. Re-create it from the still-live Supabase
    // client so the subsequent profile fetch and onboarding flow work correctly.
    if (_repo == null) {
      final client = AppSupabaseConfig.clientOrNull();
      if (client == null) {
        onboardingPhase = OnboardingPhase.auth;
        notifyListeners();
        return;
      }
      _repo = SupabaseRepository(client);
    }

    await app_local.LocalStorage.clearSessionRestored();
    profile = await _repo!.ensureProfile();
    if (profile != null) {
      await app_local.LocalStorage.saveProfileCache(profile!.toJson());
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

  Future<void> completeLocationOnboarding() async {
    locationPermissionGranted = true;
    await app_local.LocalStorage.saveOnboardingPhase('goal');
    onboardingPhase = OnboardingPhase.goal;
    notifyListeners();
  }

  Future<void> completeGoalSelection(String goal) async {
    onboardingGoal = goal;
    // Persist to local storage first (works offline).
    await app_local.LocalStorage.savePreferredCategory(goal);
    // Also write to the DB immediately so the preference is available for
    // server-side analytics and recommendation features.
    if (_repo != null) {
      try {
        await _repo!.updateProfile({'preferred_category': goal});
        profile = profile?.copyWith(
          preferredCategory: goal,
          syncStatus: SyncStatus.synced,
        );
        debugPrint('[GoalSelection] preferred_category saved to DB: $goal');
      } catch (e) {
        // Non-fatal — the goal is saved locally and will sync later.
        profile = profile?.copyWith(
          preferredCategory: goal,
          syncStatus: SyncStatus.pending,
        );
        debugPrint('[GoalSelection] DB write failed (will sync later): $e');
      }
    } else {
      profile = profile?.copyWith(preferredCategory: goal);
    }
    await app_local.LocalStorage.saveOnboardingPhase('verification');
    onboardingPhase = OnboardingPhase.verification;
    notifyListeners();
  }

  Future<void> completeVerificationOnboarding(bool verified) async {
    if (_repo != null) {
      try {
        await _repo!.updateProfile({
          'onboarding_complete': true,
          if (onboardingGoal != null) 'preferred_category': onboardingGoal,
          'language': locale,
          if (verified) 'fayda_verified': true,
        });
      } catch (e) {
        // Profile update failed (network, RLS, etc.) — not fatal for onboarding.
        // The sync queue will retry when connectivity returns.
        debugPrint('updateProfile during verification failed: $e');
      }
    }
    profile = profile?.copyWith(
      onboardingComplete: true,
      preferredCategory: onboardingGoal,
      language: locale,
      faydaVerified: verified ? true : profile?.faydaVerified,
    );
    // Persist locally so we never re-show onboarding even when offline.
    await app_local.LocalStorage.markOnboardingComplete();
    if (profile != null) {
      await app_local.LocalStorage.saveProfileCache(profile!.toJson());
    }
    await app_local.LocalStorage.clearOnboardingPhase();
    await _enterApp();
  }

  Future<void> _enterApp() async {
    onboardingPhase = OnboardingPhase.ready;
    navigationStack
      ..clear()
      ..add(HomeScreenRoute());
    // Navigate immediately — don't let sync or data loading block the transition.
    notifyListeners();
    try {
      await syncService.init();
    } catch (e) {
      debugPrint('syncService.init() failed: $e');
    }
    await app_local.LocalStorage.clearOnboardingPhase();
    await loadAllData();
    // Process any pending translation retry jobs from previous sessions.
    unawaited(TranslationService.instance.processRetryQueue());
  }

  Future<void> loadAllData() async {
    isLoadingData = true;
    dataError = null;
    notifyListeners();
    try {
      if (_repo == null) {
        allListings = [];
        chatSessions = [];
        return;
      }
      final listings = await _repo!.fetchListings();
      allListings = listings;
      // Cache for offline use.
      await app_local.LocalStorage.saveListingsCache(
        listings.map((l) => l.toJson()).toList(),
      );
      final services = await _repo!.fetchServices();
      allServices = services;
      await app_local.LocalStorage.saveServicesCache(
        services.map((s) => s.toJson()).toList(),
      );
      // Chat sessions are not critical — don't block on failure.
      try {
        chatSessions = await _repo!.fetchChatSessions();
      } catch (e) {
        debugPrint('fetchChatSessions failed: $e');
      }
      // Hiring posts and applications — non-blocking, fail silently.
      try {
        final posts = await _repo!.fetchHiringPosts();
        final myPostIds = posts
            .where((p) => p.posterId == currentUser?.id)
            .map((p) => p.id)
            .toList();
        final counts = await _repo!.fetchApplicantCounts(myPostIds);
        allHiringPosts = posts.map((p) {
          final count = counts[p.id] ?? 0;
          return count > 0 ? p.copyWith(applicantCount: count) : p;
        }).toList();
      } catch (e) {
        debugPrint('fetchHiringPosts failed: $e');
      }
      try {
        myApplications = await _repo!.fetchMyApplications();
      } catch (e) {
        debugPrint('fetchMyApplications failed: $e');
      }
      try {
        notifications = await _repo!.fetchNotifications();
      } catch (e) {
        debugPrint('fetchNotifications failed: $e');
      }
    } on SocketException catch (e) {
      debugPrint('fetchListings offline (SocketException): $e');
      await _serveListingsFromCache();
    } on HandshakeException catch (e) {
      debugPrint('fetchListings offline (HandshakeException): $e');
      await _serveListingsFromCache();
    } catch (e) {
      // Check if it's a network-related error by message
      final msg = e.toString().toLowerCase();
      final isNetworkError =
          msg.contains('network') ||
          msg.contains('socket') ||
          msg.contains('connection') ||
          msg.contains('host lookup') ||
          msg.contains('failed host') ||
          msg.contains('errno = 7') || // ECONNREFUSED
          msg.contains('errno = 101') || // ENETUNREACH
          msg.contains('errno = 111'); // ECONNREFUSED

      if (isNetworkError) {
        debugPrint('fetchListings network error: $e');
        await _serveListingsFromCache();
      } else {
        // Real app error — show it, but still serve any previously loaded data.
        debugPrint('fetchListings error: $e');
        dataError = e.toString();
      }
    } finally {
      isLoadingData = false;
      notifyListeners();
    }
  }

  /// Loads cached listings into [allListings] and shows a soft banner.
  /// If we already have listings in memory (e.g. a background refresh failed),
  /// we keep those and stay silent.
  Future<void> _serveListingsFromCache() async {
    if (allListings.isNotEmpty || allServices.isNotEmpty) {
      // Already have data in memory — silent failure, no banner needed.
      return;
    }
    final listingsCached = await app_local.LocalStorage.getListingsCache();
    if (listingsCached != null && listingsCached.isNotEmpty) {
      final userId = currentUser?.id;
      allListings = listingsCached
          .map(
            (json) => Listing.fromJson(
              json,
              isSaved: json['is_saved'] as bool? ?? false,
              isOwnedByCurrentUser: json['seller_id'] == userId,
            ),
          )
          .toList();
    }
    final servicesCached = await app_local.LocalStorage.getServicesCache();
    if (servicesCached != null && servicesCached.isNotEmpty) {
      final userId = currentUser?.id;
      allServices = servicesCached
          .map((json) => Service.fromJson(json))
          .where((service) => service.ownerId == userId || service.availability)
          .toList();
    }
    if (allListings.isNotEmpty || allServices.isNotEmpty) {
      dataError = 'Showing cached data — you appear to be offline.';
    } else {
      dataError = 'No internet connection and no cached data available.';
    }
  }

  // ── Navigation actions ───────────────────────────────────────────────────────
  void pushScreen(KoolanScreen screen) {
    navigationStack.add(screen);
    notifyListeners();
  }

  void popScreen() {
    if (navigationStack.length > 1) {
      navigationStack.removeLast();
      notifyListeners();
    }
  }

  void switchTab(KoolanScreen rootTab) {
    navigationStack
      ..clear()
      ..add(HomeScreenRoute());
    if (rootTab is! HomeScreenRoute) {
      navigationStack.add(rootTab);
    }
    notifyListeners();
  }

  // ── Filter actions ───────────────────────────────────────────────────────────
  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  List<Listing> getFilteredListings() {
    return allListings.where((listing) {
      final matchesCategory =
          selectedCategory == 'ALL' || listing.category == selectedCategory;
      final q = searchQuery.toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          listing.title.toLowerCase().contains(q) ||
          listing.location.toLowerCase().contains(q) ||
          listing.description.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<Listing> getSavedListings() =>
      allListings.where((l) => l.isSaved).toList();

  List<Listing> getMyListings() =>
      allListings.where((l) => l.isOwnedByCurrentUser).toList();

  /// Optimistically removes [listingId] from [allListings] and deletes it from
  /// Supabase. No offline-queue path — requires connectivity.
  Future<void> deleteListing(String listingId) async {
    allListings.removeWhere((l) => l.id == listingId);
    notifyListeners();
    try {
      await _repo?.deleteListing(listingId);
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
    }
  }

  /// Updates an existing listing's editable fields and optionally new images.
  ///
  /// [newImagePaths] — local file paths to upload as additional images.
  /// Existing [listing.imageUrls] are preserved unless replaced.
  Future<void> updateListing({
    required Listing listing,
    required String title,
    required String price,
    required String description,
    required String location,
    List<String> newImagePaths = const [],
    List<String> existingImageUrls = const [],
  }) async {
    if (_repo == null) {
      dataError = 'Supabase unavailable';
      notifyListeners();
      return;
    }

    final userId = currentUser?.id ?? '';
    final uploadedUrls = <String>[];

    // Upload any new local images to Cloudinary.
    for (int i = 0; i < newImagePaths.length; i++) {
      final file = File(newImagePaths[i]);
      if (!await file.exists()) continue;
      final result = await CloudinaryUploadService.instance.uploadListingImage(
        imageFile: file,
        userId: userId,
        listingId: listing.id,
        index: existingImageUrls.length + i,
      );
      if (result is CloudinaryUploadSuccess) {
        uploadedUrls.add(result.secureUrl);
      }
    }

    final mergedUrls = [...existingImageUrls, ...uploadedUrls];
    final primaryImageUrl =
        mergedUrls.isNotEmpty ? mergedUrls.first : listing.imageUrl;

    // Optimistic local update.
    final priceStr =
        (price.startsWith('ETB') || price.startsWith(r'$'))
            ? price.trim()
            : 'ETB ${price.trim()}';

    final updated = listing.copyWith(
      title: title.trim(),
      price: priceStr,
      description: description.trim(),
      location: location.trim(),
      imageUrl: primaryImageUrl,
      imageUrls: mergedUrls,
      localUpdatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    final idx = allListings.indexWhere((l) => l.id == listing.id);
    if (idx != -1) allListings[idx] = updated;
    notifyListeners();

    try {
      await _repo!.updateListing(listing.id, {
        'title': updated.title,
        'price': updated.price,
        'description': updated.description,
        'location': updated.location,
        'image_url': primaryImageUrl,
        'image_urls': mergedUrls,
      });
      if (idx != -1) {
        allListings[idx] = updated.copyWith(syncStatus: SyncStatus.synced);
      }
    } catch (e) {
      if (idx != -1) {
        allListings[idx] = updated.copyWith(syncStatus: SyncStatus.failed);
      }
      dataError = e.toString();
    }
    notifyListeners();
  }

  // ── Recommendation helpers ───────────────────────────────────────────────────

  /// Records that the user navigated to an item detail screen.
  /// In-memory only — resets on app restart. Used as a soft interaction signal
  /// to deprioritise already-viewed items in recommendations.
  void recordItemViewed(String id) {
    recentlyViewedIds.add(id);
    // No notifyListeners() — this is a background signal, not UI state.
  }

  /// Builds a [UserContext] snapshot from the current app state.
  ///
  /// Combines all available signals:
  /// - Preferred category from onboarding goal (via [UserContext.categoryFromGoal])
  ///   or profile.preferredCategory as a fallback.
  /// - Location city from profile; hasLocation from [locationPermissionGranted].
  /// - Saved listing IDs.
  /// - Applied hiring post IDs.
  /// - In-memory recently viewed IDs.
  UserContext buildUserContext() {
    // Category: onboardingGoal takes priority (freshest intent), then profile.
    final rawGoal = onboardingGoal ?? profile?.preferredCategory;
    final category = UserContext.categoryFromGoal(rawGoal);

    // Saved listing IDs.
    final savedIds = allListings
        .where((l) => l.isSaved)
        .map((l) => l.id)
        .toSet();

    // Applied hiring post IDs.
    final appliedIds = myApplications
        .map((a) => a.hiringPostId)
        .toSet();

    return UserContext(
      preferredCategory: category,
      userLocation: profile?.city,
      hasLocation: locationPermissionGranted && (profile?.city?.isNotEmpty ?? false),
      savedIds: savedIds,
      appliedPostIds: appliedIds,
      recentlyViewedIds: Set.unmodifiable(recentlyViewedIds),
    );
  }

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

  Future<void> submitServiceEdit(Service service, {String? newImagePath}) async {
    if (currentUser == null) return;

    final now = DateTime.now();
    final isNew = service.id.startsWith('local_');
    final userId = currentUser!.id;

    // Upload new image to Cloudinary before saving if provided.
    String imageUrl = service.imageUrl;
    if (newImagePath != null) {
      final file = File(newImagePath);
      if (await file.exists()) {
        final result = await CloudinaryUploadService.instance.uploadListingImage(
          imageFile: file,
          userId: userId,
          listingId: service.id,
          index: 0,
        );
        if (result is CloudinaryUploadSuccess) {
          imageUrl = result.secureUrl;
        }
      }
    }

    final updated = service
        .copyWith(imageUrl: imageUrl, syncStatus: SyncStatus.pending, localUpdatedAt: now);

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
      'created_at': updated.createdAt.toIso8601String(),
    };

    try {
      if (isNew) {
        final realId = await _repo!.insertService(fields);
        // Replace the temporary local id with the real Supabase id.
        final idx = allServices.indexWhere((s) => s.id == updated.id);
        if (idx != -1) {
          allServices[idx] = allServices[idx].copyWith(id: realId, syncStatus: SyncStatus.synced);
        }
      } else {
        await _repo!.updateService(updated.id, fields);
        final idx = allServices.indexWhere((s) => s.id == updated.id);
        if (idx != -1) {
          allServices[idx] = allServices[idx].copyWith(syncStatus: SyncStatus.synced);
        }
      }
    } catch (e) {
      final idx = allServices.indexWhere((s) => s.id == updated.id);
      if (idx != -1) {
        allServices[idx] = allServices[idx].copyWith(syncStatus: SyncStatus.failed);
      }
      dataError = e.toString();
    }
    notifyListeners();
  }

  /// Called by SyncService after a successful push for an existing item.
  /// Updates the in-memory sync status badge without a full reload.
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

  /// Called by SyncService after a new service is inserted into Supabase and
  /// we receive the real UUID. Replaces the temporary local_* id in-memory so
  /// subsequent edits/deletes target the correct row.
  void replaceServiceId(String localId, String realId) {
    final idx = allServices.indexWhere((s) => s.id == localId);
    if (idx == -1) return;
    allServices[idx] = allServices[idx].copyWith(
      id: realId,
      syncStatus: SyncStatus.synced,
    );
    notifyListeners();
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
      dataError = e.toString();
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
      dataError = e.toString();
    }
    notifyListeners();
  }

  // ── Hiring posts ─────────────────────────────────────────────────────────────

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
  /// Called after loading the applicant list so the management screen badge
  /// stays accurate without a full data reload.
  void updateHiringPostApplicantCount(String postId, int count) {
    final idx = allHiringPosts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    allHiringPosts[idx] =
        allHiringPosts[idx].copyWith(applicantCount: count);
    notifyListeners();
  }

  Future<void> submitHiringPostEdit(HiringPost post, {String? newImagePath}) async {
    if (currentUser == null) return;

    final now = DateTime.now();
    final isNew = post.id.startsWith('local_');
    final userId = currentUser!.id;

    // Upload new image to Cloudinary before saving if provided.
    String imageUrl = post.imageUrl;
    if (newImagePath != null) {
      final file = File(newImagePath);
      if (await file.exists()) {
        final result = await CloudinaryUploadService.instance.uploadListingImage(
          imageFile: file,
          userId: userId,
          listingId: post.id,
          index: 0,
        );
        if (result is CloudinaryUploadSuccess) {
          imageUrl = result.secureUrl;
        }
      }
    }

    final updated = post
        .copyWith(imageUrl: imageUrl, syncStatus: SyncStatus.pending, localUpdatedAt: now);

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
      'created_at': updated.createdAt.toIso8601String(),
    };

    try {
      if (isNew) {
        final realId = await _repo!.insertHiringPost(fields);
        final idx = allHiringPosts.indexWhere((p) => p.id == updated.id);
        if (idx != -1) {
          allHiringPosts[idx] = allHiringPosts[idx].copyWith(id: realId, syncStatus: SyncStatus.synced);
        }
      } else {
        await _repo!.updateHiringPost(updated.id, fields);
        final idx = allHiringPosts.indexWhere((p) => p.id == updated.id);
        if (idx != -1) {
          allHiringPosts[idx] = allHiringPosts[idx].copyWith(syncStatus: SyncStatus.synced);
        }
      }
    } catch (e) {
      final idx = allHiringPosts.indexWhere((p) => p.id == updated.id);
      if (idx != -1) {
        allHiringPosts[idx] = allHiringPosts[idx].copyWith(syncStatus: SyncStatus.failed);
      }
      dataError = e.toString();
    }
    notifyListeners();
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

  // ── Applications ─────────────────────────────────────────────────────────────

  /// Returns applications for a specific hiring post (poster's view).
  /// Fetches fresh from Supabase if online; returns in-memory cache otherwise.
  final Map<String, List<Application>> _applicantsCache = {};

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
        myApplications[idx] = application.copyWith(id: realId, syncStatus: SyncStatus.synced);
      }
      unawaited(_notifyNewApplication(hiringPostId: hiringPostId, application: myApplications[idx < 0 ? myApplications.length - 1 : idx]));
    } catch (e) {
      final idx = myApplications.indexWhere((a) => a.id == tempId);
      if (idx != -1) {
        myApplications[idx] = application.copyWith(syncStatus: SyncStatus.failed);
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
          postApps2[idx] = postApps2[idx].copyWith(syncStatus: SyncStatus.synced);
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
          postApps2[idx] = postApps2[idx].copyWith(syncStatus: SyncStatus.failed);
        }
      }
      dataError = e.toString();
    }
    notifyListeners();
  }

  /// Called by [SyncService] after an application status update has been
  /// successfully written to Supabase.
  ///
  /// Updates [myApplications] in-memory so the applicant sees the new status
  /// immediately the next time they look at their "My Applications" screen —
  /// without requiring a full data reload.
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
    // Also update the applicant's entry inside _applicantsCache so the
    // poster's applicant list stays consistent.
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

  // ── Notifications ────────────────────────────────────────────────────────────

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

  /// Best-effort: insert a notification for the hiring post owner when a new
  /// application arrives. Runs fire-and-forget, never blocks the apply flow.
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
      // Reload notifications if we are the recipient.
      if (post.posterId == currentUser?.id) {
        notifications = await _repo!.fetchNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('_notifyNewApplication error: $e');
    }
  }

  /// Best-effort: insert a notification for the applicant when the poster
  /// changes the application status.
  Future<void> _notifyStatusChanged({
    required String applicationId,
    required String hiringPostId,
    required ApplicationStatus newStatus,
  }) async {
    if (_repo == null) return;
    try {
      // Find the applicant from the cache.
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
      // Reload notifications if we are the applicant.
      if (app.applicantId == currentUser?.id) {
        notifications = await _repo!.fetchNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('_notifyStatusChanged error: $e');
    }
  }

  // ── Reviews ──────────────────────────────────────────────────────────────────

  /// In-memory reviews cache keyed by service id.
  final Map<String, List<ServiceReview>> _reviewsCache = {};

  List<ServiceReview> getReviewsForService(String serviceId) =>
      _reviewsCache[serviceId] ?? [];

  Future<List<ServiceReview>> loadReviewsForService(String serviceId) async {
    if (_repo == null) return [];
    try {
      final reviews = await _repo!.fetchReviewsForService(serviceId);
      _reviewsCache[serviceId] = reviews;
      notifyListeners();
      return reviews;
    } catch (e) {
      debugPrint('loadReviewsForService error: $e');
      return _reviewsCache[serviceId] ?? [];
    }
  }

  /// Submits a review for [serviceId].
  ///
  /// TODO (Phase C Part 2): Gate this on a completed HiringApplication.
  /// For Part 1, any authenticated user can leave a review.
  Future<void> submitReview({
    required String serviceId,
    required int rating,
    required String comment,
  }) async {
    if (_repo == null) {
      dataError = 'Supabase unavailable';
      notifyListeners();
      return;
    }
    try {
      final review = await _repo!.submitReview(
        serviceId: serviceId,
        rating: rating,
        comment: comment,
      );
      final existing = List<ServiceReview>.from(
        _reviewsCache[serviceId] ?? [],
      );
      // Replace existing review by same user, or prepend.
      final idx = existing.indexWhere((r) => r.reviewerId == review.reviewerId);
      if (idx >= 0) {
        existing[idx] = review;
      } else {
        existing.insert(0, review);
      }
      _reviewsCache[serviceId] = existing;
      notifyListeners();
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Public Profile ───────────────────────────────────────────────────────────

  /// In-memory cache of public profiles keyed by userId.
  final Map<String, UserProfile> _publicProfileCache = {};

  /// In-memory reviews cache keyed by userId (reviews written ABOUT that user).
  final Map<String, List<ServiceReview>> _userReviewsCache = {};

  UserProfile? getCachedPublicProfile(String userId) =>
      _publicProfileCache[userId];

  List<ServiceReview> getReviewsForUser(String userId) =>
      _userReviewsCache[userId] ?? [];

  /// Fetches the public profile for [userId] and caches it.
  Future<UserProfile?> loadPublicProfile(String userId) async {
    if (_repo == null) return _publicProfileCache[userId];
    try {
      final p = await _repo!.fetchPublicProfile(userId);
      if (p != null) _publicProfileCache[userId] = p;
      notifyListeners();
      return p;
    } catch (e) {
      debugPrint('loadPublicProfile error: $e');
      return _publicProfileCache[userId];
    }
  }

  /// Fetches all reviews received by [userId] and caches them.
  Future<List<ServiceReview>> loadReviewsForUser(String userId) async {
    if (_repo == null) return _userReviewsCache[userId] ?? [];
    try {
      final reviews = await _repo!.fetchReviewsForUser(userId);
      _userReviewsCache[userId] = reviews;
      notifyListeners();
      return reviews;
    } catch (e) {
      debugPrint('loadReviewsForUser error: $e');
      return _userReviewsCache[userId] ?? [];
    }
  }

  // ── Save / Bookmark ──────────────────────────────────────────────────────────
  Future<void> toggleSaveListing(String listingId) async {
    final index = allListings.indexWhere((l) => l.id == listingId);
    if (index == -1) return;
    final listing = allListings[index];
    final newSaved = !listing.isSaved;
    allListings[index] = listing.copyWith(isSaved: newSaved);
    notifyListeners();
    try {
      if (_repo == null) {
        dataError = 'Supabase unavailable';
        notifyListeners();
        return;
      }
      await _repo!.toggleFavorite(listingId, listing.isSaved);
    } catch (e) {
      allListings[index] = listing;
      dataError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Comparison ───────────────────────────────────────────────────────────────
  void toggleCompareMode() {
    compareModeEnabled = !compareModeEnabled;
    if (!compareModeEnabled) selectedCompareIds.clear();
    notifyListeners();
  }

  void toggleCompareSelection(String id) {
    if (selectedCompareIds.contains(id)) {
      selectedCompareIds.remove(id);
    } else if (selectedCompareIds.length < 2) {
      selectedCompareIds.add(id);
    }
    notifyListeners();
  }

  // ── Chat ─────────────────────────────────────────────────────────────────────
  Future<void> sendChatMessage(String sessionId, String text) async {
    if (text.trim().isEmpty) return;
    final index = chatSessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    try {
      if (_repo == null) {
        dataError = 'Supabase unavailable';
        notifyListeners();
        return;
      }
      final msg = await _repo!.sendMessage(threadId: sessionId, text: text);
      final session = chatSessions[index];
      final newTotal = session.totalMessages + 1;
      // Auto-reveal once 3 real messages have been sent in this thread.
      final shouldReveal = !session.contactRevealed && newTotal >= 3;
      chatSessions[index] = session.copyWith(
        messages: [...session.messages, msg],
        unreadCount: 0,
        totalMessages: newTotal,
        contactRevealed: shouldReveal ? true : session.contactRevealed,
      );
      notifyListeners();
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Explicitly reveals contact details for [sessionId].
  /// Called when either party taps "Share phone number" in the chat thread.
  /// No-op if already revealed.
  void revealContactForThread(String sessionId) {
    final index = chatSessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    final session = chatSessions[index];
    if (session.contactRevealed) return;
    chatSessions[index] = session.copyWith(contactRevealed: true);
    notifyListeners();
  }

  /// Returns the chat session for [listingId], or null if none exists yet.
  ChatSession? getSessionForListing(String listingId) {
    try {
      return chatSessions.firstWhere((s) => s.listingId == listingId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> startChatForListing(String listingId) async {
    final listing = getListingById(listingId);
    if (listing == null || listing.sellerId == null) return null;
    try {
      if (_repo == null) {
        dataError = 'Supabase unavailable';
        notifyListeners();
        return null;
      }
      final threadId = await _repo!.getOrCreateThread(
        listingId: listingId,
        sellerId: listing.sellerId!,
      );
      chatSessions = await _repo!.fetchChatSessions();
      notifyListeners();
      return threadId;
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Opens (or reuses) the chat thread for [listingId], then sends a
  /// pre-formatted viewing-request message with the chosen [date] and [time].
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> sendViewingRequest({
    required String listingId,
    required DateTime date,
    required TimeOfDay time,
    required String messageTemplate,
  }) async {
    try {
      // Ensure a thread exists for this listing.
      final threadId = await startChatForListing(listingId);
      if (threadId == null) return false;

      // Format date and time for the message body.
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute';

      final text = messageTemplate
          .replaceAll('{date}', dateStr)
          .replaceAll('{time}', timeStr);

      await sendChatMessage(threadId, text);
      return true;
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Opens (or reuses) a direct chat thread between the poster and an
  /// applicant for a hiring application. Returns the thread id on success,
  /// or null on failure.
  Future<String?> startChatForApplication({
    required String applicantId,
    required String posterId,
  }) async {
    try {
      if (_repo == null) {
        dataError = 'Supabase unavailable';
        notifyListeners();
        return null;
      }
      final threadId = await _repo!.getOrCreateApplicationThread(
        applicantId: applicantId,
        posterId: posterId,
      );
      chatSessions = await _repo!.fetchChatSessions();
      notifyListeners();
      return threadId;
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Reports ─────────────────────────────────────────────────────────────────
  Future<void> submitReport({
    required String reason,
    String? listingId,
    String? reportedUserId,
    String? details,
  }) async {
    if (_repo == null) return;
    await _repo!.submitReport(
      reason: reason,
      listingId: listingId,
      reportedUserId: reportedUserId,
      details: details,
    );
  }

  // ── Wizard ───────────────────────────────────────────────────────────────────

  /// Opens the system image picker and appends up to (8 − current count)
  /// images to [postImagePaths]. Notifies listeners so the wizard rebuilds.
  Future<void> pickListingImages(BuildContext context) async {
    final remaining = 8 - postImagePaths.length;
    if (remaining <= 0) return;

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );
    } catch (e) {
      listingImageUploadError = e.toString();
      notifyListeners();
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final paths = result.files
        .take(remaining)
        .map((f) => f.path)
        .whereType<String>()
        .toList();

    postImagePaths = [...postImagePaths, ...paths];
    postMainPhotoAttached = postImagePaths.isNotEmpty;
    listingImageUploadError = null;
    notifyListeners();
  }

  /// Removes the picked image at [index] from the wizard image list.
  void removeListingImage(int index) {
    if (index < 0 || index >= postImagePaths.length) return;
    postImagePaths = List.from(postImagePaths)..removeAt(index);
    postMainPhotoAttached = postImagePaths.isNotEmpty;
    notifyListeners();
  }
  void resetWizard() {
    postStep = 1;
    postTitle = '';
    postPrice = '';
    postDescription = '';
    postPhysicalAddress = '';
    postMainPhotoAttached = false;
    postImagePaths = [];
    listingImageUploadError = null;
    isUploadingListingImages = false;
    postCondition = '';
    postSpec1 = '';
    postSpec2 = '';
    postSpec3 = '';
    postSpec4 = '';
    notifyListeners();
  }

  Future<void> submitPost() async {
    final titleStr = postTitle.trim().isEmpty
        ? 'Untitled $postCategory Listing'
        : postTitle.trim();
    final priceStr = postPrice.trim().isEmpty
        ? 'Contact for price'
        : (postPrice.startsWith('ETB') || postPrice.startsWith(r'$'))
        ? postPrice.trim()
        : 'ETB ${postPrice.trim()}';
    final descStr = postDescription.trim().isEmpty
        ? 'No description provided.'
        : postDescription.trim();

    final sellerName = profile?.displayName ?? 'Me';
    final sellerImage = profile?.avatarUrl ?? '';
    final userId = currentUser?.id ?? '';

    try {
      if (_repo == null) {
        dataError = 'Supabase unavailable';
        notifyListeners();
        return;
      }

      // ── 1. Upload picked images to Cloudinary ──────────────────────────
      // Use a temporary listing ID for the public_id path; replaced after insert.
      final tempListingId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
      final uploadedUrls = <String>[];
      final errors = <String>[];

      if (postImagePaths.isNotEmpty) {
        isUploadingListingImages = true;
        listingImageUploadError = null;
        notifyListeners();

        for (int i = 0; i < postImagePaths.length; i++) {
          final file = File(postImagePaths[i]);
          if (!await file.exists()) continue;
          final result = await CloudinaryUploadService.instance.uploadListingImage(
            imageFile: file,
            userId: userId,
            listingId: tempListingId,
            index: i,
          );
          switch (result) {
            case CloudinaryUploadSuccess(:final secureUrl):
              uploadedUrls.add(secureUrl);
            case CloudinaryUploadFailure(:final message):
              errors.add(message);
          }
        }

        isUploadingListingImages = false;
        if (errors.isNotEmpty) {
          listingImageUploadError =
              '${errors.length} image(s) failed to upload';
          notifyListeners();
        }
      }

      // Use first Cloudinary URL as the primary imageUrl; fall back to default.
      final primaryImageUrl = uploadedUrls.isNotEmpty
          ? uploadedUrls.first
          : _defaultImageForCategory(postCategory);

      // ── 2. Insert listing into Supabase ────────────────────────────────
      final newListing = await _repo!.createListing(
        category: postCategory,
        title: titleStr,
        price: priceStr,
        imageUrl: primaryImageUrl,
        location: '${postLocation.trim()}, Jigjiga',
        conditionOrStatus: postCondition.trim().isEmpty ? 'Available' : postCondition.trim(),
        description: descStr,
        spec1Label: _specLabel1(postCategory),
        spec1Value: postSpec1.trim().isEmpty
            ? _specDefault1(postCategory)
            : postSpec1.trim(),
        spec2Label: _specLabel2(postCategory),
        spec2Value: postSpec2.trim().isEmpty
            ? _specDefault2(postCategory)
            : postSpec2.trim(),
        spec3Label: _specLabel3(postCategory),
        spec3Value: postSpec3.trim().isEmpty
            ? _specDefault3(postCategory)
            : postSpec3.trim(),
        spec4Label: _specLabel4(postCategory),
        spec4Value: postSpec4.trim().isEmpty
            ? _specDefault4(postCategory)
            : postSpec4.trim(),
        sellerName: sellerName,
        sellerImage: sellerImage,
        sellerPhone: profile?.phone,
        originalLanguage: locale,
        imageUrls: uploadedUrls,
      );

      allListings.insert(0, newListing);
      resetWizard();
      selectedCategory = postCategory;
      navigationStack
        ..clear()
        ..add(HomeScreenRoute())
        ..add(CategoryListScreenRoute(postCategory));
      notifyListeners();

      // ── 3. Fire-and-forget translation ────────────────────────────────
      TranslationService.instance.scheduleTranslation(
        listingId: newListing.id,
        title: titleStr,
        description: descStr,
        originalLanguage: locale,
      );
    } catch (e) {
      isUploadingListingImages = false;
      dataError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Auth ─────────────────────────────────────────────────────────────────────

  /// Puts the app into guest/browse mode without wiping first-install flags.
  ///
  /// Called after:
  ///   • Explicit sign-out
  ///   • tokenRefreshException (refresh token expired or network exhausted)
  ///
  /// When [clearOnboardingData] is true (used only on hard-reset / account
  /// deletion paths) the onboarding flags are also erased so the first-install
  /// flow re-runs.  For normal logout/expiry this should be false so the user
  /// lands on the Home screen rather than the auth onboarding flow.
  Future<void> _enterGuestMode({bool clearOnboardingData = false}) async {
    if (clearOnboardingData) {
      await app_local.LocalStorage.clearLanguage();
      await app_local.LocalStorage.clearSessionRestored();
      await app_local.LocalStorage.clearOnboardingComplete();
    }
    await app_local.LocalStorage.clearProfileCache();
    _repo = null;
    profile = null;
    allListings = [];
    chatSessions = [];
    navigationStack
      ..clear()
      ..add(HomeScreenRoute());
    // Stay on the ready shell — the user can browse as a guest.
    onboardingPhase = OnboardingPhase.ready;
    initError = null;
    dataError = null;
    notifyListeners();
  }

  /// Legacy hard-reset used only by the error-recovery path in _initialize.
  /// Wipes everything and forces the first-install auth flow.
  Future<void> _resetAfterAuthStateChange() async {
    await app_local.LocalStorage.clearLanguage();
    await app_local.LocalStorage.clearSessionRestored();
    await app_local.LocalStorage.clearOnboardingComplete();
    await app_local.LocalStorage.clearProfileCache();
    _repo = null;
    profile = null;
    allListings = [];
    chatSessions = [];
    navigationStack
      ..clear()
      ..add(HomeScreenRoute());
    onboardingPhase = OnboardingPhase.auth;
    initError = null;
    dataError = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    final client = AppSupabaseConfig.clientOrNull();
    try {
      if (client != null) {
        await client.auth.signOut();
        // signOut() will emit AuthChangeEvent.signedOut which calls
        // _enterGuestMode(clearOnboardingData: false).  No further action needed
        // here — the event listener handles the state transition.
      } else {
        // No client available — enter guest mode directly.
        await _enterGuestMode(clearOnboardingData: false);
      }
    } catch (e) {
      debugPrint('Sign out failed: $e');
      // Even if the remote sign-out fails, drop to guest mode locally.
      await _enterGuestMode(clearOnboardingData: false);
    }
  }

  /// Routes the user to the AuthScreen so they can sign in or create an account.
  /// [signUpMode] is passed as a query parameter so the auth screen can
  /// pre-select the Sign Up tab when true.
  ///
  /// Called from the soft-gate bottom sheet CTAs.  The auth screen is pushed
  /// onto the navigation stack so Back returns the user to whatever they were
  /// doing.
  void goToAuth({bool signUpMode = false}) {
    // We set onboardingPhase to .auth which causes _RootGate to render
    // AuthScreen on top of the current app shell.  When the user completes
    // sign-in, onFreshAuth() is called which will advance the phase to
    // .language (first-time) or .ready (returning user who lost session).
    //
    // We do NOT clear onboarding flags here — this is a soft navigation into
    // the auth screen, not a first-install trigger.
    onboardingPhase = OnboardingPhase.auth;
    // Store the sign-up mode preference so AuthScreen can read it.
    _pendingSignUpMode = signUpMode;
    notifyListeners();
  }

  /// Whether the auth screen should pre-select the Sign Up tab.
  /// Set by [goToAuth] and read by AuthScreen.
  bool _pendingSignUpMode = false;
  bool get pendingSignUpMode => _pendingSignUpMode;
  void clearPendingSignUpMode() {
    _pendingSignUpMode = false;
    // No notifyListeners needed — called from AuthScreen initState.
  }

  void markOAuthPending() => _pendingOAuthCompletion = true;

  @override
  void dispose() {
    syncService.dispose();
    super.dispose();
  }

  // ── Private helpers ───────────────────────────────────────────────────────────
  String _defaultImageForCategory(String cat) {
    switch (cat) {
      case 'CARS':
        return 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=500&q=80';
      case 'HOUSES':
        return 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=500&q=80';
      case 'LAND':
        return 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=500&q=80';
      case 'OTHERS':
        return 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=500&q=80';
      default:
        return 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=500&q=80';
    }
  }

  String _specLabel1(String cat) => cat == 'CARS'
      ? 'Year'
      : cat == 'HOUSES'
      ? 'Bedrooms'
      : cat == 'LAND'
      ? 'Size'
      : cat == 'OTHERS'
      ? 'Detail 1'
      : 'Category';
  String _specDefault1(String cat) => cat == 'CARS'
      ? '2023'
      : cat == 'HOUSES'
      ? '3 Bed'
      : cat == 'LAND'
      ? '500 sqm'
      : cat == 'OTHERS'
      ? ''
      : 'Worker';

  String _specLabel2(String cat) => cat == 'CARS'
      ? 'Mileage'
      : cat == 'HOUSES'
      ? 'Bathrooms'
      : cat == 'LAND'
      ? 'Land Use'
      : cat == 'OTHERS'
      ? 'Detail 2'
      : 'Experience';
  String _specDefault2(String cat) => cat == 'CARS'
      ? '5,000 km'
      : cat == 'HOUSES'
      ? '2 Bath'
      : cat == 'LAND'
      ? 'Residential'
      : cat == 'OTHERS'
      ? ''
      : '3 years';

  String _specLabel3(String cat) => cat == 'CARS'
      ? 'Transmission'
      : cat == 'HOUSES'
      ? 'Area'
      : cat == 'LAND'
      ? 'Title Deed'
      : cat == 'OTHERS'
      ? 'Detail 3'
      : 'Skills';
  String _specDefault3(String cat) => cat == 'CARS'
      ? 'Automatic'
      : cat == 'HOUSES'
      ? '150m²'
      : cat == 'LAND'
      ? 'Available'
      : cat == 'OTHERS'
      ? ''
      : 'General Support';

  String _specLabel4(String cat) => cat == 'CARS'
      ? 'Fuel Type'
      : cat == 'HOUSES'
      ? 'Security'
      : cat == 'LAND'
      ? 'Road Access'
      : cat == 'OTHERS'
      ? 'Detail 4'
      : 'Status';
  String _specDefault4(String cat) => cat == 'CARS'
      ? 'Petrol'
      : cat == 'HOUSES'
      ? '24/7'
      : cat == 'LAND'
      ? 'Yes'
      : cat == 'OTHERS'
      ? ''
      : 'Verified';
}

/// Makes [KoolanAppState] accessible anywhere in the widget tree.
class KoolanAppStateScope extends InheritedNotifier<KoolanAppState> {
  const KoolanAppStateScope({
    super.key,
    required KoolanAppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static KoolanAppState of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<KoolanAppStateScope>();
    assert(scope != null, 'No KoolanAppStateScope found in context');
    return scope!.notifier!;
  }
}
