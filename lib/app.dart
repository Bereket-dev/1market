import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
import 'features/onboarding/screens/verification_prompt_screen.dart';
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

class KoolanApp extends StatefulWidget {
  const KoolanApp({super.key});

  @override
  State<KoolanApp> createState() => _KoolanAppState();
}

class _KoolanAppState extends State<KoolanApp> with WidgetsBindingObserver {
  late final KoolanAppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = KoolanAppState();
    WidgetsBinding.instance.addObserver(this);
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

class _RootGate extends StatelessWidget {
  final KoolanAppState appState;

  const _RootGate({required this.appState});

  @override
  Widget build(BuildContext context) {
    print('router created');
    switch (appState.onboardingPhase) {
      case OnboardingPhase.initializing:
        return _InitializingScreen(
          error: appState.initError,
          onRetry: appState.retryInitialization,
        );
      case OnboardingPhase.auth:
        return const AuthScreen();
      case OnboardingPhase.language:
        return const LanguageScreen();
      case OnboardingPhase.location:
        return const LocationPermissionScreen();
      case OnboardingPhase.goal:
        return const GoalSelectionScreen();
      case OnboardingPhase.verification:
        return const VerificationPromptScreen();
      case OnboardingPhase.ready:
        return const _AppShell();
    }
  }
}

class _InitializingScreen extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;

