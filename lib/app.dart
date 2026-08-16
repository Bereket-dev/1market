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

  /// When true, [ServiceBootstrap] runs after the first frame so the branded
  /// boot UI appears immediately under the native splash.
  final bool bootstrapPending;

  /// Pre-known failure from a previous bootstrap attempt (tests / hot restart).
  final String? bootstrapErrorCode;

  const KoolanApp({
    super.key,
    this.initialDarkMode = false,
    this.initialLocale = 'en',
    this.bootstrapPending = false,
    this.bootstrapErrorCode,
  });

  @override
  State<KoolanApp> createState() => _KoolanAppState();
}

class _KoolanAppState extends State<KoolanApp> with WidgetsBindingObserver {
  KoolanAppState? _appState;
  String? _bootstrapErrorCode;
  bool _bootstrapPending = false;
  bool _retryingBootstrap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrapErrorCode = widget.bootstrapErrorCode;
    _bootstrapPending = widget.bootstrapPending && _bootstrapErrorCode == null;

    if (_bootstrapPending) {
      unawaited(_runBootstrap());
    } else if (_bootstrapErrorCode == null) {
      _createAppState();
      unawaited(_handleColdStartDeepLink());
    }
  }

  void _createAppState() {
    _appState = KoolanAppState(
      initialDarkMode: widget.initialDarkMode,
      initialLocale: widget.initialLocale,
    );
  }

  Future<void> _runBootstrap() async {
    final result = await ServiceBootstrap.initialize();
    if (!mounted) return;
    if (result.ok) {
      setState(() {
        _bootstrapPending = false;
        _bootstrapErrorCode = null;
        _retryingBootstrap = false;
        _createAppState();
      });
      unawaited(_handleColdStartDeepLink());
    } else {
      setState(() {
        _bootstrapPending = false;
        _bootstrapErrorCode = result.errorCode;
        _retryingBootstrap = false;
      });
    }
  }

  Future<void> _retryBootstrap() async {
    if (_retryingBootstrap) return;
    setState(() {
      _retryingBootstrap = true;
      _bootstrapPending = true;
      _bootstrapErrorCode = null;
    });
    try {
      final result = await ServiceBootstrap.initialize();
      if (!mounted) return;
      if (result.ok) {
        _appState?.dispose();
        setState(() {
          _bootstrapPending = false;
          _bootstrapErrorCode = null;
          _retryingBootstrap = false;
          _createAppState();
        });
        unawaited(_handleColdStartDeepLink());
      } else {
        setState(() {
          _bootstrapPending = false;
          _bootstrapErrorCode = result.errorCode;
          _retryingBootstrap = false;
        });
      }
    } catch (e, st) {
      await ErrorReporter.recordError(e, st, reason: 'bootstrap_retry');
      if (!mounted) return;
      setState(() {
        _bootstrapPending = false;
        _bootstrapErrorCode = 'supabase_init_failed';
        _retryingBootstrap = false;
      });
    }
  }

  /// Cold-start OAuth deep link: supabase may already have a session.
  Future<void> _handleColdStartDeepLink() async {
    await Future<void>.delayed(Duration.zero);
    final appState = _appState;
    if (appState == null) return;
    try {
      final client = AppSupabaseConfig.clientOrNull();
      if (client == null) return;
      final session = client.auth.currentSession;
      if (session != null &&
          appState.onboardingPhase == OnboardingPhase.initializing) {
        if (kDebugMode) {
          debugPrint('[DeepLink] Cold-start session found — onFreshAuth');
        }
        await appState.onFreshAuth();
      }
    } catch (e, st) {
      await ErrorReporter.recordError(e, st, reason: 'cold_start_deeplink');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState?.dispose();
    super.dispose();
  }

  /// Called whenever the app lifecycle state changes.
  /// On [AppLifecycleState.resumed] we request a sync pass so any items
  /// queued while the app was backgrounded are flushed immediately.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final appState = _appState;
    if (appState == null) return;
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        debugPrint('[KoolanApp] App foregrounded — triggering sync');
      }
      appState.syncService.requestSync();
      unawaited(appState.refreshNotificationPermissionState());
    }
  }

  ThemeMode get _themeMode =>
      widget.initialDarkMode ? ThemeMode.dark : ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('[KoolanApp] build');

    if (_bootstrapPending) {
      return MaterialApp(
        title: 'Koolan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        home: _BrandedBootScreen(locale: widget.initialLocale),
      );
    }

    if (_bootstrapErrorCode != null) {
      return MaterialApp(
        title: 'Koolan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeMode,
        home: _BootstrapFailureScreen(
          retrying: _retryingBootstrap,
          onRetry: _retryBootstrap,
          locale: widget.initialLocale,
        ),
      );
    }

    final appState = _appState!;
    return KoolanAppStateScope(
      notifier: appState,
      child: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          return MaterialApp(
            title: 'Koolan',
            debugShowCheckedModeBanner: false,
            locale: appState.materialLocale,
            supportedLocales: const [
              Locale('en'),
              Locale('am'),
              Locale('so'),
            ],
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
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: _RootGate(appState: appState),
          );
        },
      ),
    );
  }
}
