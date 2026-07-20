// ── Weights ────────────────────────────────────────────────────────────────────

/// Fraction of total score from category match.
const double kCategoryMatchWeight = 0.40;

/// Fraction of total score from rating / review quality.
const double kRatingWeight = 0.25;

/// Fraction of total score from recency of the listing/post/service.
const double kRecencyWeight = 0.15;

/// Fraction of total score from location proximity.
/// Only applied when [UserContext.hasLocation] is true; otherwise
/// the remaining weights are renormalised to fill the gap.
const double kLocationWeight = 0.15;

/// Small penalty for items the user has already saved, applied, or recently
/// viewed — enough to push them down the list, not exclude them.
const double kInteractionWeight = 0.05;

/// Rating to use when an item has no reviews yet.
/// Set at neutral (3.0 / 5.0 = 0.6) so unreviewed items aren't buried.
const double kNeutralRating = 3.0;

/// Max rating scale used for normalisation.
const double kMaxRating = 5.0;

/// Items older than this are scored 0.0 on the recency factor.
const Duration kRecencyWindow = Duration(days: 30);

/// Maximum number of recommendations returned from any single call.
const int kMaxRecommendations = 10;

// ── Goal → category mappings ──────────────────────────────────────────────────

/// Maps onboarding goal strings to the listing category they imply.
/// Handles all three locales (en/am/so) plus direct category codes.
const Map<String, String> kGoalToCategoryCode = {
  // English
  'Post a listing': 'ALL',
  'Hire a skilled person': 'SKILLS',
  'Find a job': 'SKILLS',
  'Find a car': 'CARS',
  'Rent a home': 'HOUSES',
  'Buy land': 'LAND',
  // Amharic
  'ማስታወቂያ ለጥፍ': 'ALL',
  'ብቃት ያለው ቅጠር': 'SKILLS',
  'ሥራ ፈልግ': 'SKILLS',
  'መኪና ፈልግ': 'CARS',
  'ቤት ተከራይ': 'HOUSES',
  'መሬት ግዛ': 'LAND',
  // Somali
  'Ku daji xayaysiis': 'ALL',
  'Shaqaale xirfadleh kiri': 'SKILLS',
  'Shaqo raadi': 'SKILLS',
  'Gaari raadi': 'CARS',
  'Guri kiri': 'HOUSES',
  'Dhul iibso': 'LAND',
  // Direct category codes (from profile.preferredCategory)
  'CARS': 'CARS',
  'HOUSES': 'HOUSES',
  'LAND': 'LAND',
  'SKILLS': 'SKILLS',
  'ALL': 'ALL',
};

// ── User context ──────────────────────────────────────────────────────────────

/// Snapshot of the current user's signals used by the engine.
/// Passed in at call-time — the engine is stateless.
class UserContext {
  /// Category code the user prefers (from onboarding goal or browsing).
  /// One of: CARS, HOUSES, LAND, SKILLS, ALL, or null (cold start).
  final String? preferredCategory;

  /// City / district string from the user's profile (e.g. "Kebele 06").
  /// Used for soft location matching when GPS lat/lng is unavailable.
  final String? userLocation;

  /// Whether the user granted location permission.
  /// When false, the location factor is skipped entirely.
  final bool hasLocation;

  /// IDs of listings/services/posts the user has already saved.
  final Set<String> savedIds;

  /// IDs of hiring posts the user has already applied to.
  final Set<String> appliedPostIds;

  /// IDs of items the user has recently viewed (in-memory only).
  final Set<String> recentlyViewedIds;

  const UserContext({
    this.preferredCategory,
    this.userLocation,
    this.hasLocation = false,
    this.savedIds = const {},
    this.appliedPostIds = const {},
    this.recentlyViewedIds = const {},
  });

  /// Derives the preferred category code from an onboarding goal string
  /// (which may be in any of the three supported locales).
  static String? categoryFromGoal(String? goal) {
    if (goal == null) return null;
    return kGoalToCategoryCode[goal];
  }
}

// ── Item wrappers ─────────────────────────────────────────────────────────────

/// Common interface used by the scorer — wraps Listing, Service, or HiringPost.
abstract class Scorable {
  String get id;
  String get category;
  String get location;
  double get ratingValue;   // 0.0 – 5.0
  DateTime get createdAt;
}

// ── Scoring engine ────────────────────────────────────────────────────────────