  const _InitializingScreen({this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    print('Splash build');
    final cs = Theme.of(context).colorScheme;
    // Use getInheritedWidgetOfExactType (non-registering) here because
    // _InitializingScreen only reads .s strings and never needs to rebuild
    // when appState changes — it is shown exactly once, before the app is
    // ready.  Registering a dependency would add it to the listener set
    // unnecessarily and could contribute to the build-scope assertion crash.
    final appState = context
        .getInheritedWidgetOfExactType<KoolanAppStateScope>()!
        .notifier!;
    final s = appState.s;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error == null) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  s.initLoading,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ] else ...[
                Icon(Icons.error_outline, color: cs.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.error),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: Text(s.initRetry)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Root shell ────────────────────────────────────────────────────────────────

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    // Use getInheritedWidgetOfExactType (non-registering) so that _AppShell
    // itself is NOT added to KoolanAppStateScope's listener set.
    //
    // Why this matters: _AppShell is the root shell widget — it lives above
    // the AnimatedSwitcher that drives all screen transitions.  If it
    // registers as a listener via the normal .of(context) call, every
    // notifyListeners() call (profile saves, sync status updates, etc.) marks
    // _AppShell dirty.  When notifyListeners() fires while AnimatedSwitcher is
    // mid-transition the framework tries to flush the dirty _AppShell element
    // inside a build scope that belongs to the transitioning child, triggering
    // the "Tried to build dirty widget in the wrong build scope" assertion.
    //
    // All parts of the shell that genuinely need live reactivity
    // (_ShellScaffold, _LoadingBarArea) subscribe to
    // appState individually through their own listener — so they
    // each rebuild at the right time in the right scope without pulling
    // _AppShell along with them.
    final appState = context
        .getInheritedWidgetOfExactType<KoolanAppStateScope>()!
        .notifier!;
    // isDarkMode is only needed for the static desktop-layout colours below.
    // It rarely changes (never mid-transition), so a non-registering read is safe.
    final isDark = appState.isDarkMode;

    // _ShellScaffold owns the Scaffold + nav bar + screen switcher and
    // subscribes to appState via ListenableBuilder internally.
    final shell = _ShellScaffold(
      appState: appState,
      onPostFab: () => appState.pushScreen(PostWizardScreenRoute()),
    );

    // On wide screens (desktop / web) centre a phone-sized card.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 600) return shell;

        final desktopBg = isDark
            ? const Color(0xFF060A10)
            : const Color(0xFFE2E8F0);
        final cardBg = isDark ? kDarkBackground : kBackground;

        return Container(
          color: desktopBg,
          alignment: Alignment.center,
          child: Container(
            width: 480,
            height: 850,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: shell,
          ),
        );
      },
    );
  }

  static Widget _screenFor(KoolanScreen screen) {
    if (screen is HomeScreenRoute) {
      return const HomeScreen(key: ValueKey('home'));
    } else if (screen is SavedScreenRoute) {
      return const SavedScreen(key: ValueKey('saved'));
    } else if (screen is MessagesScreenRoute) {
      return const MessagesScreen(key: ValueKey('messages'));
    } else if (screen is ProfileScreenRoute) {
      return const ProfileScreen(key: ValueKey('profile'));
    } else if (screen is CategoryListScreenRoute) {
      return CategoryListScreen(
        key: ValueKey('cat_${screen.category}'),
        categoryName: screen.category,
      );
    } else if (screen is ListingDetailScreenRoute) {
      return ListingDetailScreen(
        key: ValueKey('detail_${screen.listingId}'),
        listingId: screen.listingId,
      );
    } else if (screen is PostWizardScreenRoute) {
      return const PostWizardScreen(key: ValueKey('wizard'));
    } else if (screen is ActiveChatScreenRoute) {
      return ActiveChatScreen(
        key: ValueKey('chat_${screen.sessionIndex}'),
        sessionIndex: screen.sessionIndex,
      );
    } else if (screen is ServiceManagementScreenRoute) {
      return const ServiceManagementScreen(key: ValueKey('services'));
    } else if (screen is ServiceEditScreenRoute) {
      return ServiceEditScreen(
        key: ValueKey('service_edit_${screen.serviceId ?? 'new'}'),
        serviceId: screen.serviceId,
      );
    } else if (screen is ServiceBrowseScreenRoute) {
      return const ServiceBrowseScreen(key: ValueKey('services_browse'));
    } else if (screen is ServiceDetailScreenRoute) {
      return ServiceDetailScreen(
        key: ValueKey('service_detail_${screen.serviceId}'),
        serviceId: screen.serviceId,
      );
    } else if (screen is ServiceReviewsScreenRoute) {
      return ServiceReviewsScreen(
        key: ValueKey('service_reviews_${screen.serviceId}'),
        serviceId: screen.serviceId,
      );
    } else if (screen is HiringManagementScreenRoute) {
      return const HiringManagementScreen(
        key: ValueKey('hiring_management'),
      );
    } else if (screen is HiringEditScreenRoute) {
      return HiringEditScreen(
        key: ValueKey('hiring_edit_${screen.postId ?? 'new'}'),
        postId: screen.postId,
      );
    } else if (screen is HiringApplicantListScreenRoute) {
      return HiringApplicantListScreen(
        key: ValueKey('hiring_applicants_${screen.postId}'),
        postId: screen.postId,
      );
    } else if (screen is HiringApplicantDetailScreenRoute) {
      return HiringApplicantDetailScreen(
        key: ValueKey(
          'hiring_applicant_detail_${screen.applicationId}',
        ),
        applicationId: screen.applicationId,
        postId: screen.postId,
      );
    } else if (screen is HiringBrowseScreenRoute) {
      return const HiringBrowseScreen(
        key: ValueKey('hiring_browse'),
      );
    } else if (screen is HiringDetailScreenRoute) {
      return HiringDetailScreen(
        key: ValueKey('hiring_detail_${screen.postId}'),
        postId: screen.postId,
      );
    } else if (screen is MyApplicationsScreenRoute) {
      return const MyApplicationsScreen(
        key: ValueKey('my_applications'),
      );
    } else if (screen is NotificationsScreenRoute) {
      return const NotificationsScreen(
        key: ValueKey('notifications'),
      );
    } else if (screen is SettingsScreenRoute) {
      return const SettingsScreen(key: ValueKey('settings'));
    } else if (screen is EditProfileScreenRoute) {
      return const EditProfileScreen(key: ValueKey('edit_profile'));
    } else if (screen is MyListingsScreenRoute) {
      return const MyListingsScreen(key: ValueKey('my_listings'));
    } else if (screen is EditListingScreenRoute) {
      return EditListingScreen(
        key: ValueKey('edit_listing_${screen.listingId}'),
        listingId: screen.listingId,
      );
    } else if (screen is PublicProfileScreenRoute) {
      return PublicProfileScreen(
        key: ValueKey('public_profile_${screen.userId}'),
        userId: screen.userId,
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Isolated reactive areas inside _AppShell ──────────────────────────────────
//
// Each of these widgets holds its own ListenableBuilder so that rebuilds are
// scoped to the smallest possible subtree.  _AppShell itself no longer
// registers as a KoolanAppStateScope listener, which prevents the
// "Tried to build dirty widget in the wrong build scope" assertion that fires
// when notifyListeners() is called while AnimatedSwitcher is mid-transition.

/// Owns the Scaffold, bottom nav bar, screen switcher, and loading bar.
/// Subscribes to appState via direct listener in [initState] to show a
/// SnackBar whenever [KoolanAppState.dataError] becomes non-null.
///
/// Converting from StatelessWidget + ListenableBuilder to StatefulWidget lets
/// us use [ScaffoldMessenger.of] safely from within the widget's element (not
/// from inside build), so the SnackBar is always tied to this stable,
/// non-transitioning Scaffold context — never to a child screen that might be
/// in mid-transition.
class _ShellScaffold extends StatefulWidget {
  final KoolanAppState appState;
  final VoidCallback onPostFab;

  const _ShellScaffold({required this.appState, required this.onPostFab});

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold> {
  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onAppStateChanged);
  }

  @override
  void didUpdateWidget(_ShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState != widget.appState) {
      oldWidget.appState.removeListener(_onAppStateChanged);
      widget.appState.addListener(_onAppStateChanged);
    }
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  bool _showingSnackBar = false;

  void _onAppStateChanged() {
    final error = widget.appState.dataError;
    // Only show a SnackBar when a new, distinct error appears.
    // _showingSnackBar guards against the re-entrant call that happens when
    // clearDataError() → notifyListeners() fires back into this method.
    if (!mounted || error == null || _showingSnackBar) return;
    _showingSnackBar = true;

    final s = widget.appState.s;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        action: SnackBarAction(
          label: s.commonRetry,
          onPressed: () {
            widget.appState.clearDataError();
            widget.appState.loadAllData();
          },
        ),
        duration: const Duration(seconds: 6),
      ),
    );
    // Clear immediately after scheduling so a new error from a later action
    // will show a fresh SnackBar.
    widget.appState.clearDataError();
    _showingSnackBar = false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final current = widget.appState.navigationStack.last;
        final hideBar = current is PostWizardScreenRoute ||
            current is ActiveChatScreenRoute;

        return Scaffold(
          bottomNavigationBar: hideBar
              ? null
              : _BottomNavBar(
                  appState: widget.appState,
                  onPostFab: widget.onPostFab,
                ),
          body: SafeArea(
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _AppShell._screenFor(current),
                ),
                if (widget.appState.isLoadingData)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

/// The bottom nav bar.  Receives [appState] directly (passed from
/// _ShellScaffold which already owns a ListenableBuilder) so this widget
/// doesn't need to call KoolanAppStateScope.of(context) — avoiding an
/// additional listener registration that would contribute to the crash.
class _BottomNavBar extends StatelessWidget {
  final KoolanAppState appState;
  final VoidCallback onPostFab;

  const _BottomNavBar({
    required this.appState,
    required this.onPostFab,
  });

  @override
  Widget build(BuildContext context) {
    // appState is already live — _ShellScaffold's ListenableBuilder will
    // rebuild this when navigation / theme change.  No extra subscription needed.
    final current = appState.navigationStack.last;
    final s = appState.s;
    final cs = Theme.of(context).colorScheme;

    final tabs = [
      _Tab(s.navHome, Icons.home_outlined, Icons.home, HomeScreenRoute()),
      _Tab(
        s.navSaved,
        Icons.bookmark_border,
        Icons.bookmark,
        SavedScreenRoute(),
      ),
      _Tab(
        s.navPost,
        Icons.add,
        Icons.add,
        PostWizardScreenRoute(),
        isFab: true,
      ),
      _Tab(
        s.navMessages,
        Icons.chat_bubble_outline,
        Icons.chat_bubble,
        MessagesScreenRoute(),
      ),
      _Tab(
        s.navProfile,
        Icons.person_outline,
        Icons.person,
        ProfileScreenRoute(),
      ),
    ];

    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
              color: cs.outlineVariant.withOpacity(0.4), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(appState.isDarkMode ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((tab) {
          if (tab.isFab) {
            return Expanded(
              child: InkWell(
                onTap: () {
                  // Auth gate: posting a listing requires sign-in.
                  if (!appState.isSignedIn) {
                    showAuthGateSheet(context, reason: AuthGateReason.post);
                    return;
                  }
                  onPostFab();
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Colored rounded-square icon container — stands out
                    // without overflowing, mirrors the size of other tab icons.
                    Container(
                      width: 40,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: cs.onPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final selected = _isSelected(current, tab.route);
          return Expanded(
            child: InkWell(
              onTap: () {
                // Auth gate: Saved, Messages, and Profile require sign-in.
                final needsAuth = tab.route is SavedScreenRoute ||
                    tab.route is MessagesScreenRoute ||
                    tab.route is ProfileScreenRoute;
                if (needsAuth && !appState.isSignedIn) {
                  final reason = tab.route is SavedScreenRoute
                      ? AuthGateReason.save
                      : tab.route is MessagesScreenRoute
                          ? AuthGateReason.messages
                          : AuthGateReason.profile;
                  showAuthGateSheet(context, reason: reason);
                  return;
                }
                appState.switchTab(tab.route);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      selected ? tab.selectedIcon : tab.unselectedIcon,
                      key: ValueKey(selected),
                      color: selected
                          ? cs.primary
                          : cs.onSurfaceVariant.withOpacity(0.55),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.w500,
                      color: selected
                          ? cs.primary
                          : cs.onSurfaceVariant.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static bool _isSelected(KoolanScreen current, KoolanScreen route) {
    if (route is HomeScreenRoute) {
      return current is HomeScreenRoute || current is CategoryListScreenRoute;
    }
    if (route is SavedScreenRoute) return current is SavedScreenRoute;
    if (route is MessagesScreenRoute) {
      return current is MessagesScreenRoute || current is ActiveChatScreenRoute;
    }
    if (route is ProfileScreenRoute) {
      return current is ProfileScreenRoute || current is SettingsScreenRoute;
    }
    return false;
  }
}

class _Tab {
  final String label;
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final KoolanScreen route;
  final bool isFab;

  const _Tab(
    this.label,
    this.unselectedIcon,
    this.selectedIcon,
    this.route, {
    this.isFab = false,
  });
}
