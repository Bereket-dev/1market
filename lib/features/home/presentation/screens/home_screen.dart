import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/services/app_state.dart';
import '../widgets/lang_pill.dart';
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
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.outlineVariant),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Koolan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                ]),
                Row(children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none,
                        color: cs.onSurfaceVariant),
                    onPressed: () => ScaffoldMessenger.of(context)
                        .showSnackBar(
                            SnackBar(content: Text(state.s.homeNoNotifications))),
                  ),
                  // Language toggle pill
                  GestureDetector(
                    onTap: state.toggleLocale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 34,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LangPillSegment(
                              label: 'EN', isActive: state.locale == 'en'),
                          LangPillSegment(
                              label: 'አማ', isActive: state.locale == 'am'),
                          LangPillSegment(
                              label: 'SO', isActive: state.locale == 'so'),
                        ],
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),

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
                              subtitle: 'Gawaarida',
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
                              subtitle: 'Guryaha',
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
                              subtitle: 'Dhul',
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
                              subtitle: 'Xirfadlayaasha',
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
                        child: const Row(children: [
                          TrustBadgeCard(
                            icon: Icons.home,
                            text:
                                'A homeowner in Kebele 03 just got verified',
                          ),
                          SizedBox(width: 16),
                          TrustBadgeCard(
                            icon: Icons.person,
                            text:
                                'A security professional driver just joined',
                          ),
                        ]),
                      ),
                    ],
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
                          separatorBuilder: (_, __) =>
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
