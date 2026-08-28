part of '../public_profile_screen.dart';

class _ServicesTab extends StatelessWidget {
  final List<Service> services;
  final OnemarketAppState state;

  const _ServicesTab({required this.services, required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    if (services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.work_off_outlined,
                  size: 56, color: cs.outline.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                s.publicProfileNoServices,
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: services.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          _ServiceListTile(service: services[i], state: state),
    );
  }
}

class _ServiceListTile extends StatelessWidget {
  final Service service;
  final OnemarketAppState state;
  const _ServiceListTile({required this.service, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => state.pushScreen(ServiceDetailScreenRoute(service.id)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: service.imageUrl.isNotEmpty
                  ? CachedImageWidget(
                      imageUrl: service.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: cs.primaryContainer.withValues(alpha: 0.25),
                      child: Icon(Icons.work_outline_rounded,
                          size: 32,
                          color: cs.primary.withValues(alpha: 0.4)),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.category,
                    style: TextStyle(fontSize: 12, color: cs.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.coverDescription,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reviews tab
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  final List<ServiceReview> reviews;
  final OnemarketAppState state;

  const _ReviewsTab({required this.reviews, required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    if (reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rate_review_outlined,
                  size: 56, color: cs.outline.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                s.reviewsEmpty,
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: reviews.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _ReviewCard(review: reviews[i], s: s),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ServiceReview review;
  final dynamic s; // AppStrings

  const _ReviewCard({required this.review, required this.s});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = review.reviewerName ?? s.reviewsFallbackUserName as String;

    return Card(
      color: cs.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          cs.primaryContainer.withValues(alpha: 0.4),
                      backgroundImage: review.reviewerAvatarUrl != null
                          ? NetworkImage(review.reviewerAvatarUrl!)
                          : null,
                      child: review.reviewerAvatarUrl == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: cs.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          _ago(review.createdAt, s),
                          style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                RatingStars(
                  rating: review.rating.toDouble(),
                  reviewCount: null,
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.comment,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _ago(DateTime dt, s) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) return s.reviewsTimeAgoYears(diff.inDays ~/ 365) as String;
    if (diff.inDays >= 30) return s.reviewsTimeAgoMonths(diff.inDays ~/ 30) as String;
    if (diff.inDays >= 1) return s.reviewsTimeAgoDays(diff.inDays) as String;
    if (diff.inHours >= 1) return s.reviewsTimeAgoHours(diff.inHours) as String;
    return s.reviewsTimeAgoJustNow as String;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Initials fallback avatar
// ─────────────────────────────────────────────────────────────────────────────

class _InitialsFallback extends StatelessWidget {
  final String name;
  final ColorScheme cs;
  const _InitialsFallback({required this.name, required this.cs});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}
