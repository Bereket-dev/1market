import 'package:flutter/material.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/models/app_strings.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/services/app_state.dart';
import '../../../../shared/widgets/auth_gate_sheet.dart';
import '../widgets/car_card.dart';

// ── Sort mode ─────────────────────────────────────────────────────────────────

enum _SortMode { newest, priceAsc, priceDesc }

// ── Filter state ──────────────────────────────────────────────────────────────

/// All active filter values for the browse screen.
/// Keeps filtering logic in one place so it's easy to extend later.
class _FilterState {
  /// 'all' | 'For Sale' | 'For Rent' — matches conditionOrStatus in DB.
  String condition = 'all';

  /// Bedroom minimum (HOUSES only). null = no filter.
  int? minBedrooms;

  /// Land-use filter (LAND only). null = no filter.
  String? landUse;

  /// Minimum price (numeric). null = no filter.
  double? minPrice;

  /// Maximum price (numeric). null = no filter.
  double? maxPrice;

  // ── Car-specific filters (CARS category) ──────────────────────────────────

  /// 'Petrol' | 'Diesel' | 'Hybrid' | 'Electric' | null = no filter.
  /// Matched against spec value with label containing 'Fuel'.
  String? fuelType;

  /// 'Automatic' | 'Manual' | null = no filter.
  /// Matched against spec value with label containing 'Transmission'.
  String? transmission;

  /// Minimum manufacture year (e.g. 2018). null = no filter.
  int? yearMin;

  /// Maximum manufacture year (e.g. 2024). null = no filter.
  int? yearMax;

  // ── Derived predicates ─────────────────────────────────────────────────────

  bool get hasConditionFilter  => condition != 'all';
  bool get hasBedroomFilter    => minBedrooms != null;
  bool get hasLandFilter       => landUse != null;
  bool get hasPriceFilter      => minPrice != null || maxPrice != null;
  bool get hasFuelFilter       => fuelType != null;
  bool get hasTransFilter      => transmission != null;
  bool get hasYearFilter       => yearMin != null || yearMax != null;

  bool get hasAnyFilter =>
      hasConditionFilter ||
      hasBedroomFilter  ||
      hasLandFilter     ||
      hasPriceFilter    ||
      hasFuelFilter     ||
      hasTransFilter    ||
      hasYearFilter;

  void reset() {
    condition    = 'all';
    minBedrooms  = null;
    landUse      = null;
    minPrice     = null;
    maxPrice     = null;
    fuelType     = null;
    transmission = null;
    yearMin      = null;
    yearMax      = null;
  }

  /// Applies this filter state to [listings].
  List<Listing> apply(List<Listing> listings) {
    return listings.where((l) {
      // ── Condition / status ─────────────────────────────────────────────────
      // DB values seen in seed: 'For Sale', 'Good Condition', 'Available'.
      // We match 'For Sale' → contains 'sale'; 'For Rent' → contains 'rent'.
      if (hasConditionFilter) {
        final c = l.conditionOrStatus.toLowerCase();
        if (condition == 'For Sale' &&
            !c.contains('sale') &&
            !c.contains('new')) { return false; }
        if (condition == 'For Rent' &&
            !c.contains('rent') &&
            !c.contains('kiradda')) { return false; }
      }

      // ── Bedrooms (HOUSES) ──────────────────────────────────────────────────
      if (hasBedroomFilter) {
        final bedsStr = _specValue(l, 'Bedrooms') ??
            _specValue(l, 'Bed');
        final beds = bedsStr != null ? _parseNumber(bedsStr) : null;
        if (beds == null || beds < minBedrooms!) return false;
      }

      // ── Land-use (LAND) ────────────────────────────────────────────────────
      if (hasLandFilter) {
        final use = _specValue(l, 'Land Use') ?? _specValue(l, 'LandUse');
        if (use == null ||
            !use.toLowerCase().contains(landUse!.toLowerCase())) {
          return false;
        }
      }

      // ── Price ──────────────────────────────────────────────────────────────
      if (hasPriceFilter) {
        final priceNum = _parsePrice(l.price);
        if (priceNum != null) {
          if (minPrice != null && priceNum < minPrice!) return false;
          if (maxPrice != null && priceNum > maxPrice!) return false;
        }
      }

      // ── Fuel type (CARS) ───────────────────────────────────────────────────
      if (hasFuelFilter) {
        final fuel = _specValue(l, 'Fuel');
        if (fuel == null ||
            !fuel.toLowerCase().contains(fuelType!.toLowerCase())) {
          return false;
        }
      }

      // ── Transmission (CARS) ────────────────────────────────────────────────
      if (hasTransFilter) {
        final trans = _specValue(l, 'Transmission');
        if (trans == null ||
            !trans.toLowerCase().contains(transmission!.toLowerCase())) {
          return false;
        }
      }

      // ── Year (CARS) ────────────────────────────────────────────────────────
      if (hasYearFilter) {
        final yearStr = _specValue(l, 'Year');
        final year    = yearStr != null ? _parseNumber(yearStr) : null;
        if (year == null) return false;
        if (yearMin != null && year < yearMin!) return false;
        if (yearMax != null && year > yearMax!) return false;
      }

      return true;
    }).toList();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Finds a spec value by matching [labelHint] against spec1–4 labels
  /// (case-insensitive prefix/contains match).
  static String? _specValue(Listing l, String labelHint) {
    final hint = labelHint.toLowerCase();
    if (l.spec1Label?.toLowerCase().contains(hint) == true) return l.spec1Value;
    if (l.spec2Label?.toLowerCase().contains(hint) == true) return l.spec2Value;
    if (l.spec3Label?.toLowerCase().contains(hint) == true) return l.spec3Value;
    if (l.spec4Label?.toLowerCase().contains(hint) == true) return l.spec4Value;
    return null;
  }

  /// Extracts the first integer found in a string like "4 Bed" → 4.
  static int? _parseNumber(String s) {
    final m = RegExp(r'\d+').firstMatch(s);
    return m != null ? int.tryParse(m.group(0)!) : null;
  }

  /// Extracts numeric price from strings like "ETB 4,200,000" or "$42,500".
  /// Strips all non-digit/period characters then parses.
  static double? _parsePrice(String price) {
    final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned);
  }
}

