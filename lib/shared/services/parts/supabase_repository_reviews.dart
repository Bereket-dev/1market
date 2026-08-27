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

    return SafeParse.mapList(
      rows as List,
      (r) {
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
      },
      context: 'reviews_for_service',
    );
  }

  /// Inserts or updates a review for [serviceId] by the current user.
  ///
  /// Requires an accepted hiring application for this service where the
  /// current user is the hiring-post owner (the hirer).
  Future<ServiceReview> submitReview({
    required String serviceId,
    required int rating,
    required String comment,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    final allowed = await canReviewService(serviceId);
    if (!allowed) {
      throw StateError('Review requires an accepted hiring engagement');
    }

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

  /// True when the current user hired [serviceId] (accepted application
  /// on a hiring post they own) and does not own the service themselves.
  Future<bool> canReviewService(String serviceId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    // Owners cannot review their own service.
    final owned = await _client
        .from('services')
        .select('id')
        .eq('id', serviceId)
        .eq('owner_id', userId)
        .maybeSingle();
    if (owned != null) return false;

    // Hirer must have accepted an application for this service.
    final rows = await _client
        .from('applications')
        .select('id, hiring_posts!inner(poster_id)')
        .eq('service_id', serviceId)
        .eq('status', 'accepted')
        .eq('hiring_posts.poster_id', userId)
        .limit(1);

    return (rows as List).isNotEmpty;
  }

}
