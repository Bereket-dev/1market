import 'package:flutter/material.dart';
import '../../../../core/utils/icon_for_spec.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../shared/models/listing.dart';

/// Full-size vertical listing card. Used across all category browse screens.
class PremiumClassifiedCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const PremiumClassifiedCard({
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
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ───────────────────────────────────────────────────────
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    listing.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (listing.verified) ...[
                              const VerifiedBadge(),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer
                                    .withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                listing.conditionOrStatus,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Bookmark button
                        InkWell(
                          onTap: onSaveToggle,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                cs.surface.withValues(alpha: 0.88),
                            child: Icon(
                              listing.isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: listing.isSaved
                                  ? Colors.redAccent
                                  : cs.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        listing.price,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                      if (listing.isCustom)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer
                                .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'My Ad',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Specs row
                  Row(
                    children: [
                      if (listing.spec1Label != null &&
                          listing.spec1Value != null) ...[
                        _SpecIconLabel(
                          label: listing.spec1Value!,
                          icon: iconForSpec(listing.spec1Label!),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (listing.spec2Label != null &&
                          listing.spec2Value != null) ...[
                        _SpecIconLabel(
                          label: listing.spec2Value!,
                          icon: iconForSpec(listing.spec2Label!),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (listing.spec3Label != null &&
                          listing.spec3Value != null)
                        _SpecIconLabel(
                          label: listing.spec3Value!,
                          icon: iconForSpec(listing.spec3Label!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),

                  // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: cs.outline, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            listing.location.split(',')[0],
                            style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                      Text(
                        '2.4 km away',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.secondary,
                          fontWeight: FontWeight.bold,
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

// ── Filter chip ───────────────────────────────────────────────────────────────

class BrowseFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const BrowseFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 16,
              color:
                  selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecIconLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SpecIconLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color: cs.onSurfaceVariant.withValues(alpha: 0.5), size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style:
              TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
