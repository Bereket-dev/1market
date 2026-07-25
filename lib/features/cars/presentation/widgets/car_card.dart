import 'package:flutter/material.dart';
import '../../../../core/utils/icon_for_spec.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
part 'widgets/car_card_shared.dart';
part 'widgets/car_card_compact.dart';

// ── Full card (original) ──────────────────────────────────────────────────────

/// Full-size vertical listing card. Used in grid-off (single-column) mode.
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
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ─────────────────────────────────────────────────────
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImageWidget(
                    imageUrl: listing.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 120,
                    errorWidget:
                        Container(color: cs.surfaceContainerHighest),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ConditionPill(
                            status: listing.conditionOrStatus, cs: cs),
                        _SaveButton(
                            isSaved: listing.isSaved,
                            onTap: onSaveToggle,
                            cs: cs),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        listing.price,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                      if (listing.isOwnedByCurrentUser)
                        _MyAdBadge(cs: cs),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    listing.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Specs row
                  _SpecsRow(listing: listing),
                  const SizedBox(height: 8),
                  Divider(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                      height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: cs.outline, size: 14),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          listing.location.split(',')[0],
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

// ── Compact card (grid / 2-column mode) ──────────────────────────────────────

/// Compact listing card designed for 2-column grid layouts.
/// Shows the essential info without a large hero image.

/// A small tappable chip used in browse/filter strips.
class BrowseFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const BrowseFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}
