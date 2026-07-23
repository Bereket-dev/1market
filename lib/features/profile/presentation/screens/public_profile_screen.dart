import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../shared/models/profile.dart';
import '../../../../shared/models/service.dart';
import '../../../../shared/models/service_review.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';

/// Read-only public profile view for any user identified by [userId].
///
/// Shows avatar, name, bio, rating, services and reviews received.
class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final state = KoolanAppStateScope.of(context);
    try {
      await Future.wait([
        state.loadPublicProfile(widget.userId),
        state.loadReviewsForUser(widget.userId),
      ]);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    final profile = state.getCachedPublicProfile(widget.userId);
    final reviews = state.getReviewsForUser(widget.userId);
    // All services belonging to this user that are available
    final services = state.allServices
        .where((sv) => sv.ownerId == widget.userId)
        .toList();

    if (_loading && profile == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            onPressed: () => state.popScreen(),
          ),
          title: Text(s.publicProfileTitle),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(s.publicProfileLoading,
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    if (_error != null && profile == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            onPressed: () => state.popScreen(),
          ),
          title: Text(s.publicProfileTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_off_outlined, size: 64, color: cs.outline),
                const SizedBox(height: 16),
                Text(s.publicProfileNotFound,
                    style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _load,
                  child: Text(s.commonRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _ProfileSliverHeader(
            state: state,
            profile: profile,
            reviews: reviews,
            onBack: () => state.popScreen(),
          ),
        ],
        body: Column(
          children: [
            // Tab bar
            Material(
              color: cs.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: cs.primary,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                tabs: [
                  Tab(text: s.publicProfileServices),
                  Tab(
                    text: s.publicProfileReviews +
                        (reviews.isNotEmpty ? ' (${reviews.length})' : ''),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Services tab ────────────────────────────────────────────
                  _ServicesTab(
                    services: services,
                    state: state,
                  ),
                  // ── Reviews tab ─────────────────────────────────────────────
                  _ReviewsTab(reviews: reviews, state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sliver header: banner, avatar, name, bio, stats
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSliverHeader extends StatelessWidget {
  final KoolanAppState state;
  final UserProfile? profile;
  final List<ServiceReview> reviews;
  final VoidCallback onBack;

  const _ProfileSliverHeader({
    required this.state,
    required this.profile,
    required this.reviews,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = state.s;
    final displayName = profile?.displayName ?? '—';
    final bio = profile?.bio ?? '';
    final rating = profile?.rating ?? 0.0;
    final reviewsCount = profile?.reviewsCount ?? reviews.length;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner + back button ─────────────────────────────────────────
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Banner
                if (profile?.bannerUrl != null &&
                    profile!.bannerUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: profile!.bannerUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: cs.primaryContainer.withValues(alpha: 0.25)),
                    errorWidget: (_, _, _) =>
                        Container(color: cs.primaryContainer.withValues(alpha: 0.25)),
                  )
                else
                  Container(color: cs.primaryContainer.withValues(alpha: 0.25)),

                // Gradient scrim
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onBack,
                      child: const Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(Icons.arrow_back,
                            size: 22, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Avatar row ───────────────────────────────────────────────────
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: cs.primaryContainer,
                      child: profile?.avatarUrl != null &&
                              profile!.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: profile!.avatarUrl!,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) =>
                                    _InitialsFallback(name: displayName, cs: cs),
                              ),
                            )
                          : _InitialsFallback(name: displayName, cs: cs),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Verified badge (if applicable)
                  if (profile != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: cs.tertiary.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: cs.tertiary, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            s.detailVerified,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: cs.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Name + bio + rating ──────────────────────────────────────────
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Rating row
                  Row(
                    children: [
                      RatingStars(
                        rating: rating,
                        reviewCount: reviewsCount > 0 ? reviewsCount : null,
                      ),
                    ],
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      bio,
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(
                      s.publicProfileNoBio,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Services tab
// ─────────────────────────────────────────────────────────────────────────────

class _ServicesTab extends StatelessWidget {
  final List<Service> services;
  final KoolanAppState state;

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
  final KoolanAppState state;
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
  final KoolanAppState state;

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
