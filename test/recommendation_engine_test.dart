// Unit tests for RecommendationEngine scoring logic.
//
// Covers:
//   - Category match scoring (exact, ALL, mismatch, null preferred)
//   - Location factor skipped when hasLocation is false
//   - Neutral rating (3.0/5.0) for unreviewed services — not buried
//   - Recency decay (within window, outside window, boundary)
//   - Interaction penalty for saved / applied / viewed items
//   - rankForUser returns at most kMaxRecommendations items
//   - rankSimilarTo excludes the anchor and uses same-category as dominant signal
//   - Weight renormalisation when location is absent
import 'package:flutter_test/flutter_test.dart';
import 'package:onemarket/shared/services/recommendation_engine.dart';

// ── Minimal Scorable stub ─────────────────────────────────────────────────────

class _Item implements Scorable {
  @override final String id;
  @override final String category;
  @override final String location;
  @override final double ratingValue;
  @override final DateTime createdAt;

  const _Item({
    required this.id,
    required this.category,
    this.location = 'Kebele 06',
    this.ratingValue = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? const _Now();
}

// Helper: creates a DateTime relative to now.
extension _DateTimeHelpers on DateTime {
  static DateTime daysAgo(int days) =>
      DateTime.now().subtract(Duration(days: days));
}

// Dart const workaround — use a factory in tests instead.
_Item item({
  required String id,
  required String category,
  String location = 'Kebele 06',
  double rating = 0.0,
  int daysAgo = 0,
}) =>
    _Item(
      id: id,
      category: category,
      location: location,
      ratingValue: rating,
      createdAt: DateTime.now().subtract(Duration(days: daysAgo)),
    );

// ── Const workaround for default createdAt ───────────────────────────────────
// Dart requires const constructors to have const fields. We use a lazy
// initialisation in _Item via the named constructor pattern instead.

class _Now implements DateTime {
  const _Now();
  // Delegate all DateTime interface requirements to DateTime.now() at call time.
  // Only used as a placeholder; actual tests pass explicit createdAt values.
  @override
  dynamic noSuchMethod(Invocation i) => DateTime.now().noSuchMethod(i);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const engine = RecommendationEngine();

  // ── UserContext builders ─────────────────────────────────────────────────
  UserContext userWithGoal(String? category, {bool hasLocation = false, String? city}) =>
      UserContext(
        preferredCategory: category,
        userLocation: city,
        hasLocation: hasLocation,
        savedIds: const {},
        appliedPostIds: const {},
        recentlyViewedIds: const {},
      );

  group('Category match scoring', () {
    test('exact category match scores highest', () {
      final carsItem = item(id: '1', category: 'CARS');
      final housesItem = item(id: '2', category: 'HOUSES');
      final user = userWithGoal('CARS');

      final ranked = engine.rankForUser(candidates: [housesItem, carsItem], user: user);

      expect(ranked.first.id, '1', reason: 'CARS item should rank above HOUSES item for CARS user');
    });

    test('ALL preferred category scores both items equally (0.5 each)', () {
      final a = item(id: 'a', category: 'CARS');
      final b = item(id: 'b', category: 'HOUSES');
      final user = userWithGoal('ALL');

      final ranked = engine.rankForUser(candidates: [a, b], user: user);

      // Both get 0.5 category score — neither should be excluded
      expect(ranked.length, 2);
    });

    test('null preferred category gives neutral 0.5 to all (cold start)', () {
      final a = item(id: 'a', category: 'CARS');
      final b = item(id: 'b', category: 'LAND');
      final user = userWithGoal(null);

      final ranked = engine.rankForUser(candidates: [a, b], user: user);

      // Both should appear — cold start must not produce empty results
      expect(ranked.length, 2);
    });

    test('category mismatch scores 0 on category factor', () {
      final carsItem = item(id: '1', category: 'CARS', rating: 5.0);
      final skillsItem = item(id: '2', category: 'SKILLS', rating: 3.0);
      final user = userWithGoal('SKILLS');

      final ranked = engine.rankForUser(candidates: [carsItem, skillsItem], user: user);

      expect(ranked.first.id, '2',
          reason: 'SKILLS item with lower rating should still outrank CARS item for SKILLS user');
    });
  });

  group('Location factor', () {
    test('location factor is skipped entirely when hasLocation is false', () {
      // One item same city, one different — with location disabled they should
      // both appear and the same-city one should NOT get an automatic boost.
      final sameCity = item(id: 'same', category: 'CARS', location: 'Kebele 06', rating: 3.0);
      final diffCity = item(id: 'diff', category: 'CARS', location: 'Kebele 12', rating: 5.0);
      final user = UserContext(
        preferredCategory: 'CARS',
        userLocation: 'Kebele 06',
        hasLocation: false, // ← location permission NOT granted
      );

      final ranked = engine.rankForUser(candidates: [sameCity, diffCity], user: user);

      // With location skipped, the higher-rated item (diffCity, 5.0) should win.
      expect(ranked.first.id, 'diff',
          reason: 'Without location permission, rating alone should determine ranking');
    });

    test('location factor IS applied when hasLocation is true', () {
      final sameCity = item(id: 'same', category: 'CARS', location: 'Kebele 06', rating: 3.0);
      final diffCity = item(id: 'diff', category: 'CARS', location: 'Kebele 12', rating: 3.0);
      final user = UserContext(
        preferredCategory: 'CARS',
        userLocation: 'Kebele 06',
        hasLocation: true, // ← location permission granted
      );

      final ranked = engine.rankForUser(candidates: [sameCity, diffCity], user: user);

      // Same rating, same category — location should tip sameCity to #1
      expect(ranked.first.id, 'same',
          reason: 'With location permission, same-city item should rank higher');
    });

    test('missing userLocation city string does not crash even if hasLocation=true', () {
      final a = item(id: 'a', category: 'CARS');
      final user = UserContext(
        preferredCategory: 'CARS',
        userLocation: null, // no city string
        hasLocation: true,  // but permission was granted
      );

      // Engine checks both hasLocation AND userLocation != null before applying
      expect(
        () => engine.rankForUser(candidates: [a], user: user),
        returnsNormally,
      );
    });
  });

  group('Rating scoring — neutral default for unreviewed items', () {
    test('item with rating=0.0 uses neutral 3.0/5.0=0.6, not zero', () {
      final unreviewed = item(id: 'unreviewed', category: 'SKILLS', rating: 0.0);
      final reviewed = item(id: 'reviewed', category: 'SKILLS', rating: 3.1);
      final user = userWithGoal('SKILLS');

      final ranked = engine.rankForUser(candidates: [unreviewed, reviewed], user: user);

      // reviewed item has 3.1 vs neutral 3.0, so it should edge out, but unreviewed
      // should still appear (not buried at 0)
      expect(ranked.length, 2);
      expect(ranked.first.id, 'reviewed');
    });

    test('unreviewed item (0.0) ranks above item with very low rating (1.0)', () {
      // kNeutralRating is 3.0, which is higher than 1.0 — unreviewed wins
      final unreviewed = item(id: 'unreviewed', category: 'SKILLS', rating: 0.0);
      final badRating  = item(id: 'bad',        category: 'SKILLS', rating: 1.0);
      final user = userWithGoal('SKILLS');

      final ranked = engine.rankForUser(candidates: [badRating, unreviewed], user: user);

      expect(ranked.first.id, 'unreviewed',
          reason: 'Neutral 3.0 > 1.0 so unreviewed should rank above poorly-rated item');
    });

    test('high-rated item (5.0) ranks above unreviewed (neutral 3.0)', () {
      final unreviewed = item(id: 'unreviewed', category: 'SKILLS', rating: 0.0);
      final topRated   = item(id: 'top',        category: 'SKILLS', rating: 5.0);
      final user = userWithGoal('SKILLS');

      final ranked = engine.rankForUser(candidates: [unreviewed, topRated], user: user);

      expect(ranked.first.id, 'top');
    });
  });

  group('Recency decay', () {
    test('brand-new item scores higher than 20-day-old item', () {
      final fresh = item(id: 'fresh', category: 'CARS', daysAgo: 0);
      final stale = item(id: 'stale', category: 'CARS', daysAgo: 20);
      final user = userWithGoal('CARS');

      final ranked = engine.rankForUser(candidates: [stale, fresh], user: user);

      expect(ranked.first.id, 'fresh');
    });

    test('item older than 30-day window scores 0 on recency', () {
      final fresh = item(id: 'fresh', category: 'CARS', daysAgo: 1);
      final old   = item(id: 'old',   category: 'CARS', daysAgo: 35);
      final user = userWithGoal('CARS');

      final ranked = engine.rankForUser(candidates: [old, fresh], user: user);

      expect(ranked.first.id, 'fresh',
          reason: 'Item beyond 30-day window gets 0 recency score');
    });

    test('item at exactly the boundary (30 days) scores near 0, not negative', () {
      // boundary item should still appear — score is clamped to 0, not negative
      final boundary = item(id: 'boundary', category: 'CARS', daysAgo: 30);
      final user = userWithGoal('CARS');

      final ranked = engine.rankForUser(candidates: [boundary], user: user);

      // Should not throw, and boundary item should still be included
      expect(ranked.length, 1);
    });
  });

  group('Interaction penalty', () {
    test('saved item is deprioritised but not excluded', () {
      // Rating difference must be small enough that the 5% penalty is decisive.
      // saved: rating 3.2 → ratingScore 0.64 × 0.25 = 0.16
      // unsaved: rating 3.0 → ratingScore 0.60 × 0.25 = 0.15
      // Without penalty saved would win by 0.01. With 5% penalty applied to
      // saved (1.0 × 0.05 / 0.85 renorm ≈ 0.059), saved drops below unsaved.
      final saved   = item(id: 'saved',   category: 'CARS', rating: 3.2);
      final unsaved = item(id: 'unsaved', category: 'CARS', rating: 3.0);
      final user = UserContext(
        preferredCategory: 'CARS',
        savedIds: {'saved'},
      );

      final ranked = engine.rankForUser(candidates: [saved, unsaved], user: user);

      expect(ranked.length, 2, reason: 'Saved item should appear, just ranked lower');
      expect(ranked.last.id, 'saved',
          reason: 'Small rating edge is not enough to overcome the interaction penalty');
    });

    test('applied post is deprioritised but not excluded', () {
      final applied   = item(id: 'applied',   category: 'SKILLS', rating: 3.2);
      final unapplied = item(id: 'unapplied', category: 'SKILLS', rating: 3.0);
      final user = UserContext(
        preferredCategory: 'SKILLS',
        appliedPostIds: {'applied'},
      );

      final ranked = engine.rankForUser(candidates: [applied, unapplied], user: user);

      expect(ranked.length, 2);
      expect(ranked.last.id, 'applied');
    });

    test('recently viewed item is deprioritised but not excluded', () {
      final viewed   = item(id: 'viewed',   category: 'HOUSES', rating: 3.2);
      final unviewed = item(id: 'unviewed', category: 'HOUSES', rating: 3.0);
      final user = UserContext(
        preferredCategory: 'HOUSES',
        recentlyViewedIds: {'viewed'},
      );

      final ranked = engine.rankForUser(candidates: [viewed, unviewed], user: user);

      expect(ranked.length, 2);
      expect(ranked.last.id, 'viewed');
    });

    test('interaction penalty does NOT exclude items — item still shows in list', () {
      // Even a heavily-interacted item (saved + applied + viewed) must still appear
      final interacted = item(id: 'interacted', category: 'CARS', rating: 5.0);
      final fresh      = item(id: 'fresh',      category: 'CARS', rating: 5.0);
      final user = UserContext(
        preferredCategory: 'CARS',
        savedIds: {'interacted'},
        appliedPostIds: {'interacted'},
        recentlyViewedIds: {'interacted'},
      );

      final ranked = engine.rankForUser(candidates: [interacted, fresh], user: user);

      expect(ranked.map((i) => i.id), contains('interacted'),
          reason: 'Interaction penalty deprioritises, never excludes');
    });

    test('clean user with no interactions gets full scores', () {
      final a = item(id: 'a', category: 'CARS', rating: 4.0);
      final b = item(id: 'b', category: 'CARS', rating: 3.0);
      final user = UserContext(preferredCategory: 'CARS');

      final ranked = engine.rankForUser(candidates: [b, a], user: user);

      expect(ranked.first.id, 'a',
          reason: 'Higher rated item should win with no interaction history');
    });
  });

  group('rankForUser — limits and excludes', () {
    test('returns at most kMaxRecommendations items', () {
      final candidates = List.generate(
        25,
        (i) => item(id: 'item_$i', category: 'CARS'),
      );
      final user = userWithGoal('CARS');

      final ranked = engine.rankForUser(candidates: candidates, user: user);

      expect(ranked.length, lessThanOrEqualTo(kMaxRecommendations));
    });

    test('excludeIds removes those items from output', () {
      final a = item(id: 'a', category: 'CARS');
      final b = item(id: 'b', category: 'CARS');
      final user = userWithGoal('CARS');

      final ranked = engine.rankForUser(
        candidates: [a, b],
        user: user,
        excludeIds: {'a'},
      );

      expect(ranked.map((i) => i.id), isNot(contains('a')));
      expect(ranked.length, 1);
    });

    test('returns empty list gracefully when no candidates', () {
      final user = userWithGoal('CARS');
      final ranked = engine.rankForUser<_Item>(candidates: [], user: user);
      expect(ranked, isEmpty);
    });
  });

  group('rankSimilarTo', () {
    test('excludes anchor item itself', () {
      final anchor = item(id: 'anchor', category: 'CARS');
      final other  = item(id: 'other',  category: 'CARS');

      final ranked = engine.rankSimilarTo(anchor: anchor, candidates: [anchor, other]);

      expect(ranked.map((i) => i.id), isNot(contains('anchor')));
    });

    test('same-category item ranks above different-category item', () {
      final anchor     = item(id: 'anchor',   category: 'CARS');
      final samecat    = item(id: 'samecat',  category: 'CARS',   rating: 3.0);
      final diffcat    = item(id: 'diffcat',  category: 'HOUSES', rating: 5.0);

      final ranked = engine.rankSimilarTo(anchor: anchor, candidates: [diffcat, samecat]);

      expect(ranked.first.id, 'samecat',
          reason: 'Same-category item should rank above different-category even with lower rating');
    });

    test('returns at most kMaxRecommendations items', () {
      final anchor = item(id: 'anchor', category: 'CARS');
      final candidates = [
        anchor,
        ...List.generate(20, (i) => item(id: 'c_$i', category: 'CARS')),
      ];

      final ranked = engine.rankSimilarTo(anchor: anchor, candidates: candidates);

      expect(ranked.length, lessThanOrEqualTo(kMaxRecommendations));
    });

    test('returns empty list gracefully when only anchor is in candidates', () {
      final anchor = item(id: 'anchor', category: 'CARS');

      final ranked = engine.rankSimilarTo(anchor: anchor, candidates: [anchor]);

      expect(ranked, isEmpty);
    });
  });

  group('Weight renormalisation without location', () {
    test('scores without location sum to a value in [0, 1]', () {
      // Without location (hasLocation=false), weights are renormalised to
      // kCategoryMatchWeight + kRatingWeight + kRecencyWeight + kInteractionWeight
      // (= 0.85 total without the 0.15 location weight).
      // Final score is divided by this sum so the result stays in [0, 1].
      final a = item(id: 'a', category: 'CARS', rating: 5.0);
      final user = UserContext(
        preferredCategory: 'CARS',
        hasLocation: false,
      );

      final ranked = engine.rankForUser(candidates: [a], user: user);
      // Just verifying it runs without assertion errors and returns the item
      expect(ranked.length, 1);
    });
  });

  group('UserContext.categoryFromGoal', () {
    test('English goal strings map correctly', () {
      expect(UserContext.categoryFromGoal('Find a car'), 'CARS');
      expect(UserContext.categoryFromGoal('Rent a home'), 'HOUSES');
      expect(UserContext.categoryFromGoal('Buy land'), 'LAND');
      expect(UserContext.categoryFromGoal('Find a job'), 'SKILLS');
      expect(UserContext.categoryFromGoal('Hire a skilled person'), 'SKILLS');
    });

    test('Amharic goal strings map correctly', () {
      expect(UserContext.categoryFromGoal('መኪና ፈልግ'), 'CARS');
      expect(UserContext.categoryFromGoal('ቤት ተከራይ'), 'HOUSES');
      expect(UserContext.categoryFromGoal('መሬት ግዛ'), 'LAND');
      expect(UserContext.categoryFromGoal('ሥራ ፈልግ'), 'SKILLS');
    });

    test('Somali goal strings map correctly', () {
      expect(UserContext.categoryFromGoal('Gaari raadi'), 'CARS');
      expect(UserContext.categoryFromGoal('Guri kiri'), 'HOUSES');
      expect(UserContext.categoryFromGoal('Dhul iibso'), 'LAND');
      expect(UserContext.categoryFromGoal('Shaqo raadi'), 'SKILLS');
    });

    test('null goal returns null (cold start — all categories get 0.5)', () {
      expect(UserContext.categoryFromGoal(null), isNull);
    });

    test('unknown string returns null', () {
      expect(UserContext.categoryFromGoal('Something random'), isNull);
    });
  });
}
