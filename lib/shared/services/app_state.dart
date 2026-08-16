import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/errors/safe_parse.dart';
import '../../core/router/routes.dart';
import 'cloudinary_upload_service.dart';
import '../models/app_strings.dart';
import '../models/application.dart';
import '../models/chat.dart';
import '../models/hiring_post.dart';
import '../models/home_promo.dart';
import '../models/koolan_cities.dart';
import '../models/listing.dart';
import '../models/profile.dart';
import '../models/service.dart';
import '../models/service_review.dart';
import '../models/syncable_entity.dart';
import 'local_storage.dart' as app_local;
import 'marketplace_repository.dart';
import 'offline/hive_sync_store.dart' hide SyncStatus;
import 'offline/sync_service.dart';
import 'sync_status.dart';
import 'permission_service.dart';
import 'recommendation_engine.dart';
import 'supabase_repository.dart';
import 'translation_service.dart';
import 'cv_upload_service.dart';
import 'image_prefetch_service.dart';
import 'network_monitor.dart';
import 'search_index_service.dart';

part 'parts/app_state_profile.dart';
part 'parts/app_state_init.dart';
part 'parts/app_state_data.dart';
part 'parts/app_state_services.dart';
part 'parts/app_state_hiring.dart';
part 'parts/app_state_reviews.dart';
part 'parts/app_state_chat.dart';
part 'parts/app_state_wizard.dart';
part 'parts/app_state_auth.dart';

enum NotifPushToggleResult {
  enabled,
  disabled,
  permissionDenied,
}

enum OnboardingPhase {
  initializing,
  auth,
  language,
  profileSetup, // OAuth users missing name/phone — shown after language
  location,
  goal,
  ready,
}

/// Central application state. Shared via [KoolanAppStateScope].
class KoolanAppState extends ChangeNotifier {
  KoolanAppState({
    bool initialDarkMode = false,
    String initialLocale = 'en',
  }) {
    // Apply pre-loaded prefs immediately so the very first frame renders
    // with the correct theme and language — no flash of wrong defaults.
    isDarkMode = initialDarkMode;
    locale = initialLocale;

    syncService = SyncService(this);
    // When the SyncService discards a stale queue entry (LWW conflict), surface
    // it through dataError so the SnackBar listener in _ShellScaffold picks it
    // up.
    syncService.onDiscard = (entityType, entityId) {
      dataError = s.errorSyncConflict;
      notifyListeners();
    };
    syncService.onCorrupt = (entityType, entityId) {
      dataError = s.errorSyncCorrupt;
      notifyListeners();
    };
    final client = AppSupabaseConfig.clientOrNull();
    if (client != null) {
      try {
        _repo = SupabaseRepository(client);
        if (kDebugMode) debugPrint('Supabase repository created');
      } catch (e, st) {
        ErrorReporter.recordError(e, st, reason: 'repo_create');
        _repo = null;
      }

      try {
        client.auth.onAuthStateChange.listen(
          (event) async {
            if (kDebugMode) debugPrint('Auth event: ${event.event}');

            if (event.event == AuthChangeEvent.initialSession) {
              if (kDebugMode) {
                debugPrint(
                  '[AUTH] initialSession received at '
                  '${DateTime.now().millisecondsSinceEpoch}ms',
                );
              }
              if (!_sessionReadyCompleter.isCompleted) {
                _sessionReadyCompleter.complete(event.session);
              }
              return;
            }

            if (event.event == AuthChangeEvent.signedIn &&
                event.session != null) {
              _pendingOAuthCompletion = false;
              _authError = null;
              final uid = event.session?.user.id;
              if (uid != null) unawaited(ErrorReporter.setUserId(uid));
              if (onboardingPhase == OnboardingPhase.auth ||
                  onboardingPhase == OnboardingPhase.initializing) {
                await onFreshAuth();
              } else {
                // Guest / in-app OAuth (Facebook auth-gate): posts/services
                // resolve via currentUser.id, but profile was never loaded.
                await hydrateSessionProfile();
              }
              return;
            }

            if (event.event == AuthChangeEvent.tokenRefreshed) {
              if (kDebugMode) {
                debugPrint('[AUTH] Token silently refreshed — session extended');
              }
              return;
            }

            if (event.event == AuthChangeEvent.signedOut) {
              if (kDebugMode) {
                debugPrint('[AUTH] signedOut event — entering guest mode');
              }
              unawaited(ErrorReporter.setUserId(null));
              await _enterGuestMode(clearOnboardingData: false);
              return;
            }

            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            ErrorReporter.recordError(
              error,
              stackTrace,
              reason: 'auth_stream',
            );
            reportOAuthFailure(error);
          },
        );
      } catch (e, st) {
        ErrorReporter.recordError(e, st, reason: 'auth_listener_setup');
        if (!_sessionReadyCompleter.isCompleted) {
          _sessionReadyCompleter.complete(null);
        }
      }
    } else {
      if (kDebugMode) {
        debugPrint('Supabase not initialized yet; skipping repo/auth setup');
      }
      _repo = null;
      if (!_sessionReadyCompleter.isCompleted) {
        _sessionReadyCompleter.complete(null);
      }
    }
    _initialize();
  }

  /// Maps [error] to a user-safe [dataError] string. Never stores raw
  /// exception text. Triggers clean sign-out on session expiry.
  void reportDataError(Object error, [StackTrace? stack]) {
    unawaited(ErrorReporter.recordError(error, stack));
    if (AppError.requiresReauth(error)) {
      unawaited(handleSessionExpired());
      return;
    }
    dataError = ErrorMapper.userMessage(error, s);
  }

  /// Sign out cleanly and surface a session-expired toast.
  Future<void> handleSessionExpired() async {
    await signOut();
    dataError = s.errorSessionExpired;
    notifyListeners();
  }

