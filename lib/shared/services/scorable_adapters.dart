/// Adapters that make [Listing], [Service], and [HiringPost] conform to
/// [Scorable] without modifying those models.
library;

import '../models/hiring_post.dart';
import '../models/listing.dart';
import '../models/service.dart';
import 'recommendation_engine.dart';

// ── Listing adapter ───────────────────────────────────────────────────────────

class ScorableListing implements Scorable {
  final Listing listing;
  const ScorableListing(this.listing);

  @override
  String get id => listing.id;

  @override
  String get category => listing.category;

  @override
  String get location => listing.location;

  @override
  // Listings have seller rating — use it directly.
  double get ratingValue => listing.sellerRating;

  @override
  DateTime get createdAt => listing.localUpdatedAt;
}

// ── Service adapter ───────────────────────────────────────────────────────────

class ScorableService implements Scorable {
  final Service service;

  /// Average rating computed from reviews. Pass 0.0 when no reviews exist —
  /// the engine will substitute [kNeutralRating] so unreviewed services
  /// aren't buried.
  final double reviewRating;

  const ScorableService(this.service, {this.reviewRating = 0.0});

  @override
  String get id => service.id;

  @override
  // Services use their declared category, which maps to listing categories.
  String get category => service.category;

  @override
  String get location => service.location;

  @override
  double get ratingValue => reviewRating;

  @override
  DateTime get createdAt => service.createdAt;
}

// ── HiringPost adapter ────────────────────────────────────────────────────────

class ScorableHiringPost implements Scorable {
  final HiringPost post;
  const ScorableHiringPost(this.post);

  @override
  String get id => post.id;

  @override
  String get category => post.category;

  @override
  String get location => post.location;

  @override
  // Hiring posts don't carry a rating — neutral default.
  double get ratingValue => 0.0;

  @override
  DateTime get createdAt => post.createdAt;
}
