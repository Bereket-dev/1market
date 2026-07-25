part of '../home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Scrollable body sections for HomeScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Greeting headline + 2×2+1 category card grid.
class _CategoryGridSection extends StatelessWidget {
  const _CategoryGridSection();

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s  = state.s;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.homeGreeting,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: CompactCategoryCard(
                title: s.homeCategoryCars,
                subtitle: s.homeCategoryCars,
                icon: Icons.directions_car_filled,
                color: const Color(0xFF1E40AF),
                onTap: () => state.pushScreen(CategoryListScreenRoute('CARS')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CompactCategoryCard(
                title: s.homeCategoryHouses,
                subtitle: s.homeCategoryHouses,
                icon: Icons.home_rounded,
                color: const Color(0xFF0F766E),
                onTap: () =>
                    state.pushScreen(CategoryListScreenRoute('HOUSES')),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: CompactCategoryCard(
                title: s.homeCategoryLand,
                subtitle: s.homeCategoryLand,
                icon: Icons.landscape_rounded,
                color: const Color(0xFF92400E),
                onTap: () => state.pushScreen(CategoryListScreenRoute('LAND')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CompactCategoryCard(
                title: s.homeCategorySkills,
                subtitle: s.homeCategorySkills,
                icon: Icons.construction_rounded,
                color: const Color(0xFF6D28D9),
                onTap: () =>
                    state.pushScreen(CategoryListScreenRoute('SKILLS')),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          // Others — full-width (5th category, layout 2+2+1)
          CompactCategoryCard(
            title: s.homeCategoryOthers,
            subtitle: s.homeCategoryOthers,
            icon: Icons.category_outlined,
            color: const Color(0xFF475569),
            onTap: () => state.pushScreen(CategoryListScreenRoute('OTHERS')),
          ),
        ],
      ),
    );
  }
}

/// Tappable search bar that navigates to the ALL category list.
class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: InkWell(
        onTap: () => state.pushScreen(CategoryListScreenRoute('ALL')),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(children: [
            Icon(Icons.search, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              state.s.homeSearchHint,
              style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Gradient banner that opens the hiring/jobs browse screen.
class _FindJobsBanner extends StatelessWidget {
  const _FindJobsBanner();

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s  = state.s;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: InkWell(
        onTap: () => state.pushScreen(HiringBrowseScreenRoute()),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.work_outline, color: cs.onPrimary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.hiringBrowseTitle,
                        style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      s.hiringBrowseSearchHint,
                      style: TextStyle(
                          color: cs.onPrimary.withValues(alpha: 0.8),
                          fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: cs.onPrimary.withValues(alpha: 0.8), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recently-added section: up-to-3 listing cards + "View all" button.
/// Shows skeleton placeholders while data is loading.
class _RecentlyAddedSection extends StatelessWidget {
  const _RecentlyAddedSection();

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s  = state.s;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.homeRecentlyAdded,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 16),
          if (state.isLoadingData && state.allListings.isEmpty)
            Column(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: EdgeInsets.only(bottom: i < 2 ? 12 : 0),
                  child: const _SkeletonCard(width: double.infinity, height: 80),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(state.allListings.length, 3),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final listing = state.allListings[index];
                return RecentListingCard(
                  listing: listing,
                  onTap: () =>
                      state.pushScreen(ListingDetailScreenRoute(listing.id)),
                );
              },
            ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => state.pushScreen(CategoryListScreenRoute('ALL')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Text(s.homeViewAll,
                style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
