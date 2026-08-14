import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/router/routes.dart';
import 'cloudinary_upload_service.dart';
import '../models/app_strings.dart';
import '../models/application.dart';
import '../models/chat.dart';
import '../models/hiring_post.dart';
import '../models/home_promo.dart';
import '../models/listing.dart';
import '../models/profile.dart';
import '../models/service.dart';
import '../models/service_review.dart';
import '../models/syncable_entity.dart';
import 'local_storage.dart' as app_local;
import 'offline/hive_sync_store.dart' hide SyncStatus;
import 'offline/sync_service.dart';
import 'permission_service.dart';
import 'recommendation_engine.dart';
import 'supabase_repository.dart';
import 'translation_service.dart';
import 'cv_upload_service.dart';

part 'parts/app_state_profile.dart';
part 'parts/app_state_init.dart';
part 'parts/app_state_data.dart';
part 'parts/app_state_services.dart';
part 'parts/app_state_hiring.dart';
part 'parts/app_state_reviews.dart';
part 'parts/app_state_chat.dart';
part 'parts/app_state_wizard.dart';
part 'parts/app_state_auth.dart';

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
        client.auth.onAuthStateChange.listen(
          (event) async {
            debugPrint('Auth event: ${event.event}');

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
                event.session != null) {
              _pendingOAuthCompletion = false;
              _authError = null;
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
              debugPrint('[AUTH] Token silently refreshed — session extended');
              return;
            }

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
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('[AUTH] Auth stream error: $error');
            debugPrint(stackTrace.toString());
            final message = error is AuthException
                ? error.message
                : error.toString();
            reportOAuthFailure(message);
          },
        );
      } catch (e, st) {
        debugPrint('Auth listener setup failed: $e');
        debugPrint(st.toString());
        if (!_sessionReadyCompleter.isCompleted) {
          _sessionReadyCompleter.complete(null);
        }
      }
    } else {
      debugPrint('Supabase not initialized yet; skipping repo/auth setup');
      _repo = null;
      if (!_sessionReadyCompleter.isCompleted) {
        _sessionReadyCompleter.complete(null);
      }
    }
    _initialize();
  }

  SupabaseRepository? _repo;
  /// Read-only anon repo used for guest browsing (pagination load-more).
  SupabaseRepository? _anonRepo;

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

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void dispose() {
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
