part of '../app.dart';

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

/// Owns the Scaffold, bottom nav bar, screen switcher, loading bar, and the
/// floating error toast overlay.
///
/// Error toasts replace the old SnackBar approach: they auto-dismiss after 5 s,
/// drain a progress bar, and have an X button for immediate removal.
///
/// Pull-to-refresh is wired at this level so every top-level screen benefits
/// from it — the user can drag down anywhere to trigger [loadAllData].
class _ShellScaffold extends StatefulWidget {
  final KoolanAppState appState;
  final VoidCallback onPostFab;

  const _ShellScaffold({required this.appState, required this.onPostFab});

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold> {
  // Tracks the currently visible toast key so we never stack duplicates.
  String? _activeToastMessage;

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

  void _onAppStateChanged() {
    final error = widget.appState.dataError;
    if (!mounted || error == null) return;
    // Don't re-show the exact same message that's already visible.
    if (_activeToastMessage == error) return;
    setState(() => _activeToastMessage = error);
    widget.appState.clearDataError();
  }

  void _dismissToast() {
    if (mounted) setState(() => _activeToastMessage = null);
  }

  Future<void> _onRefresh() => widget.appState.loadAllData(forceRefresh: true);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
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
                // ── Screen content + pull-to-refresh ──────────────────
                RefreshIndicator(
                  onRefresh: _onRefresh,
                  displacement: 60,
                  strokeWidth: 2.5,
                  color: cs.primary,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0.03, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offset,
                          child: child,
                        ),
                      );
                    },
                    child: _AppShell._screenFor(current),
                  ),
                ),

                // ── Global loading bar (top of screen) ────────────────
                if (widget.appState.isLoadingData)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _LoadingBar(),
                  ),

                // ── Floating error toast ───────────────────────────────
                if (_activeToastMessage != null)
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: ToastBanner(
                      key: ValueKey(_activeToastMessage),
                      message: _activeToastMessage!,
                      type: ToastType.error,
                      actionLabel: widget.appState.s.commonRetry,
                      onAction: () => widget.appState.loadAllData(),
                      onDismiss: _dismissToast,
                    ),
                  ),

                // ── Debug sync overlay (bottom-left, debug builds only) ───
                if (kDebugMode)
                  Positioned(
                    left: 8,
                    bottom: hideBar ? 12 : 96,
                    child: SyncDebugOverlay(appState: widget.appState),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

