import 'package:flutter/material.dart';

import 'core/constants/colors.dart';
import 'core/router/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/cars/presentation/screens/category_list_screen.dart';
import 'features/chat/presentation/screens/active_chat_screen.dart';
import 'features/chat/presentation/screens/messages_screen.dart';
import 'features/favorites/presentation/screens/saved_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/listings/presentation/screens/listing_detail_screen.dart';
import 'features/post/presentation/screens/post_wizard_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/profile/presentation/screens/settings_screen.dart';
import 'shared/services/app_state.dart';

class KoolanApp extends StatelessWidget {
  const KoolanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koolan – Jigjiga Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppRoot(),
    );
  }
}

// ── Root shell ────────────────────────────────────────────────────────────────

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final KoolanAppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = KoolanAppState();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KoolanAppStateScope(
      notifier: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          final current = _appState.navigationStack.last;
          final hideBar = current is PostWizardScreenRoute ||
              current is ActiveChatScreenRoute;

          final shell = Scaffold(
            bottomNavigationBar: hideBar
                ? null
                : _BottomNavBar(
                    current: current,
                    onTabSelect: _appState.switchTab,
                    onPostFab: () =>
                        _appState.pushScreen(PostWizardScreenRoute()),
                  ),
            body: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _screenFor(current),
              ),
            ),
          );

          // On wide screens (desktop / web) centre a phone-sized card.
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 600) return shell;
              return Container(
                color: const Color(0xFFE2E8F0),
                alignment: Alignment.center,
                child: Container(
                  width: 480,
                  height: 850,
                  decoration: BoxDecoration(
                    color: kBackground,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: shell,
                ),
              );
            },
          );
        },
      ),
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
    } else if (screen is SettingsScreenRoute) {
      return const SettingsScreen(key: ValueKey('settings'));
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
    final s = KoolanAppStateScope.of(context).s;

    final tabs = [
      _Tab(s.navHome, Icons.home_outlined, Icons.home, HomeScreenRoute()),
      _Tab(s.navSaved, Icons.bookmark_border, Icons.bookmark, SavedScreenRoute()),
      _Tab(s.navPost, Icons.add, Icons.add, PostWizardScreenRoute(), isFab: true),
      _Tab(s.navMessages, Icons.chat_bubble_outline, Icons.chat_bubble, MessagesScreenRoute()),
      _Tab(s.navProfile, Icons.person_outline, Icons.person, ProfileScreenRoute()),
    ];

    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: kSurfaceContainerLowest,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
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
                decoration: const BoxDecoration(
                  color: kPrimaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
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
                  Icon(
                    selected ? tab.selectedIcon : tab.unselectedIcon,
                    color: selected
                        ? kPrimary
                        : kOnSurfaceVariant.withOpacity(0.6),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.w500,
                      color: selected
                          ? kPrimary
                          : kOnSurfaceVariant.withOpacity(0.6),
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
