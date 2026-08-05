part of '../home_screen.dart';

class _RecommendedSection extends StatefulWidget {
  const _RecommendedSection();

  @override
  State<_RecommendedSection> createState() => _RecommendedSectionState();
}

class _RecommendedSectionState extends State<_RecommendedSection> {
  static const _engine = RecommendationEngine();

  // Cached output — list of (id, type) records so we can tap back to the
  // correct detail screen. We store them as a sealed record-like class.
  List<_RecItem> _recommendations = [];
  // Data version stamp: length of listings + services + hiringPosts at last compute.
  int _lastDataVersion = -1;

  /// Returns the current data version from [state] (sum of list lengths).
  static int _dataVersion(KoolanAppState state) =>
      state.allListings.length +
      state.allServices.length +
      state.allHiringPosts.length;

  void _computeIfStale(KoolanAppState state) {
    final version = _dataVersion(state);
    if (version == _lastDataVersion) return;
    _lastDataVersion = version;

    final user = state.buildUserContext();
    final currentUserId = state.currentUser?.id;

    // Build scored listings.
    final excludeOwned = currentUserId == null
        ? <String>{}
        : state.allListings
            .where((l) => l.isOwnedByCurrentUser)
            .map((l) => l.id)
            .toSet();

    final scoredListings = _engine.rankForUser<ScorableListing>(
      candidates:
          state.allListings.map((l) => ScorableListing(l)).toList(),
      user: user,
      excludeIds: excludeOwned,
    );

    // Build scored services.
    final excludeOwnedServices = currentUserId == null
        ? <String>{}
        : state.allServices
            .where((s) => s.ownerId == currentUserId)
            .map((s) => s.id)
            .toSet();

    final scoredServices = _engine.rankForUser<ScorableService>(
      candidates: state.allServices.map((s) {
        final reviews = state.getReviewsForService(s.id);
        final avg = reviews.isEmpty
            ? 0.0
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                reviews.length;
        return ScorableService(s, reviewRating: avg);
      }).toList(),
      user: user,
      excludeIds: excludeOwnedServices,
    );

    // Build scored hiring posts — only open posts.
    final excludeOwnedPosts = currentUserId == null
        ? <String>{}
        : state.allHiringPosts
            .where((p) => p.posterId == currentUserId)
            .map((p) => p.id)
            .toSet();

    final scoredPosts = _engine.rankForUser<ScorableHiringPost>(
      candidates: state.allHiringPosts
          .where((p) => p.isOpen)
          .map((p) => ScorableHiringPost(p))
          .toList(),
      user: user,
      excludeIds: excludeOwnedPosts,
    );

    // Interleave top results: take up to 4 listings, 3 services, 3 posts
    // then trim to kMaxRecommendations total.
    final merged = <_RecItem>[
      ...scoredListings.take(4).map((s) => _RecItem.listing(s.listing)),
      ...scoredServices.take(3).map((s) => _RecItem.service(s.service)),
      ...scoredPosts.take(3).map((s) => _RecItem.hiring(s.post)),
    ];

    _recommendations = merged.take(kMaxRecommendations).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    _computeIfStale(state);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.homeRecommendedTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (_recommendations.isEmpty && state.isLoadingData)
            // Skeleton shimmer while data is loading.
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, i) => const SizedBox(width: 12),
                itemBuilder: (_, i) => const _SkeletonCard(
                  width: 160,
                  height: 180,
                ),
              ),
            )
          else if (_recommendations.isEmpty)
            // Empty state — graceful, not broken.
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                s.homeRecommendedEmpty,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            )
          else
            // Horizontal scroll of recommendation cards.
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _recommendations.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = _recommendations[index];
                  return _RecommendationCard(
                    item: item,
                    onTap: () {
                      state.recordItemViewed(item.id);
                      switch (item.type) {
                        case _RecType.listing:
                          state.pushScreen(
                              ListingDetailScreenRoute(item.id));
                        case _RecType.service:
                          state.pushScreen(
                              ServiceDetailScreenRoute(item.id));
                        case _RecType.hiring:
                          state.pushScreen(
                              HiringDetailScreenRoute(item.id));
                      }
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Recommendation card ───────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final _RecItem item;
  final VoidCallback onTap;

  const _RecommendationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = KoolanAppStateScope.of(context).s;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / icon area
            SizedBox(
              height: 96,
              width: double.infinity,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? CachedImageWidget(
                      imageUrl: item.imageUrl!,
                      width: 160,
                      height: 96,
                      fit: BoxFit.cover,
                      errorWidget: ListingPlaceholder(
                          category: item.category,
                          width: 160,
                          height: 96),
                    )
                  : ListingPlaceholder(
                      category: item.category,
                      width: 160,
                      height: 96),
            ),
            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        // Type badge (accessible — text label, not icon only)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _typeLabel(item.type, s),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (item.price != null)
                          Flexible(
                            child: Text(
                              item.price!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: cs.primary,
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
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(_RecType type, AppStrings s) {
    return switch (type) {
      _RecType.listing => s.catAll, // "All" / generic listing label
      _RecType.service => s.servicesTitle,
      _RecType.hiring => s.hiringBrowseTitle,
    };
  }
}


// (Category icon placeholder is now handled by ListingPlaceholder in cached_image_widget.dart)


