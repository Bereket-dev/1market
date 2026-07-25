// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Reviews & public profiles ─────────────────────────────────────────────────

extension AppStateReviews on KoolanAppState {
  List<ServiceReview> getReviewsForService(String serviceId) =>
      _reviewsCache[serviceId] ?? [];

  Future<List<ServiceReview>> loadReviewsForService(String serviceId) async {
    if (_repo == null) return [];
    try {
      final reviews = await _repo!.fetchReviewsForService(serviceId);
      _reviewsCache[serviceId] = reviews;
      notifyListeners();
      return reviews;
    } catch (e) {
      debugPrint('loadReviewsForService error: $e');
      return _reviewsCache[serviceId] ?? [];
    }
  }

  /// Submits a review for [serviceId].
  Future<void> submitReview({
    required String serviceId,
    required int rating,
    required String comment,
  }) async {
    if (_repo == null) {
      dataError = 'Supabase unavailable';
      notifyListeners();
      return;
    }
    try {
      final review = await _repo!.submitReview(
        serviceId: serviceId,
        rating: rating,
        comment: comment,
      );
      final existing = List<ServiceReview>.from(
        _reviewsCache[serviceId] ?? [],
      );
      final idx = existing.indexWhere((r) => r.reviewerId == review.reviewerId);
      if (idx >= 0) {
        existing[idx] = review;
      } else {
        existing.insert(0, review);
      }
      _reviewsCache[serviceId] = existing;
      notifyListeners();
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Public Profile ────────────────────────────────────────────────────────────

  UserProfile? getCachedPublicProfile(String userId) =>
      _publicProfileCache[userId];

  List<ServiceReview> getReviewsForUser(String userId) =>
      _userReviewsCache[userId] ?? [];

  Future<UserProfile?> loadPublicProfile(String userId) async {
    if (_repo == null) return _publicProfileCache[userId];
    try {
      final p = await _repo!.fetchPublicProfile(userId);
      if (p != null) _publicProfileCache[userId] = p;
      notifyListeners();
      return p;
    } catch (e) {
      debugPrint('loadPublicProfile error: $e');
      return _publicProfileCache[userId];
    }
  }

  Future<List<ServiceReview>> loadReviewsForUser(String userId) async {
    if (_repo == null) return _userReviewsCache[userId] ?? [];
    try {
      final reviews = await _repo!.fetchReviewsForUser(userId);
      _userReviewsCache[userId] = reviews;
      notifyListeners();
      return reviews;
    } catch (e) {
      debugPrint('loadReviewsForUser error: $e');
      return _userReviewsCache[userId] ?? [];
    }
  }
}
