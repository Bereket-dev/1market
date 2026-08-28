part of '../category_list_screen.dart';

// ── Feed variants ─────────────────────────────────────────────────────────────

class _ListFeed extends StatelessWidget {
  final List<Listing> results;
  final OnemarketAppState state;
  final ScrollController scrollController;
  const _ListFeed({required this.results, required this.state, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = results[index];
        return PremiumClassifiedCard(
          listing: item,
          onSaveToggle: () => state.toggleSaveListing(item.id),
          onTap: () => state.pushScreen(ListingDetailScreenRoute(item.id)),
        );
      },
    );
  }
}

class _GridFeed extends StatelessWidget {
  final List<Listing> results;
  final OnemarketAppState state;
  final ScrollController scrollController;
  const _GridFeed({required this.results, required this.state, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListingCompactCard(
          listing: item,
          onSaveToggle: () => state.toggleSaveListing(item.id),
          onTap: () => state.pushScreen(ListingDetailScreenRoute(item.id)),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppStrings s;
  final ColorScheme cs;
  const _EmptyState({required this.s, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(s.catNoMatchingListings,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(s.catClearFilters,
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

