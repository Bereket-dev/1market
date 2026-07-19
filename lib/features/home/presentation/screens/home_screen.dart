import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/cached_image_widget.dart';
import '../widgets/category_card.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/trust_badge_card.dart';
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

                  // Trust strip
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.s.homeTrustTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content:
                                          Text(state.s.homeVerifiedStats))),
                              child: Text(state.s.homeSeeStats,
                                  style: TextStyle(color: cs.primary)),
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(children: [
                          TrustBadgeCard(
                            icon: Icons.home,
                            text: state.s.homeTrustHomeowner,
                          ),
                          const SizedBox(width: 16),
                          TrustBadgeCard(
                            icon: Icons.person,
                            text: state.s.homeTrustDriver,
                          ),
                        ]),
                      ),
                    ],
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
                  onTap: () => state.pushScreen(NotificationsScreenRoute()),
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
            onTap: () => state.pushScreen(ProfileScreenRoute()),
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
