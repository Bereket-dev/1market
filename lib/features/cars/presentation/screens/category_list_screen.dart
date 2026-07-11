import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/services/app_state.dart';
import '../widgets/car_card.dart';
import '../widgets/car_filter_sheet.dart';

/// Browse screen for a single category (CARS / HOUSES / LAND / SKILLS / ALL).
class CategoryListScreen extends StatefulWidget {
  final String categoryName;
  const CategoryListScreen({super.key, required this.categoryName});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _verifiedOnly = false;
  String _rentBuySelected = 'Buy';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = KoolanAppStateScope.of(context);
      state.selectedCategory = widget.categoryName;
      state.searchQuery = '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final results = state
        .getFilteredListings()
        .where((l) => !_verifiedOnly || l.verified)
        .toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          state.postCategory =
              widget.categoryName == 'ALL' ? 'CARS' : widget.categoryName;
          state.pushScreen(PostWizardScreenRoute());
        },
        backgroundColor: cs.primaryContainer,
        child: Icon(Icons.add, color: cs.onPrimaryContainer),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: cs.primary),
                  onPressed: () => state.popScreen(),
                ),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: state.setSearchQuery,
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText:
                            'Search ${widget.categoryName.toLowerCase()}...',
                        hintStyle:
                            TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                        prefixIcon: Icon(Icons.search,
                            size: 20, color: cs.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Filter strip ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // List / Map toggle pill
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              'List',
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: Text(
                              'Map',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Verified toggle
                    Row(
                      children: [
                        Text(
                          state.s.catVerifiedOnly,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _verifiedOnly,
                          onChanged: (val) =>
                              setState(() => _verifiedOnly = val),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      BrowseFilterChip(
                        label: state.s.isAmharic
                            ? '${state.s.catForRent} / ${state.s.catForSale}'
                            : state.s.isSomali
                                ? '${state.s.catForRent} / ${state.s.catForSale}'
                                : 'Rent / Buy',
                        selected: _rentBuySelected != 'Buy',
                        onTap: () => setState(() => _rentBuySelected =
                            _rentBuySelected == 'Buy' ? 'Rent' : 'Buy'),
                      ),
                      const SizedBox(width: 8),
                      BrowseFilterChip(
                        label: state.s.isAmharic
                            ? 'የዋጋ ክልል'
                            : state.s.isSomali
                                ? 'Xadka qiimaha'
                                : 'Price Range',
                      ),
                      const SizedBox(width: 8),
                      if (widget.categoryName == 'HOUSES' ||
                          widget.categoryName == 'ALL') ...[
                        BrowseFilterChip(
                          label: state.s.isAmharic
                              ? 'አልጋ ቤቶች'
                              : state.s.isSomali
                                  ? 'Qolalka jiifka'
                                  : 'Bedrooms',
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (widget.categoryName == 'LAND' ||
                          widget.categoryName == 'ALL') ...[
                        BrowseFilterChip(
                          label: state.s.isAmharic
                              ? 'የመሬት አጠቃቀም'
                              : state.s.isSomali
                                  ? 'Isticmaalka dhulka'
                                  : 'Land-use',
                        ),
                        const SizedBox(width: 8),
                      ],
                      BrowseFilterChip(
                        label: state.s.isAmharic
                            ? 'ተጨማሪ'
                            : state.s.isSomali
                                ? 'Wax dheeraad ah'
                                : 'More',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Count ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              '${results.length} results in Jigjiga',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),

          // ── Feed ──────────────────────────────────────────────────────────
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color:
                              cs.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No matching listings found',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try clearing your query filters',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return PremiumClassifiedCard(
                        listing: item,
                        onSaveToggle: () =>
                            state.toggleSaveListing(item.id),
                        onTap: () => state.pushScreen(
                            ListingDetailScreenRoute(item.id)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


