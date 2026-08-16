// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Auth & private helpers ────────────────────────────────────────────────────

extension AppStateAuth on KoolanAppState {
  /// Puts the app into guest/browse mode without wiping first-install flags.
  ///
  /// Called after:
  ///   • Explicit sign-out
  ///   • tokenRefreshException (refresh token expired or network exhausted)
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
    onboardingPhase = OnboardingPhase.ready;
    initError = null;
    dataError = null;
    notifyListeners();
    unawaited(loadAllData());
  }

  /// Legacy hard-reset used only by the error-recovery path in _initialize.
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
        // _enterGuestMode(clearOnboardingData: false).
      } else {
        await _enterGuestMode(clearOnboardingData: false);
      }
    } catch (e, st) {
      ErrorReporter.recordError(e, st, reason: 'sign_out');
      await _enterGuestMode(clearOnboardingData: false);
    }
  }

  /// Routes the user to the AuthScreen so they can sign in or create an account.
  void goToAuth({bool signUpMode = false}) {
    onboardingPhase = OnboardingPhase.auth;
    _pendingSignUpMode = signUpMode;
    notifyListeners();
  }

  void clearPendingSignUpMode() {
    _pendingSignUpMode = false;
    // No notifyListeners needed — called from AuthScreen initState.
  }

  void markOAuthPending() {
    _pendingOAuthCompletion = true;
    _authError = null;
  }

  void clearOAuthPending() => _pendingOAuthCompletion = false;

  /// Latest OAuth redirect failure, if any (e.g. Facebook missing email).
  String? get authError => _authError;

  void clearAuthError() {
    if (_authError == null) return;
    _authError = null;
  }

  /// Returns and clears any pending OAuth error so the auth UI can display it.
  String? consumeAuthError() {
    final error = _authError;
    _authError = null;
    return error;
  }

  /// Records an OAuth redirect failure so the auth screen / toast can show it.
  ///
  /// Facebook often fails with "Error getting user email from external
  /// provider" when email permission is denied — without email, Supabase
  /// cannot link the Facebook identity to an existing same-email profile.
  void reportOAuthFailure(Object error) {
    if (!_pendingOAuthCompletion && onboardingPhase != OnboardingPhase.auth) {
      return;
    }
    _pendingOAuthCompletion = false;
    final text = error is AuthException
        ? error.message
        : error.toString();
    final lower = text.toLowerCase();
    final isEmailIssue = lower.contains('email') ||
        lower.contains('external provider') ||
        lower.contains('user_email');
    final friendly = isEmailIssue
        ? s.authFacebookEmailRequired
        : ErrorMapper.userMessage(error, s);
    _authError = friendly;
    // Guest-mode auth gate closes before OAuth returns — use the shell toast.
    if (onboardingPhase == OnboardingPhase.ready) {
      dataError = friendly;
    }
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────────

  /// Returns an empty string when no photo was uploaded.
  /// Listing cards must handle an empty imageUrl gracefully (show placeholder).
  String _defaultImageForCategory(String cat) {
    return ''; // No stock-photo fallback in production.
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

  /// Empty when the user left the field blank — never invent sample values.
  String _specDefault1(String cat) => '';

  String _specLabel2(String cat) => cat == 'CARS'
      ? 'Mileage'
      : cat == 'HOUSES'
      ? 'Bathrooms'
      : cat == 'LAND'
      ? 'Land Use'
      : cat == 'OTHERS'
      ? 'Detail 2'
      : 'Experience';

  String _specDefault2(String cat) => '';

  String _specLabel3(String cat) => cat == 'CARS'
      ? 'Transmission'
      : cat == 'HOUSES'
      ? 'Area'
      : cat == 'LAND'
      ? 'Title Deed'
      : cat == 'OTHERS'
      ? 'Detail 3'
      : 'Skills';

  String _specDefault3(String cat) => '';

  String _specLabel4(String cat) => cat == 'CARS'
      ? 'Fuel Type'
      : cat == 'HOUSES'
      ? 'Security'
      : cat == 'LAND'
      ? 'Road Access'
      : cat == 'OTHERS'
      ? 'Detail 4'
      : 'Status';

  String _specDefault4(String cat) => '';
}
