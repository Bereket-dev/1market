part of '../car_card.dart';

// ── Compact card (grid / 2-column mode) ──────────────────────────────────────

/// Compact listing card designed for 2-column grid layouts.
/// Shows the essential info without a large hero image.
class ListingCompactCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const ListingCompactCard({
    super.key,
    required this.listing,
    required this.onSaveToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ───────────────────────────────────────────────
            Stack(
              children: [
                CachedImageWidget(
                  imageUrl: listing.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 110,
                  errorWidget: ListingPlaceholder(
                    category: listing.category,
                    width: double.infinity,
                    height: 110,
                  ),
                ),
                // Save overlay
                Positioned(
                  top: 6,
                  right: 6,
                  child: _SaveButton(
                      isSaved: listing.isSaved, onTap: onSaveToggle, cs: cs),
                ),
              ],
            ),

            // ── Info ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.price,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Condition pill + location on same row to save vertical space
                  Row(
                    children: [
                      _ConditionPill(status: listing.conditionOrStatus, cs: cs),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on,
                                color: cs.outline, size: 11),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                listing.location.split(',')[0],
                                style: TextStyle(
                                    fontSize: 10, color: cs.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }
}

