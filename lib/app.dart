import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/colors.dart';
import 'core/router/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/cars/presentation/screens/category_list_screen.dart';
import 'shared/widgets/auth_gate_sheet.dart';
import 'features/chat/presentation/screens/active_chat_screen.dart';
import 'features/chat/presentation/screens/messages_screen.dart';
import 'features/favorites/presentation/screens/saved_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/listings/presentation/screens/listing_detail_screen.dart';
import 'features/listings/presentation/screens/edit_listing_screen.dart';
import 'features/onboarding/screens/auth_screen.dart';
import 'features/onboarding/screens/goal_selection_screen.dart';
import 'features/onboarding/screens/language_screen.dart';
import 'features/onboarding/screens/location_permission_screen.dart';
import 'features/onboarding/screens/profile_setup_screen.dart';
import 'features/post/presentation/screens/post_wizard_screen.dart';
import 'features/profile/presentation/screens/edit_profile_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/profile/presentation/screens/settings_screen.dart';
import 'features/services/presentation/screens/service_browse_screen.dart';
import 'features/services/presentation/screens/service_detail_screen.dart';
import 'features/services/presentation/screens/service_edit_screen.dart';
import 'features/services/presentation/screens/service_management_screen.dart';
import 'features/services/presentation/screens/service_reviews_screen.dart';
import 'features/hiring/presentation/screens/hiring_applicant_list_screen.dart';
import 'features/hiring/presentation/screens/hiring_applicant_detail_screen.dart';
import 'features/hiring/presentation/screens/hiring_browse_screen.dart';
import 'features/hiring/presentation/screens/hiring_detail_screen.dart';
import 'features/hiring/presentation/screens/hiring_edit_screen.dart';
import 'features/hiring/presentation/screens/hiring_management_screen.dart';
import 'features/hiring/presentation/screens/my_applications_screen.dart';
import 'features/hiring/presentation/screens/notifications_screen.dart';
import 'features/listings/presentation/screens/my_listings_screen.dart';
import 'features/profile/presentation/screens/public_profile_screen.dart';
import 'shared/services/app_state.dart';
import 'shared/widgets/toast_banner.dart';
part 'widgets/app_shell.dart';
part 'widgets/app_nav.dart';
part 'widgets/app_gate.dart';

class KoolanApp extends StatefulWidget {
  final bool initialDarkMode;
  final String initialLocale;

  const KoolanApp({
    super.key,
    this.initialDarkMode = false,
    this.initialLocale = 'en',
  });

  @override
  State<KoolanApp> createState() => _KoolanAppState();
}

class _KoolanAppState extends State<KoolanApp> with WidgetsBindingObserver {
  late final KoolanAppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = KoolanAppState(
      initialDarkMode: widget.initialDarkMode,
      initialLocale: widget.initialLocale,
    );
    WidgetsBinding.instance.addObserver(this);
    // Handle the case where the app is cold-started from a deep link
    // (e.g. Facebook OAuth redirect while the app was not running).
    // supabase_flutter v2 uses app_links internally and processes the
    // initial URI automatically, but we trigger a session check here so
    // the auth state stream fires onFreshAuth if a valid PKCE code arrived.
    _handleColdStartDeepLink();
  }

  /// Called once on startup. If the app was launched via a
  /// io.supabase.koolan://login-callback/ deep link (cold start from OAuth
  /// redirect), supabase_flutter will have already exchanged the code by the
  /// time the first frame renders. We listen for the signedIn event in
  /// app_state.dart, but if the event was already emitted before the listener
  /// was attached we check the session explicitly here.
  Future<void> _handleColdStartDeepLink() async {
    // Wait one frame so KoolanAppState has set up its auth listener first.
    await Future<void>.delayed(Duration.zero);
    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      if (session != null &&
          _appState.onboardingPhase == OnboardingPhase.initializing) {
        debugPrint('[DeepLink] Cold-start session found — calling onFreshAuth');
        await _appState.onFreshAuth();
      }
    } catch (e) {
      debugPrint('[DeepLink] Cold-start check error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState.dispose();
    super.dispose();
  }

  /// Called whenever the app lifecycle state changes.
  /// On [AppLifecycleState.resumed] we request a sync pass so any items
  /// queued while the app was backgrounded are flushed immediately.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[KoolanApp] App foregrounded — triggering sync');
      _appState.syncService.requestSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('MyApp build');
    return KoolanAppStateScope(
      notifier: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          return MaterialApp(
            title: 'Koolan – Jigjiga Marketplace',
            debugShowCheckedModeBanner: false,
            locale: _appState.materialLocale,
            supportedLocales: const [Locale('en')],
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale == null) return const Locale('en');
              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
              return const Locale('en');
            },
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: _RootGate(appState: _appState),
          );
        },
      ),
    );
  }
}

// ── Onboarding gate ───────────────────────────────────────────────────────────
