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
    return SafeParse.mapList(
      rows as List,
      (row) => Map<String, dynamic>.from(row as Map),
      context: 'notifications',
    );
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
    return SafeParse.tryMap(
      Map<String, dynamic>.from(data),
      UserProfile.fromJson,
      context: 'public_profile',
    );
  }

  /// Fetches all service reviews received by [userId] in a single join query.
  Future<List<ServiceReview>> fetchReviewsForUser(String userId) async {
    final rows = await _client
        .from('service_reviews')
        .select('*, profiles(display_name, avatar_url), services!inner(owner_id)')
        .eq('services.owner_id', userId)
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
          createdAt:
              DateTime.tryParse(r['created_at'] as String? ?? '') ??
                  DateTime.now(),
          reviewerName: profile?['display_name'] as String?,
          reviewerAvatarUrl: profile?['avatar_url'] as String?,
        );
      },
      context: 'reviews_for_user',
    );
  }
}
