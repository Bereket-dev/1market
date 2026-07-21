import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/colors.dart';
import 'core/router/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/cars/presentation/screens/category_list_screen.dart';
import 'features/chat/presentation/screens/active_chat_screen.dart';
import 'features/chat/presentation/screens/messages_screen.dart';
import 'features/favorites/presentation/screens/saved_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/listings/presentation/screens/listing_detail_screen.dart';
import 'features/onboarding/screens/auth_screen.dart';
import 'features/onboarding/screens/goal_selection_screen.dart';
import 'features/onboarding/screens/language_screen.dart';
import 'features/onboarding/screens/location_permission_screen.dart';
import 'features/onboarding/screens/verification_prompt_screen.dart';
import 'features/post/presentation/screens/post_wizard_screen.dart';
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
    // s is not available via KoolanAppStateScope yet during init,
    // so we read it directly from the appState passed through _RootGate.
    final appState = KoolanAppStateScope.of(context);
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
    final appState = KoolanAppStateScope.of(context);
    final isDark = appState.isDarkMode;
    final s = appState.s;

    final current = appState.navigationStack.last;
    final hideBar =
        current is PostWizardScreenRoute || current is ActiveChatScreenRoute;

    final shell = Scaffold(
      bottomNavigationBar: hideBar
          ? null
          : _BottomNavBar(
              current: current,
              onTabSelect: appState.switchTab,
              onPostFab: () => appState.pushScreen(PostWizardScreenRoute()),
            ),
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _screenFor(current),
            ),
            if (appState.isLoadingData)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
            if (appState.dataError != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: hideBar ? 16 : 96,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            appState.dataError!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            appState.clearDataError();
                            appState.loadAllData();
                          },
                          child: Text(s.commonRetry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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

  Widget _screenFor(KoolanScreen screen) {
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
    } else if (screen is MyListingsScreenRoute) {
      return const MyListingsScreen(key: ValueKey('my_listings'));
    }
    return const SizedBox.shrink();
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final KoolanScreen current;
  final void Function(KoolanScreen) onTabSelect;
  final VoidCallback onPostFab;

  const _BottomNavBar({
    required this.current,
    required this.onTabSelect,
    required this.onPostFab,
  });

  @override
  Widget build(BuildContext context) {
    final appState = KoolanAppStateScope.of(context);
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
      height: 80,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withOpacity(0.4), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(appState.isDarkMode ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((tab) {
          if (tab.isFab) {
            return InkWell(
              onTap: onPostFab,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: cs.onPrimaryContainer, size: 28),
              ),
            );
          }

          final selected = _isSelected(tab.route);
          return Expanded(
            child: InkWell(
              onTap: () => onTabSelect(tab.route),
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
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
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

  bool _isSelected(KoolanScreen route) {
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
