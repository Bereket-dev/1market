import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';

/// Compact horizontal card shown in the "Recently Added" feed on the home screen.
class RecentListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const RecentListingCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = OnemarketAppStateScope.of(context).s;

    return Card(
      elevation: 0,
      color: kSurfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedImageWidget(
                      imageUrl: listing.imageUrl,
                      delivery: CachedImageDelivery.compact,
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
                  if (listing.verified)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: kVerifiedColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded,
                            size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          listing.price,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: cs.outline, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listing.location,
                            style: TextStyle(
                                fontSize: 12, color: cs.outline),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              listing.category == 'SKILLS'
                                  ? s.cardTalkToSeller
                                  : s.cardCallOwner,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              listing.category == 'SKILLS'
                                  ? Icons.chat_bubble
                                  : Icons.call,
                              color: cs.onPrimary,
                              size: 11,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
