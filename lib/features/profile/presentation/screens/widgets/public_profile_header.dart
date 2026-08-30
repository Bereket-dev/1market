part of '../public_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sliver header: avatar, name, bio, stats
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSliverHeader extends StatelessWidget {
  final OnemarketAppState state;
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
          // ── Back button ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            ),
          ),

          // ── Avatar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
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
          ),

          // ── Name + bio + rating ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Services tab
// ─────────────────────────────────────────────────────────────────────────────