class RecommendationEngine {
  const RecommendationEngine();

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Scores and ranks [candidates] for a [user].
  ///
  /// Excludes the user's own items (pass [excludeIds] for those).
  /// Returns at most [kMaxRecommendations] items.
  List<T> rankForUser<T extends Scorable>({
    required List<T> candidates,
    required UserContext user,
    Set<String> excludeIds = const {},
  }) {
    final scored = <_Scored<T>>[];
    for (final item in candidates) {
      if (excludeIds.contains(item.id)) continue;
      final s = _scoreForUser(item, user);
      scored.add(_Scored(item, s));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored
        .take(kMaxRecommendations)
        .map((s) => s.item)
        .toList();
  }

  /// Scores and ranks [candidates] similar to [anchor].
  ///
  /// Used for "Similar to this" sections on detail screens.
  /// Excludes the anchor item itself from results.
  List<T> rankSimilarTo<T extends Scorable>({
    required T anchor,
    required List<T> candidates,
    Set<String> excludeIds = const {},
  }) {
    final scored = <_Scored<T>>[];
    for (final item in candidates) {
      if (item.id == anchor.id) continue;
      if (excludeIds.contains(item.id)) continue;
      final s = _scoreForSimilarity(item, anchor);
      scored.add(_Scored(item, s));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored
        .take(kMaxRecommendations)
        .map((s) => s.item)
        .toList();
  }

  // ── User-based scoring ──────────────────────────────────────────────────────

  double _scoreForUser(Scorable item, UserContext user) {
    // Renormalise weights when location is skipped.
    final useLocation = user.hasLocation && user.userLocation != null;
    final totalWeight = useLocation
        ? 1.0
        : (kCategoryMatchWeight + kRatingWeight + kRecencyWeight +
            kInteractionWeight);

    double score = 0.0;

    // 1. Category match
    final catScore = _categoryScore(item.category, user.preferredCategory);
    score += catScore * kCategoryMatchWeight;

    // 2. Rating
    final ratingScore = _ratingScore(item.ratingValue);
    score += ratingScore * kRatingWeight;

    // 3. Recency
    final recencyScore = _recencyScore(item.createdAt);
    score += recencyScore * kRecencyWeight;

    // 4. Location (skipped when no permission)
    if (useLocation) {
      final locScore = _locationScore(item.location, user.userLocation!);
      score += locScore * kLocationWeight;
    }

    // 5. Interaction penalty (already saved/applied/viewed → deprioritise)
    final penalty = _interactionPenalty(
      item.id,
      user.savedIds,
      user.appliedPostIds,
      user.recentlyViewedIds,
    );
    score -= penalty * kInteractionWeight;

    return score / totalWeight;
  }

  // ── Similarity-based scoring ────────────────────────────────────────────────

  double _scoreForSimilarity(Scorable item, Scorable anchor) {
    double score = 0.0;

    // Same category is still the dominant signal
    final catScore = item.category == anchor.category ? 1.0 : 0.0;
    score += catScore * kCategoryMatchWeight;

    // Rating quality of the candidate
    score += _ratingScore(item.ratingValue) * kRatingWeight;

    // Recency
    score += _recencyScore(item.createdAt) * kRecencyWeight;

    // Location: how similar to anchor's location
    score += _locationScore(item.location, anchor.location) * kLocationWeight;

    return score;
  }

  // ── Component scorers ───────────────────────────────────────────────────────

  /// Returns 1.0 for exact category match, 0.5 for ALL (universal), 0.0 otherwise.
  double _categoryScore(String itemCategory, String? preferred) {
    if (preferred == null || preferred == 'ALL') return 0.5;
    if (itemCategory == preferred) return 1.0;
    return 0.0;
  }

  /// Normalises [rating] to [0.0, 1.0]. Uses [kNeutralRating] for 0.0 input
  /// so items without reviews aren't penalised.
  double _ratingScore(double rating) {
    final effective = rating <= 0.0 ? kNeutralRating : rating;
    return (effective / kMaxRating).clamp(0.0, 1.0);
  }

  /// Scores recency linearly within [kRecencyWindow].
  /// Items newer than the window boundary score 1.0; older items score 0.0.
  double _recencyScore(DateTime createdAt) {
    final now = DateTime.now();
    final age = now.difference(createdAt);
    if (age.isNegative) return 1.0;
    if (age > kRecencyWindow) return 0.0;
    return 1.0 - (age.inSeconds / kRecencyWindow.inSeconds);
  }

  /// Soft location match: compares the first word (kebele / district) of the
  /// location strings. Full GPS matching is not available in Phase D since
  /// lat/lng coordinates are not stored.
  ///
  /// Returns 1.0 for matching first token, 0.0 otherwise.
  double _locationScore(String itemLocation, String referenceLocation) {
    final itemFirst = itemLocation.trim().split(RegExp(r'[\s,]+')).first.toLowerCase();
    final refFirst = referenceLocation.trim().split(RegExp(r'[\s,]+')).first.toLowerCase();
    if (itemFirst.isEmpty || refFirst.isEmpty) return 0.0;
    return itemFirst == refFirst ? 1.0 : 0.0;
  }

  /// Returns 1.0 when the item has been interacted with (saved/applied/viewed).
  double _interactionPenalty(
    String id,
    Set<String> saved,
    Set<String> applied,
    Set<String> viewed,
  ) {
    if (saved.contains(id) || applied.contains(id) || viewed.contains(id)) {
      return 1.0;
    }
    return 0.0;
  }
}

// ── Internal helpers ──────────────────────────────────────────────────────────

class _Scored<T> {
  final T item;
  final double score;
  const _Scored(this.item, this.score);
}
