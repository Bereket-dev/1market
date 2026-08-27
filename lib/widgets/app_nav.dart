part of '../app.dart';

// ── Animated loading bar ──────────────────────────────────────────────────────
// A shimmer-style indeterminate bar — more modern than a plain LinearProgressIndicator.

class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return SizedBox(
          height: 3,
          child: LinearProgressIndicator(
            backgroundColor: cs.primary.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            // null → indeterminate animated sweep
            value: null,
            borderRadius: BorderRadius.zero,
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
                  HapticFeedback.lightImpact();
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
          final isMessages = tab.route is MessagesScreenRoute;
          final unreadChats =
              isMessages ? appState.totalUnreadChatCount : 0;
          return Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
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
                    child: Badge(
                      key: ValueKey('$selected-$unreadChats'),
                      isLabelVisible: unreadChats > 0,
                      backgroundColor: cs.error,
                      textColor: cs.onError,
                      label: Text(
                        unreadChats > 99 ? '99+' : '$unreadChats',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Icon(
                        selected ? tab.selectedIcon : tab.unselectedIcon,
                        color: selected
                            ? cs.primary
                            : cs.onSurfaceVariant.withOpacity(0.55),
                        size: 24,
                      ),
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