  SupabaseRepository? _repo;
  /// Read-only anon repo used for guest browsing (pagination load-more).
  SupabaseRepository? _anonRepo;

  /// Phase 1: local-first marketplace data layer (lazy-initialised when _repo
  /// or _anonRepo becomes available).
  MarketplaceRepository? _marketplaceRepo;

  /// Completes when Supabase fires [AuthChangeEvent.initialSession].
  final Completer<Session?> _sessionReadyCompleter = Completer<Session?>();

  bool _pendingOAuthCompletion = false;
  /// Surfaced OAuth redirect failures (e.g. Facebook missing email).
  String? _authError;
  late final SyncService syncService;

  // ── Auth & onboarding ─────────────────────────────────────────────────────────
  OnboardingPhase onboardingPhase = OnboardingPhase.initializing;
  String? onboardingGoal;
  bool locationPermissionGranted = false;

  /// Real GPS coordinates populated after the user grants location permission.
  double? deviceLat;
  double? deviceLng;

  UserProfile? profile;
  String? initError;
  bool isLoadingData = false;
  /// True while a background delta/refresh sync is running after local data
  /// was already shown to the user (stale-while-revalidate pattern).
  bool isRefreshing = false;
  /// The timestamp of the last successful full or delta sync from Supabase.
  /// Null until the first successful sync in the current app session.
  DateTime? lastSuccessfulSyncAt;
  String? dataError;

  /// Phase 2: aggregate sync observability — updated by SyncService callbacks.
  final SyncObservabilityStatus syncObservability = SyncObservabilityStatus();

  User? get currentUser {
    try {
      final client = AppSupabaseConfig.clientOrNull();
      return client?.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isSignedIn => currentUser != null;

  // ── Navigation ────────────────────────────────────────────────────────────────
  final List<KoolanScreen> navigationStack = [HomeScreenRoute()];

  // ── Locale ────────────────────────────────────────────────────────────────────
  String locale = 'en';
  AppStrings get s => AppStrings(locale);

  Locale get materialLocale {
    // Flutter's built-in Material localization delegates do not provide
    // translations for the custom 'am'/'so' codes. Falling back to English for
    // framework widgets avoids the runtime crash.
    return const Locale('en');
  }

  // ── Theme ─────────────────────────────────────────────────────────────────────
  bool isDarkMode = false;

  // ── Notification preferences (persisted device-level) ────────────────────────
  bool notifPushEnabled    = true;
  bool notifMessagesEnabled = true;
  bool notifPriceAlerts    = false;
  bool _fcmListenersAttached = false;
  StreamSubscription<String>? _fcmTokenRefreshSub;

  // ── Data Saver (Phase 3) ──────────────────────────────────────────────────────
  /// When true: thumbnails only, no background prefetch, longer sync interval,
  /// chat media tap-to-load. Persisted across launches via LocalStorage.
  bool dataSaverEnabled = false;

  // ── Filters ───────────────────────────────────────────────────────────────────
  String selectedCategory = 'ALL';
  String searchQuery = '';

  // ── Comparison ────────────────────────────────────────────────────────────────
  bool compareModeEnabled = false;
  Set<String> selectedCompareIds = {};

  // ── Data ──────────────────────────────────────────────────────────────────────
  List<Listing> allListings = [];
  List<Service> allServices = [];
  List<ChatSession> chatSessions = [];
  List<HiringPost> allHiringPosts = [];
  List<Application> myApplications = [];
  List<Map<String, dynamic>> notifications = [];

  /// Active promo cards fetched from Supabase.
  /// Empty until loaded; carousel uses hardcoded fallback when empty.
  List<HomePromo> homePromos = [];

  // ── Pagination state ──────────────────────────────────────────────────────────
  bool hasMoreListings    = true;
  bool hasMoreServices    = true;
  bool hasMoreHiringPosts = true;
  bool isLoadingMore      = false;

  /// In-memory set of item IDs the user has viewed this session.
  final Set<String> recentlyViewedIds = {};

  // ── Location CTA ──────────────────────────────────────────────────────────────
  bool _locationCtaReady = false;

  // ── Auth sign-up mode ─────────────────────────────────────────────────────────
  bool _pendingSignUpMode = false;
  bool get pendingSignUpMode => _pendingSignUpMode;

  // ── Post-wizard state ─────────────────────────────────────────────────────────
  int postStep = 1;
  String postCategory = 'CARS';
  String postTitle = '';
  String postPrice = '';
  String postDescription = '';
  String postLocation = 'Kebele 06';
  /// City appended to [postLocation] on submit (East Ethiopia launch cities).
  String postCity = 'Dire Dawa';
  String postPhysicalAddress = '';
  bool postMainPhotoAttached = false;
  /// Condition / status selected by the user (e.g. "Brand New", "For Rent").
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

  // ── Applications cache ────────────────────────────────────────────────────────
  final Map<String, List<Application>> _applicantsCache = {};

  // ── Reviews cache ─────────────────────────────────────────────────────────────
  final Map<String, List<ServiceReview>> _reviewsCache = {};

  /// In-memory cache of public profiles keyed by userId.
  final Map<String, UserProfile> _publicProfileCache = {};

  /// In-memory reviews cache keyed by userId.
  final Map<String, List<ServiceReview>> _userReviewsCache = {};

  // ── Phase 3: local search index cache ─────────────────────────────────────────
  // Holds the last async index query result so getFilteredListings() can use
  // it synchronously inside build().  Reset when searchQuery changes.
  Set<String>? searchIndexResults;
  String lastIndexedQuery = '';

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    unawaited(_fcmTokenRefreshSub?.cancel());
    syncService.dispose();
    super.dispose();
  }
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