// ── Main screen ───────────────────────────────────────────────────────────────

/// Browse screen for a single category (CARS / HOUSES / LAND / SKILLS / ALL).
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

class _ListFeed extends StatelessWidget {
  final List<Listing> results;
  final KoolanAppState state;
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
  final KoolanAppState state;
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

// ── Price range bottom sheet ──────────────────────────────────────────────────

class _PriceRangeSheet extends StatefulWidget {
  final double? initialMin;
  final double? initialMax;
  final void Function(double? min, double? max) onApply;

  const _PriceRangeSheet({
    required this.initialMin,
    required this.initialMax,
    required this.onApply,
  });

  @override
  State<_PriceRangeSheet> createState() => _PriceRangeSheetState();
}

class _PriceRangeSheetState extends State<_PriceRangeSheet> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
        text: widget.initialMin?.toStringAsFixed(0) ?? '');
    _maxCtrl = TextEditingController(
        text: widget.initialMax?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.catPriceRange,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.catPriceMin,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('–', style: TextStyle(fontSize: 18)),
              ),
              Expanded(
                child: TextField(
                  controller: _maxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.catPriceMax,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(null, null);
                    Navigator.pop(context);
                  },
                  child: Text(s.catReset),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final min = double.tryParse(_minCtrl.text.trim());
                    final max = double.tryParse(_maxCtrl.text.trim());
                    widget.onApply(min, max);
                    Navigator.pop(context);
                  },
                  child: Text(s.catApply),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Year range bottom sheet ───────────────────────────────────────────────────

class _YearRangeSheet extends StatefulWidget {
  final int? initialMin;
  final int? initialMax;
  final void Function(int? min, int? max) onApply;

  const _YearRangeSheet({
    required this.initialMin,
    required this.initialMax,
    required this.onApply,
  });

  @override
  State<_YearRangeSheet> createState() => _YearRangeSheetState();
}

class _YearRangeSheetState extends State<_YearRangeSheet> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
        text: widget.initialMin?.toString() ?? '');
    _maxCtrl = TextEditingController(
        text: widget.initialMax?.toString() ?? '');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s  = KoolanAppStateScope.of(context).s;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.catCarYearRange,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.catYearFrom,
                    hintText: '2015',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('–', style: TextStyle(fontSize: 18)),
              ),
              Expanded(
                child: TextField(
                  controller: _maxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: s.catYearTo,
                    hintText: '2024',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(null, null);
                    Navigator.pop(context);
                  },
                  child: Text(s.catReset),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final min = int.tryParse(_minCtrl.text.trim());
                    final max = int.tryParse(_maxCtrl.text.trim());
                    widget.onApply(min, max);
                    Navigator.pop(context);
                  },
                  child: Text(s.catApply),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
