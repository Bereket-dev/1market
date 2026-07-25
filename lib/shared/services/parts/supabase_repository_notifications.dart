part of '../supabase_repository.dart';

// ── Notifications ──────────────────────────────────────────────────────────

extension SupabaseRepositoryNotifications on SupabaseRepository {
  // ── In-app notifications ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final userId = currentUserId;
    if (userId == null) return [];
    final rows = await _client
        .from('app_notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> insertNotification({
    required String recipientUserId,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    await _client.from('app_notifications').insert({
      'user_id': recipientUserId,
      'type': type,
      'title': title,
      'body': body,
      'payload': payload,
    });
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from('app_notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // ── Public Profile ───────────────────────────────────────────────────────────

  /// Fetches the public profile of any user by [userId].
  /// Returns null if not found.
  Future<UserProfile?> fetchPublicProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  /// Fetches all service reviews received by [userId] (i.e. reviews on any
  /// service owned by [userId]), enriched with reviewer name/avatar.
  Future<List<ServiceReview>> fetchReviewsForUser(String userId) async {
    // Step 1: get the service IDs owned by this user.
    final serviceRows = await _client
        .from('services')
        .select('id')
        .eq('owner_id', userId);

    final serviceIds = (serviceRows as List)
        .map((r) => r['id'] as String)
        .toList();

    if (serviceIds.isEmpty) return [];

    // Step 2: fetch all reviews for those services in a single query.
    final rows = await _client
        .from('service_reviews')
        .select('*, profiles(display_name, avatar_url)')
        .inFilter('service_id', serviceIds)
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
        createdAt:
            DateTime.tryParse(r['created_at'] as String? ?? '') ??
                DateTime.now(),
        reviewerName: profile?['display_name'] as String?,
        reviewerAvatarUrl: profile?['avatar_url'] as String?,
      );
    }).toList();
  }
}
