import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/hiring_post.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/services/recommendation_engine.dart';
import '../../../../shared/services/scorable_adapters.dart';
import '../../../../shared/widgets/auth_gate_sheet.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../widgets/category_card.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/recent_listing_card.dart';
import '../../data/category_picker_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          _HomeHeader(),

          // ── Scrollable body ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting + 2×2 category grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.s.homeGreeting,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: CompactCategoryCard(
                              title: state.s.homeCategoryCars,
                              subtitle: state.s.homeCategoryCars,
                              icon: Icons.directions_car_filled,
                              color: const Color(0xFF1E40AF),
                              onTap: () => state.pushScreen(
                                  CategoryListScreenRoute('CARS')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CompactCategoryCard(
                              title: state.s.homeCategoryHouses,
                              subtitle: state.s.homeCategoryHouses,
                              icon: Icons.home_rounded,
                              color: const Color(0xFF0F766E),
                              onTap: () => state.pushScreen(
                                  CategoryListScreenRoute('HOUSES')),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: CompactCategoryCard(
                              title: state.s.homeCategoryLand,
                              subtitle: state.s.homeCategoryLand,
                              icon: Icons.landscape_rounded,
                              color: const Color(0xFF92400E),
                              onTap: () => state.pushScreen(
                                  CategoryListScreenRoute('LAND')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CompactCategoryCard(
                              title: state.s.homeCategorySkills,
                              subtitle: state.s.homeCategorySkills,
                              icon: Icons.construction_rounded,
                              color: const Color(0xFF6D28D9),
                              onTap: () => state.pushScreen(
                                  CategoryListScreenRoute('SKILLS')),
                            ),
                          ),
                        ]),
                        // Others — full-width tile (5th category, layout 2+2+1)
                        const SizedBox(height: 12),
                        CompactCategoryCard(
                          title: state.s.homeCategoryOthers,
                          subtitle: state.s.homeCategoryOthers,
                          icon: Icons.category_outlined,
                          color: const Color(0xFF475569),
                          onTap: () => state.pushScreen(
                              CategoryListScreenRoute('OTHERS')),
                        ),
                      ],
                    ),
                  ),

                  // Promo carousel
                  const SizedBox(height: 20),
                  const PromoCarousel(),

                  // Search simulator
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: InkWell(
                      onTap: () => state
                          .pushScreen(CategoryListScreenRoute('ALL')),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: cs.outlineVariant
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Row(children: [
                          Icon(Icons.search, color: cs.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Text(
                            state.s.homeSearchHint,
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),

                  // ── Find Jobs banner ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                    child: InkWell(
                      onTap: () =>
                          state.pushScreen(HiringBrowseScreenRoute()),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              cs.primary,
                              cs.primary.withValues(alpha: 0.75),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.work_outline,
                              color: cs.onPrimary,
                              size: 28,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.s.hiringBrowseTitle,
                                    style: TextStyle(
                                      color: cs.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    state.s.hiringBrowseSearchHint,
                                    style: TextStyle(
                                      color: cs.onPrimary
                                          .withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: cs.onPrimary.withValues(alpha: 0.8),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Recommended for you ──────────────────────────────────
                  const _RecommendedSection(),

                  // Recently Added
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.s.homeRecentlyAdded,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (state.isLoadingData && state.allListings.isEmpty)
                          // Skeleton shimmer while listings are loading.
                          Column(
                            children: List.generate(
                              3,
                              (i) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: i < 2 ? 12 : 0),
                                child: const _SkeletonCard(
                                  width: double.infinity,
                                  height: 80,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                math.min(state.allListings.length, 3),
                            separatorBuilder: (context2, idx) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final listing = state.allListings[index];
                              return RecentListingCard(
                                listing: listing,
                                onTap: () => state.pushScreen(
                                    ListingDetailScreenRoute(listing.id)),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => state.pushScreen(
                              CategoryListScreenRoute('ALL')),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                            side: BorderSide(color: cs.outlineVariant),
                          ),
                          child: Text(
                            state.s.homeViewAll,
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Auth gate: posting a listing requires sign-in.
          if (!state.isSignedIn) {
            showAuthGateSheet(context, reason: AuthGateReason.post);
            return;
          }
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => CategoryPickerSheet(
              onSelect: (cat) {
                Navigator.pop(context);
                state.postCategory = cat;
                state.pushScreen(PostWizardScreenRoute());
              },
            ),
          );
        },
        backgroundColor: cs.primaryContainer,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: cs.onPrimaryContainer, size: 28),
      ),
    );
  }
}

// ── Home header ───────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final profile = state.profile;
    final avatarUrl = profile?.avatarUrl;
    final displayName = profile?.displayName;
    final initials = displayName != null && displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'K';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Brand mark ─────────────────────────────────────────────────────
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              'K',
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── App name ───────────────────────────────────────────────────────
          Expanded(
            child: Text(
              'Koolan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cs.primary,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // ── Notification bell ──────────────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    // Auth gate: notifications require sign-in.
                    if (!state.isSignedIn) {
                      showAuthGateSheet(
                        context,
                        reason: AuthGateReason.notifications,
                      );
                      return;
                    }
                    state.pushScreen(NotificationsScreenRoute());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      state.unreadNotificationCount > 0
                          ? Icons.notifications
                          : Icons.notifications_none_outlined,
                      color: state.unreadNotificationCount > 0
                          ? cs.primary
                          : cs.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ),
              ),
              if (state.unreadNotificationCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IgnorePointer(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: cs.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.surface,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        state.unreadNotificationCount > 9
                            ? '9+'
                            : '${state.unreadNotificationCount}',
                        style: TextStyle(
                          color: cs.onError,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),

          // ── Profile avatar ─────────────────────────────────────────────────
          GestureDetector(
            onTap: () {
              // Auth gate: own profile requires sign-in.
              if (!state.isSignedIn) {
                showAuthGateSheet(context, reason: AuthGateReason.profile);
                return;
              }
              state.pushScreen(ProfileScreenRoute());
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        cacheManager: KoolanImageCacheManager.instance,
                        imageBuilder: (ctx, provider) => Image(
                          image: provider,
                          fit: BoxFit.cover,
                          width: 38,
                          height: 38,
                        ),
                        placeholder: (ctx, url) => _AvatarPlaceholder(
                          initials: initials,
                          cs: cs,
                        ),
                        errorWidget: (ctx, url, err) => _AvatarPlaceholder(
                          initials: initials,
                          cs: cs,
                        ),
                      )
                    : _AvatarPlaceholder(initials: initials, cs: cs),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final String initials;
  final ColorScheme cs;
  const _AvatarPlaceholder({required this.initials, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      color: cs.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ── Skeleton shimmer card ─────────────────────────────────────────────────────
//
// Used in the Recommended and Recently-Added sections while [isLoadingData]
// is true and the lists are empty. Pulses between surfaceContainerHighest and
// surfaceContainerHigh to suggest content is on its way.

class _SkeletonCard extends StatefulWidget {
  final double width;
  final double height;
  const _SkeletonCard({required this.width, required this.height});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// ── Recommended for You section ───────────────────────────────────────────────
//
// Caching strategy: recommendations are computed once when the widget first
// builds and cached in [_recommendations]. They are recomputed only when
// [_dataVersion] changes — detected by tracking the combined length of
// allListings + allServices + allHiringPosts at last compute time.
// This prevents re-scoring on every widget rebuild / scroll frame.

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
                      errorWidget: _CategoryIconPlaceholder(
                          category: item.category, cs: cs),
                    )
                  : _CategoryIconPlaceholder(
                      category: item.category, cs: cs),
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

class _CategoryIconPlaceholder extends StatelessWidget {
  final String category;
  final ColorScheme cs;

  const _CategoryIconPlaceholder(
      {required this.category, required this.cs});

  @override
  Widget build(BuildContext context) {
    final icon = switch (category.toUpperCase()) {
      'CARS' => Icons.directions_car_filled,
      'HOUSES' => Icons.home_rounded,
      'LAND' => Icons.landscape_rounded,
      'SKILLS' => Icons.construction_rounded,
      'OTHERS' => Icons.category_outlined,
      _ => Icons.inventory_2_outlined,
    };
    return Container(
      color: cs.primaryContainer.withValues(alpha: 0.25),
      alignment: Alignment.center,
      child: Icon(icon, color: cs.primary, size: 36),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

enum _RecType { listing, service, hiring }

class _RecItem {
  final String id;
  final _RecType type;
  final String title;
  final String category;
  final String? imageUrl;
  final String? price;

  const _RecItem({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    this.imageUrl,
    this.price,
  });

  factory _RecItem.listing(Listing l) => _RecItem(
        id: l.id,
        type: _RecType.listing,
        title: l.title,
        category: l.category,
        imageUrl: l.imageUrl,
        price: l.price,
      );

  factory _RecItem.service(Service s) => _RecItem(
        id: s.id,
        type: _RecType.service,
        title: s.title,
        category: s.category,
        imageUrl: null,
        price: s.priceRange,
      );

  factory _RecItem.hiring(HiringPost p) => _RecItem(
        id: p.id,
        type: _RecType.hiring,
        title: p.title,
        category: p.category,
        imageUrl: null,
        price: p.priceRange,
      );
}
