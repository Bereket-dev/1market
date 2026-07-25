part of '../supabase_repository.dart';

// ── Reviews ──────────────────────────────────────────────────────────

extension SupabaseRepositoryReviews on SupabaseRepository {
  // ── Service reviews ─────────────────────────────────────────────────────────

  /// Fetches all reviews for [serviceId], enriched with reviewer name/avatar
  /// via a join on profiles.
  Future<List<ServiceReview>> fetchReviewsForService(String serviceId) async {
    final rows = await _client
        .from('service_reviews')
        .select('*, profiles(display_name, avatar_url)')
        .eq('service_id', serviceId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) {
      final r = row as Map<String, dynamic>;
      final profile = r['profiles'] as Map<String, dynamic>?;
      return ServiceReview(
        id: r['id'] as String,
        serviceId: r['service_id'] as String,
        reviewerId: r['reviewer_id'] as String,
        rating: (r['rating'] as num?)?.toInt() ?? 3,
        comment: r['comment'] as String? ?? '',
        createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ??
            DateTime.now(),
        reviewerName: profile?['display_name'] as String?,
        reviewerAvatarUrl: profile?['avatar_url'] as String?,
      );
    }).toList();
  }

  /// Inserts or updates a review for [serviceId] by the current user.
  /// TODO (Phase C Part 2): Gate this on a completed HiringApplication.
  Future<ServiceReview> submitReview({
    required String serviceId,
    required int rating,
    required String comment,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    // Upsert on the unique (service_id, reviewer_id) constraint.
    // onConflict is required by PostgREST v2 for non-PK upserts.
    await _client
        .from('service_reviews')
        .upsert(
          {
            'service_id': serviceId,
            'reviewer_id': userId,
            'rating': rating,
            'comment': comment,
          },
          onConflict: 'service_id,reviewer_id',
        );

    // Re-fetch with profile join so the caller gets the reviewer name + avatar
    // immediately — without waiting for a separate loadReviewsForService call.
    final row = await _client
        .from('service_reviews')
        .select('*, profiles(display_name, avatar_url)')
        .eq('service_id', serviceId)
        .eq('reviewer_id', userId)
        .single();

    final profile = row['profiles'] as Map<String, dynamic>?;
    return ServiceReview(
      id: row['id'] as String,
      serviceId: row['service_id'] as String,
      reviewerId: row['reviewer_id'] as String,
      rating: (row['rating'] as num?)?.toInt() ?? rating,
      comment: row['comment'] as String? ?? comment,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
              DateTime.now(),
      reviewerName: profile?['display_name'] as String?,
      reviewerAvatarUrl: profile?['avatar_url'] as String?,
    );
  }

}
