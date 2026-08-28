part of '../category_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Header, filter strip, filter chips and count row for CategoryListScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Back + search + grid/list toggle row.
class _CategoryHeaderRow extends StatelessWidget {
  final String categoryName;
  final TextEditingController searchController;
  final bool gridMode;
  final VoidCallback onBack;
  final ValueChanged<String> onSearch;
  final VoidCallback onToggleGrid;

  const _CategoryHeaderRow({
    required this.categoryName,
    required this.searchController,
    required this.gridMode,
    required this.onBack,
    required this.onSearch,
    required this.onToggleGrid,
  });

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: cs.primary),
            tooltip: s.wizardBack,
            onPressed: onBack,
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearch,
                style: TextStyle(fontSize: 14, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: '${s.catSearchHint} ${categoryName.toLowerCase()}…',
                  hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                      fontSize: 13),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: cs.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: gridMode ? s.catListView : s.catGridView,
            child: IconButton(
              icon: Icon(
                gridMode ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: cs.primary,
              ),
              onPressed: onToggleGrid,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sort chip + optional reset chip row.
class _FilterStripRow extends StatelessWidget {
  final _SortMode sortMode;
  final bool hasAnyFilter;
  final VoidCallback onSort;
  final VoidCallback onReset;

  const _FilterStripRow({
    required this.sortMode,
    required this.hasAnyFilter,
    required this.onSort,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    final sortLabel = switch (sortMode) {
      _SortMode.newest    => s.catSortNewest,
      _SortMode.priceAsc  => s.catSortPriceAsc,
      _SortMode.priceDesc => s.catSortPriceDsc,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          const Spacer(),
          BrowseFilterChip(
            label: sortLabel,
            selected: sortMode != _SortMode.newest,
            onTap: onSort,
          ),
          const SizedBox(width: 6),
          if (hasAnyFilter)
            GestureDetector(
              onTap: onReset,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 12, color: cs.error),
                    const SizedBox(width: 3),
                    Text(s.catReset,
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.error,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal scrollable row of per-category filter chips.
class _FilterChipsRow extends StatelessWidget {
  final String categoryName;
  final _FilterState filters;
  final VoidCallback onCondition;
  final VoidCallback onPrice;
  final VoidCallback onFuel;
  final VoidCallback onTransmission;
  final VoidCallback onYear;
  final VoidCallback onBedrooms;
  final VoidCallback onLandUse;

  const _FilterChipsRow({
    required this.categoryName,
    required this.filters,
    required this.onCondition,
    required this.onPrice,
    required this.onFuel,
    required this.onTransmission,
    required this.onYear,
    required this.onBedrooms,
    required this.onLandUse,
  });

  @override
  Widget build(BuildContext context) {
    final s = OnemarketAppStateScope.of(context).s;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          // Rent / Buy — all categories
          BrowseFilterChip(
            label: filters.hasConditionFilter
                ? (filters.condition == 'For Sale'
                    ? s.catFilterSale
                    : s.catFilterRent)
                : s.catRentBuy,
            selected: filters.hasConditionFilter,
            onTap: onCondition,
          ),
          const SizedBox(width: 8),
          // Price range — all categories
          BrowseFilterChip(
            label: filters.hasPriceFilter
                ? _priceRangeLabel(filters.minPrice, filters.maxPrice)
                : s.catPriceRange,
            selected: filters.hasPriceFilter,
            onTap: onPrice,
          ),
          const SizedBox(width: 8),
          // CARS-specific
          if (categoryName == 'CARS' || categoryName == 'ALL') ...[
            BrowseFilterChip(
              label:
                  filters.hasFuelFilter ? filters.fuelType! : s.catCarFuelType,
              selected: filters.hasFuelFilter,
              onTap: onFuel,
            ),
            const SizedBox(width: 8),
            BrowseFilterChip(
              label: filters.hasTransFilter
                  ? filters.transmission!
                  : s.catCarTransmission,
              selected: filters.hasTransFilter,
              onTap: onTransmission,
            ),
            const SizedBox(width: 8),
            BrowseFilterChip(
              label: filters.hasYearFilter
                  ? _yearRangeLabel(filters.yearMin, filters.yearMax)
                  : s.catCarYearRange,
              selected: filters.hasYearFilter,
              onTap: onYear,
            ),
            const SizedBox(width: 8),
          ],
          // HOUSES-specific
          if (categoryName == 'HOUSES' || categoryName == 'ALL') ...[
            BrowseFilterChip(
              label: filters.hasBedroomFilter
                  ? '${filters.minBedrooms}+ ${s.catBedrooms}'
                  : s.catBedrooms,
              selected: filters.hasBedroomFilter,
              onTap: onBedrooms,
            ),
            const SizedBox(width: 8),
          ],
          // LAND-specific
          if (categoryName == 'LAND' || categoryName == 'ALL') ...[
            BrowseFilterChip(
              label: filters.hasLandFilter ? filters.landUse! : s.catLandUse,
              selected: filters.hasLandFilter,
              onTap: onLandUse,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  static String _priceRangeLabel(double? min, double? max) {
    String fmt(double v) {
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
      return v.toStringAsFixed(0);
    }
    if (min != null && max != null) return '${fmt(min)}–${fmt(max)}';
    if (min != null) return '≥ ${fmt(min)}';
    return '≤ ${fmt(max!)}';
  }

  static String _yearRangeLabel(int? min, int? max) {
    if (min != null && max != null) return '$min–$max';
    if (min != null) return '≥ $min';
    return '≤ $max';
  }
}

/// Result count line.
class _ResultCountRow extends StatelessWidget {
  final int count;
  const _ResultCountRow({required this.count});

  @override
  Widget build(BuildContext context) {
    final s  = OnemarketAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Text(
        s.catResultsCount.replaceAll('{count}', '$count'),
        style: TextStyle(
          fontSize: 11,
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// Generic options bottom sheet — used by all filter pickers.
void _showOptionsSheet(
  BuildContext context, {
  required String title,
  required List<({String label, String value})> options,
  required String selected,
  required ValueChanged<String> onSelect,
}) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface)),
              const SizedBox(height: 12),
              ...options.map((opt) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(opt.label,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: opt.value == selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                    trailing: opt.value == selected
                        ? Icon(Icons.check, color: cs.primary)
                        : null,
                    onTap: () {
                      onSelect(opt.value);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      );
    },
  );
}
