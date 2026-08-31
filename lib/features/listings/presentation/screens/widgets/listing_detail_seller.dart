part of '../listing_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Seller card
// ─────────────────────────────────────────────────────────────────────────────

class _SellerCard extends StatelessWidget {
  final Listing listing;
  final OnemarketAppState state;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.primaryContainer,
                  child: listing.sellerImage.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: listing.sellerImage,
                            cacheManager: OnemarketImageCacheManager.instance,
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
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: kBrandGold, size: 15),
                          Text(
                            listing.sellerRating.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface),
                          ),
                          Text(
                            '(${listing.sellerReviewsCount} ${s.detailReviews})',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant),
                          ),
                          if (listing.verified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: kVerifiedBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded,
                                      size: 12, color: kVerifiedColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    s.detailVerified,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: kVerifiedColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: OutlinedButton(
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
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Text(
                      s.detailViewProfile,
                      style: TextStyle(fontSize: 12, color: cs.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
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
