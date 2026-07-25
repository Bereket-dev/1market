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
    } catch (e) {
      debugPrint('Sign out failed: $e');
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

  void markOAuthPending() => _pendingOAuthCompletion = true;

  void clearOAuthPending() => _pendingOAuthCompletion = false;

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
