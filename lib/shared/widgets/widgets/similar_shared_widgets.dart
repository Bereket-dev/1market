part of '../similar_section.dart';

// ── Shared layout ─────────────────────────────────────────────────────────────

/// Header + horizontal card list shell, shared by all three similar sections.
class _SimilarShell extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const _SimilarShell({required this.itemCount, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    final s = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 12),
        Text(
          s.detailSimilarTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: itemBuilder,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Empty state — shown gracefully when no similar items exist yet.
class _SimilarEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            s.detailSimilarTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.detailSimilarEmpty,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Card variants ─────────────────────────────────────────────────────────────

class _SimilarListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  const _SimilarListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        height: 156,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            SizedBox(
              height: 82,
              width: double.infinity,
              child: listing.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: listing.imageUrl,
                      cacheManager: OnemarketImageCacheManager.instance,
                      width: double.infinity,
                      height: 82,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => ListingPlaceholder(
                        category: listing.category,
                        width: double.infinity,
                        height: 82,
                      ),
                    )
                  : ListingPlaceholder(
                      category: listing.category,
                      width: double.infinity,
                      height: 82,
                    ),
            ),
            // Label
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      listing.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      listing.price,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimilarServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;
  const _SimilarServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = OnemarketAppStateScope.of(context).s;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        height: 156,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon area
            Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.construction_rounded,
                color: cs.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              service.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Availability chip — text label, not icon only (acc. criterion 6)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: service.availability
                    ? cs.primaryContainer.withValues(alpha: 0.3)
                    : cs.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                service.availability
                    ? s.servicesAvailable
                    : s.servicesUnavailable,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: service.availability ? cs.primary : cs.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimilarHiringCard extends StatelessWidget {
  final HiringPost post;
  final VoidCallback onTap;
  const _SimilarHiringCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = OnemarketAppStateScope.of(context).s;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        height: 156,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon area
            Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.work_outline, color: cs.primary, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              post.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Status chip — text label (acc. criterion 6)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: post.isOpen
                    ? cs.primaryContainer.withValues(alpha: 0.3)
                    : cs.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                post.isOpen ? s.hiringStatusOpen : s.hiringStatusClosed,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: post.isOpen ? cs.primary : cs.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// (Category icon placeholder is now handled by ListingPlaceholder in cached_image_widget.dart)
