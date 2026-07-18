import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/router/routes.dart';
import '../models/app_strings.dart';
import '../models/chat.dart';
import '../models/listing.dart';
import '../models/profile.dart';
import '../models/syncable_entity.dart';
import 'local_storage.dart' as app_local;
import 'offline/sync_service.dart';
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

          if (event.event == AuthChangeEvent.signedOut) {
            await _resetAfterAuthStateChange();
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

  /// Enqueues a profile edit through the offline-first sync queue.
  /// Updates local [profile] immediately with [SyncStatus.pending] so the UI
  /// can show pending → synced → failed in real time.
  Future<void> submitProfileUpdate({
    required String displayName,
    required String bio,
    required String phone,
    required String city,
  }) async {
    final current = profile;
    if (current == null) return;

    final now = DateTime.now();

    // Optimistic local update — mark pending immediately.
    profile = current.copyWith(
      displayName: displayName,
      bio: bio,
      phone: phone,
      city: city,
      syncStatus: SyncStatus.pending,
      localUpdatedAt: now,
    );
    notifyListeners();

    // Payload uses Supabase column names (snake_case) to match _pushEntry.
    final payload = <String, dynamic>{
      'display_name': displayName,
      'bio': bio,
      'phone': phone,
      'city': city,
      'updated_at': now.toIso8601String(),
    };

    try {
      await syncService.enqueueProfileEdit(
        userId: current.id,
        payload: payload,
        localUpdatedAt: now,
      );
      // syncService.requestSync() is called inside enqueueProfileEdit.
      // After sync completes the queue entry is deleted; update local profile
      // to synced so the badge reflects the final state.
      profile = profile?.copyWith(syncStatus: SyncStatus.synced);
    } catch (e) {
      profile = profile?.copyWith(syncStatus: SyncStatus.failed);
      dataError = e.toString();
    }
    notifyListeners();
  }

  Future<void> setLocale(String newLocale) async {
    locale = newLocale;
    // 1. Persist to Hive immediately — available offline on next cold start.
    await app_local.LocalStorage.saveLanguage(newLocale);
    // 2. Update in-memory profile optimistically.
    profile = profile?.copyWith(
      language: newLocale,
      syncStatus: SyncStatus.pending,
    );
    // 3. Enqueue through SyncService so it reaches Supabase with retry/backoff,
    //    exactly like submitProfileUpdate does for other profile fields.
    if (isSignedIn && profile != null) {
      final now = DateTime.now();
      try {
        await syncService.enqueueProfileEdit(
          userId: profile!.id,
          payload: {'language': newLocale, 'updated_at': now.toIso8601String()},
          localUpdatedAt: now,
        );
        profile = profile?.copyWith(syncStatus: SyncStatus.synced);
      } catch (e) {
        profile = profile?.copyWith(syncStatus: SyncStatus.failed);
        dataError = e.toString();
      }
    }
    notifyListeners();
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
  List<ChatSession> chatSessions = [];

  // ── Post-wizard state ────────────────────────────────────────────────────────
  int postStep = 1;
  String postCategory = 'CARS';
  String postTitle = '';
  String postPrice = '';
  String postDescription = '';
  String postLocation = 'Kebele 06';
  String postPhysicalAddress = '';
  bool postMainPhotoAttached = false;
  String postSpec1 = '';
  String postSpec2 = '';
  String postSpec3 = '';
  String postSpec4 = '';

  // ── Initialization ──────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    debugPrint('[AUTH] _initialize started at ${t0}ms');
    initError = null;
    try {
      final savedLang = await app_local.LocalStorage.getLanguage();
      if (savedLang != null) locale = savedLang;

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
        onboardingPhase = OnboardingPhase.auth;
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
      onboardingPhase = OnboardingPhase.auth;
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
    if (_repo == null) {
      onboardingPhase = OnboardingPhase.auth;
      notifyListeners();
      return;
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
      // Chat sessions are not critical — don't block on failure.
      try {
        chatSessions = await _repo!.fetchChatSessions();
      } catch (e) {
        debugPrint('fetchChatSessions failed: $e');
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
    if (allListings.isNotEmpty) {
      // Already have data in memory — silent failure, no banner needed.
      return;
    }
    final cached = await app_local.LocalStorage.getListingsCache();
    if (cached != null && cached.isNotEmpty) {
      final userId = currentUser?.id;
      allListings = cached
          .map(
            (json) => Listing.fromJson(
              json,
              isSaved: json['is_saved'] as bool? ?? false,
              isOwnedByCurrentUser: json['seller_id'] == userId,
            ),
          )
          .toList();
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

  Listing? getListingById(String id) {
    try {
      return allListings.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
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
  void resetWizard() {
    postStep = 1;
    postTitle = '';
    postPrice = '';
    postDescription = '';
    postPhysicalAddress = '';
    postMainPhotoAttached = false;
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

    final imageStr = _defaultImageForCategory(postCategory);
    final sellerName = profile?.displayName ?? 'Me';
    final sellerImage = profile?.avatarUrl ?? '';

    try {
      if (_repo == null) {
        dataError = 'Supabase unavailable';
        notifyListeners();
        return;
      }
      final newListing = await _repo!.createListing(
        category: postCategory,
        title: titleStr,
        price: priceStr,
        imageUrl: imageStr,
        location: '${postLocation.trim()}, Jigjiga',
        conditionOrStatus: 'Available',
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
        originalLanguage: locale,
      );

      allListings.insert(0, newListing);
      resetWizard();
      selectedCategory = postCategory;
      navigationStack
        ..clear()
        ..add(HomeScreenRoute())
        ..add(CategoryListScreenRoute(postCategory));
      notifyListeners();

      // ── Fire-and-forget translation after the listing is already live ───────
      // Only title and description are translated — never price, spec values,
      // location, phone numbers, or any structured/numeric field.
      TranslationService.instance.scheduleTranslation(
        listingId: newListing.id,
        title: titleStr,
        description: descStr,
        originalLanguage: locale,
      );
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Auth ─────────────────────────────────────────────────────────────────────
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
      }
    } catch (e) {
      debugPrint('Sign out failed: $e');
    } finally {
      await _resetAfterAuthStateChange();
    }
  }

  void markOAuthPending() => _pendingOAuthCompletion = true;

  /// Skips real authentication for demo/simulation — no Supabase call needed.
  Future<void> simulateAuth() async {
    profile = const UserProfile(
      id: 'demo-user',
      displayName: 'Demo User',
      rating: 5.0,
      reviewsCount: 0,
    );
    onboardingPhase = OnboardingPhase.language;
    notifyListeners();
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
      : 'Category';
  String _specDefault1(String cat) => cat == 'CARS'
      ? '2023'
      : cat == 'HOUSES'
      ? '3 Bed'
      : cat == 'LAND'
      ? '500 sqm'
      : 'Worker';

  String _specLabel2(String cat) => cat == 'CARS'
      ? 'Mileage'
      : cat == 'HOUSES'
      ? 'Bathrooms'
      : cat == 'LAND'
      ? 'Land Use'
      : 'Experience';
  String _specDefault2(String cat) => cat == 'CARS'
      ? '5,000 km'
      : cat == 'HOUSES'
      ? '2 Bath'
      : cat == 'LAND'
      ? 'Residential'
      : '3 years';

  String _specLabel3(String cat) => cat == 'CARS'
      ? 'Transmission'
      : cat == 'HOUSES'
      ? 'Area'
      : cat == 'LAND'
      ? 'Title Deed'
      : 'Skills';
  String _specDefault3(String cat) => cat == 'CARS'
      ? 'Automatic'
      : cat == 'HOUSES'
      ? '150m²'
      : cat == 'LAND'
      ? 'Available'
      : 'General Support';

  String _specLabel4(String cat) => cat == 'CARS'
      ? 'Fuel Type'
      : cat == 'HOUSES'
      ? 'Security'
      : cat == 'LAND'
      ? 'Road Access'
      : 'Status';
  String _specDefault4(String cat) => cat == 'CARS'
      ? 'Petrol'
      : cat == 'HOUSES'
      ? '24/7'
      : cat == 'LAND'
      ? 'Yes'
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
