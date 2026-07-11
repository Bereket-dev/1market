import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
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
    return Card(
      elevation: 0,
      color: kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: kOutlineVariant.withOpacity(0.2)),
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
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[300]),
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
                                color: kPrimaryContainer.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                listing.conditionOrStatus,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Bookmark
                        InkWell(
                          onTap: onSaveToggle,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: Icon(
                              listing.isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: listing.isSaved
                                  ? Colors.red
                                  : kOnSurfaceVariant,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: kPrimary,
                        ),
                      ),
                      if (listing.isCustom)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'My Ad',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kOnSurface,
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
                  const Divider(color: Color(0xFFF1F3F9)),
                  const SizedBox(height: 12),

                  // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: kOutline, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            listing.location.split(',')[0],
                            style: const TextStyle(
                                fontSize: 13, color: kOnSurfaceVariant),
                          ),
                        ],
                      ),
                      const Text(
                        '2.4 km away',
                        style: TextStyle(
                          fontSize: 11,
                          color: kSecondary,
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

class _SpecIconLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SpecIconLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: kOnSurfaceVariant.withOpacity(0.5), size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: kOnSurfaceVariant),
        ),
      ],
    );
  }
}
