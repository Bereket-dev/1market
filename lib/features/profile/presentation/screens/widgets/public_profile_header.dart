part of '../public_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sliver header: banner, avatar, name, bio, stats
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSliverHeader extends StatelessWidget {
  final KoolanAppState state;
  final UserProfile? profile;
  final List<ServiceReview> reviews;
  final VoidCallback onBack;

  const _ProfileSliverHeader({
    required this.state,
    required this.profile,
    required this.reviews,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;
    final displayName = profile?.displayName ?? '—';
    final bio = profile?.bio ?? '';
    final rating = profile?.rating ?? 0.0;
    final reviewsCount = profile?.reviewsCount ?? reviews.length;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner + back button ─────────────────────────────────────────
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Banner
                if (profile?.bannerUrl != null &&
                    profile!.bannerUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: profile!.bannerUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: cs.primaryContainer.withValues(alpha: 0.25)),
                    errorWidget: (_, _, _) =>
                        Container(color: cs.primaryContainer.withValues(alpha: 0.25)),
                  )
                else
                  Container(color: cs.primaryContainer.withValues(alpha: 0.25)),

                // Gradient scrim
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onBack,
                      child: const Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(Icons.arrow_back,
                            size: 22, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Avatar row ───────────────────────────────────────────────────
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: cs.primaryContainer,
                      child: profile?.avatarUrl != null &&
                              profile!.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: profile!.avatarUrl!,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) =>
                                    _InitialsFallback(name: displayName, cs: cs),
                              ),
                            )
                          : _InitialsFallback(name: displayName, cs: cs),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),

          // ── Name + bio + rating ──────────────────────────────────────────
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Rating row
                  Row(
                    children: [
                      RatingStars(
                        rating: rating,
                        reviewCount: reviewsCount > 0 ? reviewsCount : null,
                      ),
                    ],
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      bio,
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(
                      s.publicProfileNoBio,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Services tab
// ─────────────────────────────────────────────────────────────────────────────

