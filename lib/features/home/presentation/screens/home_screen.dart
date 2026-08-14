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
import '../../../../shared/widgets/sync_status_banner.dart';
import '../widgets/category_card.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/recent_listing_card.dart';
import '../../../../shared/widgets/location_cta_banner.dart';
part 'widgets/home_skeleton.dart';
part 'widgets/home_sections.dart';
part 'widgets/home_recommended.dart';
part 'widgets/home_models.dart';
part 'widgets/home_header.dart';

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

          const SyncStatusBanner(),

          // ── Scrollable body ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Location permission CTA (re-prompt after onboarding skip) ─
                  const LocationCtaBanner(),

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
          state.pushScreen(PostWizardScreenRoute());
        },
        backgroundColor: cs.primaryContainer,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: cs.onPrimaryContainer, size: 28),
      ),
    );
  }
}

// ── Home header ───────────────────────────────────────────────────────────────
