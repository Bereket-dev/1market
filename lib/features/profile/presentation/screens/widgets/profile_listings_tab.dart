part of '../profile_screen.dart';

// ── Listings tab ──────────────────────────────────────────────────────────────

class _ListingsTab extends StatelessWidget {
  final List<Listing> listings;
  final VoidCallback onManageTap;
  final VoidCallback onPostTap;

  const _ListingsTab({
    required this.listings,
    required this.onManageTap,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final state = OnemarketAppStateScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Action buttons ────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onManageTap,
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: Text(state.s.profileManageAll),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onPostTap,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(state.s.profileNewPost),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Listing cards ─────────────────────────────────────────────────
        if (listings.isEmpty) ...[
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 38,
            backgroundColor: cs.surfaceContainerHighest,
            child: Icon(Icons.storefront_outlined,
                size: 36, color: cs.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 14),
          Text(
            'No listings yet',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Post a car, house, or land to start selling or renting.',
            style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: listings.length > 3 ? 3 : listings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final l = listings[i];
              return _ProfileListingCard(
                listing: l,
                onTap: () => state.pushScreen(ListingDetailScreenRoute(l.id)),
              );
            },
          ),
          if (listings.length > 3) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onManageTap,
              child: Text(
                '+ ${listings.length - 3} more listings',
                style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Rich listing preview card used in the profile Listings tab.
/// Taps into ListingDetailScreen.
class _ProfileListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  const _ProfileListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // First non-empty image from imageUrls or fallback imageUrl
    final thumb = listing.imageUrls.isNotEmpty
        ? listing.imageUrls.first
        : listing.imageUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedImageWidget(
                imageUrl: thumb,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorWidget: ListingPlaceholder(
                  category: listing.category,
                  width: 72,
                  height: 72,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + condition chips
                  Row(
                    children: [
                      _MiniChip(
                          label: listing.category, cs: cs, primary: true),
                      const SizedBox(width: 6),
                      _MiniChip(
                          label: listing.conditionOrStatus,
                          cs: cs,
                          primary: false),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Title
                  Text(
                    listing.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Price
                  Text(
                    listing.price,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: cs.primary),
                  ),
                  const SizedBox(height: 3),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 11, color: cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          listing.location.split(',').first,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Arrow ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  final bool primary;
  const _MiniChip(
      {required this.label, required this.cs, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: primary
            ? cs.primaryContainer.withValues(alpha: 0.45)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: primary
            ? null
            : Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: primary ? cs.primary : cs.onSurfaceVariant),
      ),
    );
  }
}
