part of '../supabase_repository.dart';

// ── Hiring ──────────────────────────────────────────────────────────

extension SupabaseRepositoryHiring on SupabaseRepository {

  // ── Applications ──────────────────────────────────────────────────────────────

  /// Inserts a new application and returns the Supabase-assigned id.
  Future<String> insertApplication(Map<String, dynamic> fields) async {
    final row = await _client
        .from('applications')
        .insert(fields)
        .select('id')
        .single();
    return row['id'] as String;
  }

  // ── Reports ─────────────────────────────────────────────────────────────────

  Future<void> submitReport({
    required String reason,
    String? listingId,
    String? serviceId,
    String? hiringPostId,
    String? reportedUserId,
    String? targetType,
    String? details,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    await _client.from('reports').insert({
      'reporter_id': userId,
      'listing_id': listingId,
      'service_id': serviceId,
      'hiring_post_id': hiringPostId,
      'reported_user_id': reportedUserId,
      'target_type': targetType,
      'reason': reason,
      'details': details,
    });
  }

  // ── Hiring posts ─────────────────────────────────────────────────────────────

  /// Fetches all hiring posts visible to the current user:
  /// open posts (public) + the user's own closed posts (per RLS).
  Future<List<HiringPost>> fetchHiringPosts({
    int limit = SupabaseRepository.kPageSize,
    int offset = 0,
  }) async {
    final rows = await _client
        .from('hiring_posts')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (rows as List)
        .map((r) => HiringPost.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Returns applicant count per hiring post id for the current user's posts.
  Future<Map<String, int>> fetchApplicantCounts(
    List<String> postIds,
  ) async {
    if (postIds.isEmpty) return {};
    final rows = await _client
        .from('applications')
        .select('hiring_post_id')
        .inFilter('hiring_post_id', postIds);
    final counts = <String, int>{};
    for (final r in rows as List) {
      final postId = (r as Map<String, dynamic>)['hiring_post_id'] as String;
      counts[postId] = (counts[postId] ?? 0) + 1;
    }
    return counts;
  }

  // ── Applications ─────────────────────────────────────────────────────────────

  /// Fetches all applications for a specific hiring post (poster's view).
  Future<List<Application>> fetchApplicationsForPost(
    String hiringPostId,
  ) async {
    final rows = await _client
        .from('applications')
        .select(
          '*, profiles(display_name, avatar_url), services(title), hiring_posts(title)',
        )
        .eq('hiring_post_id', hiringPostId)
        .order('submitted_at', ascending: false)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException(
            'fetchApplicationsForPost timed out',
          ),
        );
    return (rows as List)
        .map((r) => Application.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Fetches all applications submitted by the current user,
  /// enriched with service and post titles for the grouped view.
  Future<List<Application>> fetchMyApplications() async {
    final userId = currentUserId;
    if (userId == null) return [];
    final rows = await _client
        .from('applications')
        .select(
          '*, services(title), hiring_posts(title)',
        )
        .eq('applicant_id', userId)
        .order('submitted_at', ascending: false);
    return (rows as List)
        .map((r) => Application.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Checks whether the current user has already applied to [hiringPostId]
  /// with [serviceId]. Returns true if a duplicate exists.
  Future<bool> hasDuplicateApplication({
    required String hiringPostId,
    required String serviceId,
  }) async {
    final userId = currentUserId;
    if (userId == null) return false;
    final row = await _client
        .from('applications')
        .select('id')
        .eq('hiring_post_id', hiringPostId)
        .eq('applicant_id', userId)
        .eq('service_id', serviceId)
        .maybeSingle();
    return row != null;
  }

  /// Updates the status of an application (poster only — enforced by RLS).
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String newStatus,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('applications').update({
      'status': newStatus,
      'status_updated_at': now,
      'updated_at': now,
    }).eq('id', applicationId);
  }

}
