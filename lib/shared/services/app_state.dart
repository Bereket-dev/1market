import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/router/routes.dart';
import '../models/app_strings.dart';
import '../models/chat.dart';
import '../models/listing.dart';
import '../models/profile.dart';
import 'local_storage.dart' as app_local;
import 'supabase_repository.dart';

enum OnboardingPhase { initializing, auth, language, ready }

/// Central application state. Shared via [KoolanAppStateScope].
class KoolanAppState extends ChangeNotifier {
  KoolanAppState() {
    final client = AppSupabaseConfig.clientOrNull();
    if (client != null) {
      try {
        _repo = SupabaseRepository(client);
        print('Supabase repository created');
      } catch (e, st) {
        print('Supabase repository unavailable: $e');
        print(st);
        _repo = null;
      }

      try {
        client.auth.onAuthStateChange.listen((event) async {
          if (event.event == AuthChangeEvent.signedIn &&
              event.session != null &&
              _pendingOAuthCompletion) {
            _pendingOAuthCompletion = false;
            await onFreshAuth();
          }
          notifyListeners();
        });
      } catch (e, st) {
        print('Auth listener setup failed: $e');
        print(st);
      }
    } else {
      print('Supabase not initialized yet; skipping repo/auth setup');
      _repo = null;
    }
    _initialize();
  }

  SupabaseRepository? _repo;

  bool _pendingOAuthCompletion = false;

  // ── Auth & onboarding ───────────────────────────────────────────────────────
  OnboardingPhase onboardingPhase = OnboardingPhase.initializing;
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
    switch (locale) {
      case 'am':
        return const Locale('am');
      case 'so':
        return const Locale('so');
      default:
        return const Locale('en');
    }
  }

  Future<void> setLocale(String newLocale) async {
    locale = newLocale;
    await app_local.LocalStorage.saveLanguage(newLocale);
    if (isSignedIn && _repo != null) {
      try {
        await _repo!.updateLanguage(newLocale);
        profile = profile?.copyWith(language: newLocale);
      } catch (e) {
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
    print('Auth check started');
    print('Repo available: ${_repo != null}');
    initError = null;
    try {
      final savedLang = await app_local.LocalStorage.getLanguage();
      if (savedLang != null) locale = savedLang;

      if (!isSignedIn || _repo == null) {
        onboardingPhase = OnboardingPhase.auth;
        notifyListeners();
        return;
      }

      profile = await _repo!.ensureProfile();
      final sessionRestored = await app_local.LocalStorage.wasSessionRestored();

      if (profile?.language != null) {
        locale = profile!.language!;
        await app_local.LocalStorage.saveLanguage(locale);
      }

      if (!sessionRestored || profile?.language == null) {
        onboardingPhase = OnboardingPhase.language;
        notifyListeners();
        return;
      }

      await _enterApp();
    } catch (e) {
      initError = e.toString();
      onboardingPhase = OnboardingPhase.auth;
      notifyListeners();
    } finally {
      print('Auth check finished');
    }
  }

  Future<void> retryInitialization() => _initialize();

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
    onboardingPhase = OnboardingPhase.language;
    notifyListeners();
  }

  Future<void> completeLanguageOnboarding(String language) async {
    await setLocale(language);
    if (_repo != null) {
      await _repo!.updateLanguage(language);
    }
    profile = profile?.copyWith(language: language);
    await app_local.LocalStorage.markSessionRestored();
    await _enterApp();
  }

  Future<void> _enterApp() async {
    onboardingPhase = OnboardingPhase.ready;
    navigationStack
      ..clear()
      ..add(HomeScreenRoute());
    await loadAllData();
    notifyListeners();
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
      allListings = await _repo!.fetchListings();
      chatSessions = await _repo!.fetchChatSessions();
    } catch (e) {
      dataError = e.toString();
    } finally {
      isLoadingData = false;
      notifyListeners();
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
      chatSessions[index] = session.copyWith(
        messages: [...session.messages, msg],
        unreadCount: 0,
      );
      notifyListeners();
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
      rethrow;
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
      );

      allListings.insert(0, newListing);
      resetWizard();
      selectedCategory = postCategory;
      navigationStack
        ..clear()
        ..add(HomeScreenRoute())
        ..add(CategoryListScreenRoute(postCategory));
      notifyListeners();
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Auth ─────────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      final client = AppSupabaseConfig.clientOrNull();
      await client?.auth.signOut();
    } catch (_) {}
    await app_local.LocalStorage.clearLanguage();
    await app_local.LocalStorage.clearSessionRestored();
    profile = null;
    allListings = [];
    chatSessions = [];
    navigationStack
      ..clear()
      ..add(HomeScreenRoute());
    onboardingPhase = OnboardingPhase.auth;
    notifyListeners();
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
