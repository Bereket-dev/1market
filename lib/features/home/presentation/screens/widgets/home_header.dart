part of '../home_screen.dart';

// ── Home header ───────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final profile = state.profile;
    final avatarUrl = profile?.avatarUrl;
    final displayName = profile?.displayName;
    final initials = displayName != null && displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '1';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Brand mark ─────────────────────────────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              color: BrandLogo.iconBackgroundForBrightness(
                Theme.of(context).brightness,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: BrandLogo(iconOnly: true, width: 34, height: 34),
            ),
          ),
          const SizedBox(width: 10),
          // ── App name ───────────────────────────────────────────────────────
          Expanded(
            child: Text(
              state.s.appName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cs.primary,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // ── Notification bell ──────────────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    // Auth gate: notifications require sign-in.
                    if (!state.isSignedIn) {
                      showAuthGateSheet(
                        context,
                        reason: AuthGateReason.notifications,
                      );
                      return;
                    }
                    state.pushScreen(NotificationsScreenRoute());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      state.unreadNotificationCount > 0
                          ? Icons.notifications
                          : Icons.notifications_none_outlined,
                      color: state.unreadNotificationCount > 0
                          ? cs.primary
                          : cs.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ),
              ),
              if (state.unreadNotificationCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IgnorePointer(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: cs.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.surface,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        state.unreadNotificationCount > 9
                            ? '9+'
                            : '${state.unreadNotificationCount}',
                        style: TextStyle(
                          color: cs.onError,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),

          // ── Profile avatar ─────────────────────────────────────────────────
          GestureDetector(
            onTap: () {
              // Auth gate: own profile requires sign-in.
              if (!state.isSignedIn) {
                showAuthGateSheet(context, reason: AuthGateReason.profile);
                return;
              }
              state.pushScreen(ProfileScreenRoute());
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        cacheManager: KoolanImageCacheManager.instance,
                        imageBuilder: (ctx, provider) => Image(
                          image: provider,
                          fit: BoxFit.cover,
                          width: 38,
                          height: 38,
                        ),
                        placeholder: (ctx, url) => _AvatarPlaceholder(
                          initials: initials,
                          cs: cs,
                        ),
                        errorWidget: (ctx, url, err) => _AvatarPlaceholder(
                          initials: initials,
                          cs: cs,
                        ),
                      )
                    : _AvatarPlaceholder(initials: initials, cs: cs),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final String initials;
  final ColorScheme cs;
  const _AvatarPlaceholder({required this.initials, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      color: cs.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

