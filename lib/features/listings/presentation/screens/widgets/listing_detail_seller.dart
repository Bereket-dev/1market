part of '../listing_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Seller card
// ─────────────────────────────────────────────────────────────────────────────

class _SellerCard extends StatelessWidget {
  final Listing listing;
  final KoolanAppState state;
  const _SellerCard({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s  = state.s;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.detailSeller.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.primaryContainer,
                  child: listing.sellerImage.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: listing.sellerImage,
                            cacheManager: KoolanImageCacheManager.instance,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _SellerInitials(
                              name: listing.sellerName,
                              cs: cs,
                            ),
                          ),
                        )
                      : _SellerInitials(name: listing.sellerName, cs: cs),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.sellerName,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              color: Colors.amber, size: 15),
                          const SizedBox(width: 3),
                          Text(
                            listing.sellerRating.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${listing.sellerReviewsCount} ${s.detailReviews})',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    if (!state.isSignedIn) {
                      showAuthGateSheet(context,
                          reason: AuthGateReason.profile);
                      return;
                    }
                    final sellerId = listing.sellerId;
                    if (sellerId != null && sellerId.isNotEmpty) {
                      state.pushScreen(PublicProfileScreenRoute(sellerId));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.detailProfileVerified)),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  child: Text(s.detailViewProfile,
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurface)),
                ),
              ],
            ),

            // ── Report link — non-owner only ──────────────────────────
            if (!listing.isOwnedByCurrentUser) ...[
              const Divider(height: 24),
              GestureDetector(
                onTap: () => showReportBottomSheet(
                  context,
                  targetType: 'listing',
                  listingId: listing.id,
                  reportedUserId: listing.sellerId,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 15, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      s.reportMenuLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Initials fallback ─────────────────────────────────────────────────────────

class _SellerInitials extends StatelessWidget {
  final String name;
  final ColorScheme cs;
  const _SellerInitials({required this.name, required this.cs});

  @override
  Widget build(BuildContext context) => Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onPrimaryContainer),
      );
}
