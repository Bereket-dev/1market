import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/auth_gate_sheet.dart';
import '../widgets/car_card.dart';
part 'widgets/category_list_sheets.dart';
part 'widgets/category_list_header.dart';
part 'widgets/category_list_filter_state.dart';
part 'widgets/category_list_feeds.dart';

// ── Sort mode ─────────────────────────────────────────────────────────────────

class CategoryListScreen extends StatefulWidget {
  final String categoryName;
  const CategoryListScreen({super.key, required this.categoryName});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _gridMode = true;              // default: 2-column grid to show more items
  _SortMode _sortMode = _SortMode.newest;
  final _filters = _FilterState();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = KoolanAppStateScope.of(context);
      state.selectedCategory = widget.categoryName;
      state.searchQuery = '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= maxScroll - 300) {
      KoolanAppStateScope.of(context).loadMoreListings();
    }
  }

  Future<void> _onRefresh() async {
    await KoolanAppStateScope.of(context).loadAllData();
  }

  // ── Filter actions ────────────────────────────────────────────────────────

  void _showConditionPicker() {
    final s = KoolanAppStateScope.of(context).s;
    final options = [
      (label: s.catFilterAll,  value: 'all'),
      (label: s.catFilterSale, value: 'For Sale'),
      (label: s.catFilterRent, value: 'For Rent'),
    ];
    _showOptionsSheet(
      title: s.catRentBuy,
      options: options,
      selected: _filters.condition,
      onSelect: (v) => setState(() => _filters.condition = v),
    );
  }

  void _showBedroomPicker() {
    final s = KoolanAppStateScope.of(context).s;
    final options = [
      (label: s.catFilterAll, value: 'all'),
      (label: '1+', value: '1'),
      (label: '2+', value: '2'),
      (label: '3+', value: '3'),
      (label: '4+', value: '4'),
    ];
    _showOptionsSheet(
      title: s.catBedrooms,
      options: options,
      selected: _filters.minBedrooms?.toString() ?? 'all',
      onSelect: (v) => setState(() {
        _filters.minBedrooms = v == 'all' ? null : int.tryParse(v);
      }),
    );
  }

  void _showLandUsePicker() {
    final s = KoolanAppStateScope.of(context).s;
    final options = [
      (label: s.catFilterAll,         value: 'all'),
      (label: s.catLandResidential,   value: 'Residential'),
      (label: s.catLandAgricultural,  value: 'Agricultural'),
      (label: s.catLandCommercial,    value: 'Commercial'),
    ];
    _showOptionsSheet(
      title: s.catLandUse,
      options: options,
      selected: _filters.landUse ?? 'all',
      onSelect: (v) => setState(() {
        _filters.landUse = v == 'all' ? null : v;
      }),
    );
  }

  void _showFuelTypePicker() {
    final s = KoolanAppStateScope.of(context).s;
    final options = [
      (label: s.catFilterAll,    value: 'all'),
      (label: s.catFuelPetrol,   value: 'Petrol'),
      (label: s.catFuelDiesel,   value: 'Diesel'),
      (label: s.catFuelHybrid,   value: 'Hybrid'),
      (label: s.catFuelElectric, value: 'Electric'),
    ];
    _showOptionsSheet(
      title: s.catCarFuelType,
      options: options,
      selected: _filters.fuelType ?? 'all',
      onSelect: (v) => setState(() {
        _filters.fuelType = v == 'all' ? null : v;
      }),
    );
  }

  void _showTransmissionPicker() {
    final s = KoolanAppStateScope.of(context).s;
    final options = [
      (label: s.catFilterAll,    value: 'all'),
      (label: s.catTransAuto,    value: 'Automatic'),
      (label: s.catTransManual,  value: 'Manual'),
    ];
    _showOptionsSheet(
      title: s.catCarTransmission,
      options: options,
      selected: _filters.transmission ?? 'all',
      onSelect: (v) => setState(() {
        _filters.transmission = v == 'all' ? null : v;
      }),
    );
  }

  void _showYearSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _YearRangeSheet(
        initialMin: _filters.yearMin,
        initialMax: _filters.yearMax,
        onApply: (min, max) {
          setState(() {
            _filters.yearMin = min;
            _filters.yearMax = max;
          });
        },
      ),
    );
  }

  void _showSortPicker() {
    final s = KoolanAppStateScope.of(context).s;
    final options = [
      (label: s.catSortNewest,   value: 'newest'),
      (label: s.catSortPriceAsc, value: 'priceAsc'),
      (label: s.catSortPriceDsc, value: 'priceDesc'),
    ];
    _showOptionsSheet(
      title: s.catSortLabel,
      options: options,
      selected: _sortMode.name,
      onSelect: (v) => setState(() {
        _sortMode = _SortMode.values.firstWhere(
          (e) => e.name == v,
          orElse: () => _SortMode.newest,
        );
      }),
    );
  }

  void _showPriceSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PriceRangeSheet(
        initialMin: _filters.minPrice,
        initialMax: _filters.maxPrice,
        onApply: (min, max) {
          setState(() {
            _filters.minPrice = min;
            _filters.maxPrice = max;
          });
        },
      ),
    );
  }

  void _showOptionsSheet({
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = KoolanAppStateScope.of(context);
    final s = state.s;
    final cs = Theme.of(context).colorScheme;

    // Apply category + search first (via app_state), then local filters, then sort.
    final base     = state.getFilteredListings();
    final filtered = _filters.apply(base);
    final results  = _applySortMode(filtered, _sortMode);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Auth gate: posting requires sign-in.
          if (!state.isSignedIn) {
            showAuthGateSheet(context, reason: AuthGateReason.post);
            return;
          }
          state.postCategory =
              widget.categoryName == 'ALL' ? 'CARS' : widget.categoryName;
          state.pushScreen(PostWizardScreenRoute());
        },
        tooltip: 'Post a listing',
        backgroundColor: cs.primaryContainer,
        child: Icon(Icons.add, color: cs.onPrimaryContainer),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        displacement: 60,
        strokeWidth: 2.5,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: cs.primary),
                  tooltip: s.wizardBack,
                  onPressed: () => state.popScreen(),
                ),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: state.setSearchQuery,
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText:
                            '${s.catSearchHint} ${widget.categoryName.toLowerCase()}…',
                        hintStyle: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                            fontSize: 13),
                        prefixIcon: Icon(Icons.search,
                            size: 18, color: cs.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Grid / List toggle
                Tooltip(
                  message: _gridMode ? s.catListView : s.catGridView,
                  child: IconButton(
                    icon: Icon(
                      _gridMode
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      color: cs.primary,
                    ),
                    onPressed: () => setState(() => _gridMode = !_gridMode),
                  ),
                ),
              ],
            ),
          ),

          // ── Filter strip ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Row(
              children: [
                const Spacer(),
                // Sort chip
                BrowseFilterChip(
                  label: _sortLabel(s, _sortMode),
                  selected: _sortMode != _SortMode.newest,
                  onTap: _showSortPicker,
                ),
                const SizedBox(width: 6),
                // Reset chip — only visible when a filter is active
                if (_filters.hasAnyFilter)
                  GestureDetector(
                    onTap: () => setState(() => _filters.reset()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
          ),

          // ── Filter chips ──────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                // Rent / Buy — all categories
                BrowseFilterChip(
                  label: _filters.hasConditionFilter
                      ? (_filters.condition == 'For Sale'
                          ? s.catFilterSale
                          : s.catFilterRent)
                      : s.catRentBuy,
                  selected: _filters.hasConditionFilter,
                  onTap: _showConditionPicker,
                ),
                const SizedBox(width: 8),
                // Price range — all categories
                BrowseFilterChip(
                  label: _filters.hasPriceFilter
                      ? _priceRangeLabel(_filters.minPrice, _filters.maxPrice)
                      : s.catPriceRange,
                  selected: _filters.hasPriceFilter,
                  onTap: _showPriceSheet,
                ),
                const SizedBox(width: 8),
                // ── CARS-specific chips ──────────────────────────────────
                if (widget.categoryName == 'CARS' ||
                    widget.categoryName == 'ALL') ...[
                  BrowseFilterChip(
                    label: _filters.hasFuelFilter
                        ? _filters.fuelType!
                        : s.catCarFuelType,
                    selected: _filters.hasFuelFilter,
                    onTap: _showFuelTypePicker,
                  ),
                  const SizedBox(width: 8),
                  BrowseFilterChip(
                    label: _filters.hasTransFilter
                        ? _filters.transmission!
                        : s.catCarTransmission,
                    selected: _filters.hasTransFilter,
                    onTap: _showTransmissionPicker,
                  ),
                  const SizedBox(width: 8),
                  BrowseFilterChip(
                    label: _filters.hasYearFilter
                        ? _yearRangeLabel(_filters.yearMin, _filters.yearMax)
                        : s.catCarYearRange,
                    selected: _filters.hasYearFilter,
                    onTap: _showYearSheet,
                  ),
                  const SizedBox(width: 8),
                ],
                // ── HOUSES-specific chips ────────────────────────────────
                if (widget.categoryName == 'HOUSES' ||
                    widget.categoryName == 'ALL') ...[
                  BrowseFilterChip(
                    label: _filters.hasBedroomFilter
                        ? '${_filters.minBedrooms}+ ${s.catBedrooms}'
                        : s.catBedrooms,
                    selected: _filters.hasBedroomFilter,
                    onTap: _showBedroomPicker,
                  ),
                  const SizedBox(width: 8),
                ],
                // ── LAND-specific chips ──────────────────────────────────
                if (widget.categoryName == 'LAND' ||
                    widget.categoryName == 'ALL') ...[
                  BrowseFilterChip(
                    label: _filters.hasLandFilter
                        ? _filters.landUse!
                        : s.catLandUse,
                    selected: _filters.hasLandFilter,
                    onTap: _showLandUsePicker,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),

          // ── Count ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              s.catResultsCount.replaceAll('{count}', '${results.length}'),
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),

          // ── Feed ──────────────────────────────────────────────────────
          Expanded(
            child: results.isEmpty
                ? _EmptyState(s: s, cs: cs)
                : _gridMode
                    ? _GridFeed(
                        results: results,
                        state: state,
                        scrollController: _scrollController,
                      )
                    : _ListFeed(
                        results: results,
                        state: state,
                        scrollController: _scrollController,
                      ),
          ),
          // ── Load-more indicator ────────────────────────────────────────
          if (state.isLoadingMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      ), // RefreshIndicator
    );
  }

  String _priceRangeLabel(double? min, double? max) {
    if (min != null && max != null) return '${_fmt(min)}–${_fmt(max)}';
    if (min != null) return '≥ ${_fmt(min)}';
    return '≤ ${_fmt(max!)}';
  }

  String _yearRangeLabel(int? min, int? max) {
    if (min != null && max != null) return '$min–$max';
    if (min != null) return '≥ $min';
    return '≤ $max';
  }

  String _sortLabel(AppStrings s, _SortMode mode) => switch (mode) {
        _SortMode.newest   => s.catSortNewest,
        _SortMode.priceAsc => s.catSortPriceAsc,
        _SortMode.priceDesc => s.catSortPriceDsc,
      };

  List<Listing> _applySortMode(List<Listing> list, _SortMode mode) {
    final copy = List<Listing>.from(list);
    switch (mode) {
      case _SortMode.newest:
        // already ordered by created_at desc from the repository
        break;
      case _SortMode.priceAsc:
        copy.sort((a, b) =>
            (_parsePrice(a.price) ?? 0).compareTo(_parsePrice(b.price) ?? 0));
      case _SortMode.priceDesc:
        copy.sort((a, b) =>
            (_parsePrice(b.price) ?? 0).compareTo(_parsePrice(a.price) ?? 0));
    }
    return copy;
  }

  static double? _parsePrice(String price) {
    final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned);
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Feed variants ─────────────────────────────────────────────────────────────
