part of '../service_reviews_screen.dart';

// ── Star picker — never icon-only ─────────────────────────────────────────────

class _StarPicker extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;

  const _StarPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              star <= value ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 28,
              semanticLabel: '$star stars',
            ),
          ),
        );
      }),
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ServiceReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;
    final displayName = review.reviewerName ?? s.reviewsFallbackUserName;

    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reviewer row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          cs.primaryContainer.withValues(alpha: 0.4),
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          _ago(review.createdAt, s),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Star display — labelled via semanticLabel on each star
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

  // NOTE: pluralization uses a simple '$n X(s)' pattern which is a known
  // approximation — Amharic and Somali have different plural rules. Tracked
  // as a low-priority UX improvement for a future phase.
  String _ago(DateTime dt, AppStrings s) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 365) {
      return s.reviewsTimeAgoYears(diff.inDays ~/ 365);
    }
    if (diff.inDays >= 30) {
      return s.reviewsTimeAgoMonths(diff.inDays ~/ 30);
    }
    if (diff.inDays >= 1) {
      return s.reviewsTimeAgoDays(diff.inDays);
    }
    if (diff.inHours >= 1) {
      return s.reviewsTimeAgoHours(diff.inHours);
    }
    return s.reviewsTimeAgoJustNow;
  }
}
