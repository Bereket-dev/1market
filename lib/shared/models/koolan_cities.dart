/// Launch cities for Koolan across East Ethiopia.
///
/// Listings store a free-text `location` like `"Kebele 03, Dire Dawa"`.
/// The city portion must match these names so regional sync filters
/// (`ilike '%City%'`) and browse chips stay consistent.
class KoolanCities {
  KoolanCities._();

  /// First launch market — prefer this when profile city is unset.
  static const String launchDefault = 'Dire Dawa';

  /// Curated East Ethiopia cities (order = picker order).
  static const List<String> all = [
    'Dire Dawa',
    'Harar',
    'Jigjiga',
    'Chiro',
    'Degahbur',
    'Gode',
    'Kebri Dahar',
  ];

  /// Nearby cities used after the user's own city during regional sync.
  static const List<String> nearby = [
    'Dire Dawa',
    'Harar',
    'Jigjiga',
    'Chiro',
  ];

  /// Broader East Ethiopia majors fetched after nearby.
  static const List<String> extended = [
    'Degahbur',
    'Gode',
    'Kebri Dahar',
    'Addis Ababa',
  ];

  /// Profile / wizard city: known profile city if in [all], else launch default.
  static String resolve(String? profileCity) {
    final trimmed = profileCity?.trim() ?? '';
    if (trimmed.isEmpty) return launchDefault;
    for (final city in all) {
      if (city.toLowerCase() == trimmed.toLowerCase()) return city;
    }
    // Custom city from older free-text profiles — keep as-is.
    return trimmed;
  }
}
