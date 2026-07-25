part of '../category_list_screen.dart';

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
