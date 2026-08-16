import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/bootstrap/service_bootstrap.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/colors.dart';
import 'core/errors/error_reporter.dart';
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
import 'shared/models/app_strings.dart';
import 'shared/widgets/sync_debug_overlay.dart';
import 'shared/widgets/toast_banner.dart';
part 'widgets/app_shell.dart';
part 'widgets/app_nav.dart';
part 'widgets/app_gate.dart';

class KoolanApp extends StatefulWidget {
  final bool initialDarkMode;
  final String initialLocale;

  /// Stable bootstrap failure code from [ServiceBootstrap], or null when OK.
  final String? bootstrapErrorCode;

  const KoolanApp({
    super.key,
    this.initialDarkMode = false,
    this.initialLocale = 'en',
    this.bootstrapErrorCode,
  });

  @override
  State<KoolanApp> createState() => _KoolanAppState();
}

class _KoolanAppState extends State<KoolanApp> with WidgetsBindingObserver {
  late KoolanAppState _appState;
  String? _bootstrapErrorCode;
  bool _retryingBootstrap = false;

  @override
  void initState() {
    super.initState();
    _bootstrapErrorCode = widget.bootstrapErrorCode;
    _appState = KoolanAppState(
      initialDarkMode: widget.initialDarkMode,
      initialLocale: widget.initialLocale,
    );
    WidgetsBinding.instance.addObserver(this);
    if (_bootstrapErrorCode == null) {
      _handleColdStartDeepLink();
    }
  }

  Future<void> _retryBootstrap() async {
    if (_retryingBootstrap) return;
    setState(() => _retryingBootstrap = true);
    try {
      final result = await ServiceBootstrap.initialize();
      if (!mounted) return;
      if (result.ok) {
        _appState.dispose();
        setState(() {
          _bootstrapErrorCode = null;
          _retryingBootstrap = false;
          _appState = KoolanAppState(
            initialDarkMode: widget.initialDarkMode,
            initialLocale: widget.initialLocale,
          );
        });
        _handleColdStartDeepLink();
      } else {
        setState(() {
          _bootstrapErrorCode = result.errorCode;
          _retryingBootstrap = false;
        });
      }
    } catch (e, st) {
      await ErrorReporter.recordError(e, st, reason: 'bootstrap_retry');
      if (!mounted) return;
      setState(() {
        _bootstrapErrorCode = 'supabase_init_failed';
        _retryingBootstrap = false;
      });
    }
  }

  /// Cold-start OAuth deep link: supabase may already have a session.
  Future<void> _handleColdStartDeepLink() async {
    await Future<void>.delayed(Duration.zero);
    try {
      final client = AppSupabaseConfig.clientOrNull();
      if (client == null) return;
      final session = client.auth.currentSession;
      if (session != null &&
          _appState.onboardingPhase == OnboardingPhase.initializing) {
        if (kDebugMode) {
          debugPrint('[DeepLink] Cold-start session found — onFreshAuth');
        }
        await _appState.onFreshAuth();
      }
    } catch (e, st) {
      await ErrorReporter.recordError(e, st, reason: 'cold_start_deeplink');
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
      if (kDebugMode) {
        debugPrint('[KoolanApp] App foregrounded — triggering sync');
      }
      _appState.syncService.requestSync();
      unawaited(_appState.refreshNotificationPermissionState());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('[KoolanApp] build');
    if (_bootstrapErrorCode != null) {
      return MaterialApp(
        title: 'Koolan – East Ethiopia Marketplace',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: widget.initialDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: _BootstrapFailureScreen(
          retrying: _retryingBootstrap,
          onRetry: _retryBootstrap,
        ),
      );
    }
    return KoolanAppStateScope(
      notifier: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          return MaterialApp(
            title: 'Koolan – East Ethiopia Marketplace',
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
