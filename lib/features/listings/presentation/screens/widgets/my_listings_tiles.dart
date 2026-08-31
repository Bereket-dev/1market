part of '../my_listings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Individual listing tile
// ─────────────────────────────────────────────────────────────────────────────

class _MyListingTile extends StatelessWidget {
  final Listing listing;
  final OnemarketAppState state;
  const _MyListingTile({required this.listing, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => state.pushScreen(ListingDetailScreenRoute(listing.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedImageWidget(
                  imageUrl: listing.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: ListingPlaceholder(
                    category: listing.category,
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip + condition
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _SmallChip(
                          label: listing.category,
                          color: cs.primaryContainer.withValues(alpha: 0.5),
                          textColor: cs.primary,
                        ),
                        const SizedBox(width: 6),
                        _SmallChip(
                          label: listing.conditionOrStatus,
                          color: cs.surfaceContainerHighest,
                          textColor: cs.onSurfaceVariant,
                          border: cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        _SmallChip(
                          label: listing.isHidden
                              ? state.s.listingUnlisted
                              : state.s.listingListed,
                          color: listing.isHidden
                              ? cs.errorContainer.withValues(alpha: 0.35)
                              : cs.primaryContainer.withValues(alpha: 0.35),
                          textColor: listing.isHidden ? cs.error : cs.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Title
                    Text(
                      listing.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Price
                    Text(
                      listing.price,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.location.split(',')[0],
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions column
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit listing
                  _ActionButton(
                    icon: Icons.edit_rounded,
                    label: state.s.commonEdit,
                    color: cs.secondaryContainer.withValues(alpha: 0.5),
                    iconColor: cs.secondary,
                    onTap: () =>
                        state.pushScreen(EditListingScreenRoute(listing.id)),
                  ),
                  const SizedBox(height: 6),
                  // View detail
                  _ActionButton(
                    icon: Icons.open_in_new_rounded,
                    label: state.s.commonView,
                    color: cs.primary.withValues(alpha: 0.12),
                    iconColor: cs.primary,
                    onTap: () =>
                        state.pushScreen(ListingDetailScreenRoute(listing.id)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Color? border;
  const _SmallChip({
    required this.label,
    required this.color,
    required this.textColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
