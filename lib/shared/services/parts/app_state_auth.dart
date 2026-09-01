// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Auth & private helpers ────────────────────────────────────────────────────

extension AppStateAuth on OnemarketAppState {
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
      // Detach the device from the current account before signing out. Keep
      // the local FCM registration so the next account can claim the current
      // token without unnecessary token rotation.
      await _detachPushTokenFromAccount();

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

  /// Permanently deletes the signed-in account (Play Store requirement).
  ///
  /// Calls the `delete_own_account` RPC (migration 031), then clears local
  /// session state. Throws on failure so the UI can show an error.
  Future<void> deleteAccount() async {
    final client = AppSupabaseConfig.clientOrNull();
    if (client == null || client.auth.currentUser == null) {
      throw StateError('Not signed in');
    }
    try {
      await client.rpc('delete_own_account');
    } catch (e, st) {
      ErrorReporter.recordError(e, st, reason: 'delete_account');
      rethrow;
    }
    try {
      await client.auth.signOut();
    } catch (_) {
      // Auth user may already be gone; force local guest mode.
    }
    await _enterGuestMode(clearOnboardingData: true);
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

  /// Latest OAuth redirect failure, if any (e.g. provider withheld email).
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
  /// Some providers fail with "Error getting user email from external
  /// provider" when email permission is denied — without email, Supabase
  /// cannot link the identity to an existing same-email profile.
  void reportOAuthFailure(Object error) {
    if (!_pendingOAuthCompletion && onboardingPhase != OnboardingPhase.auth) {
      return;
    }
    _pendingOAuthCompletion = false;
    final text = error is AuthException ? error.message : error.toString();
    final lower = text.toLowerCase();
    final isEmailIssue =
        lower.contains('email') ||
        lower.contains('external provider') ||
        lower.contains('user_email');
    final friendly = isEmailIssue
        ? s.authOAuthEmailRequired
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
      ? s.specLabelYear
      : cat == 'HOUSES'
      ? s.specLabelBedrooms
      : cat == 'LAND'
      ? s.specLabelSize
      : cat == 'OTHERS'
      ? s.specLabelDetail1
      : s.specLabelCategory;

  /// Empty when the user left the field blank — never invent sample values.
  String _specDefault1(String cat) => '';

  String _specLabel2(String cat) => cat == 'CARS'
      ? s.specLabelMileage
      : cat == 'HOUSES'
      ? s.specLabelBathrooms
      : cat == 'LAND'
      ? s.specLabelLandUse
      : cat == 'OTHERS'
      ? s.specLabelDetail2
      : s.specLabelExperience;

  String _specDefault2(String cat) => '';

  String _specLabel3(String cat) => cat == 'CARS'
      ? s.specLabelTransmission
      : cat == 'HOUSES'
      ? s.specLabelArea
      : cat == 'LAND'
      ? s.specLabelTitleDeed
      : cat == 'OTHERS'
      ? s.specLabelDetail3
      : s.specLabelSkills;

  String _specDefault3(String cat) => '';

  String _specLabel4(String cat) => cat == 'CARS'
      ? s.specLabelFuelType
      : cat == 'HOUSES'
      ? s.specLabelSecurity
      : cat == 'LAND'
      ? s.specLabelRoadAccess
      : cat == 'OTHERS'
      ? s.specLabelDetail4
      : s.specLabelStatus;

  String _specDefault4(String cat) => '';
}
