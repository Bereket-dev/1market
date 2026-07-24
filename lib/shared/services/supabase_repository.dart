import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/application.dart';
import '../models/chat.dart';
import '../models/hiring_post.dart';
import '../models/listing.dart';
import '../models/profile.dart';
import '../models/service.dart';
import '../models/service_review.dart';

class SupabaseRepository {
  SupabaseRepository(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // ── Profile ─────────────────────────────────────────────────────────────────

  Future<UserProfile?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> ensureProfile() async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    var profile = await fetchProfile(userId);
    if (profile != null) return profile;

    final user = _client.auth.currentUser!;
    final meta = user.userMetadata ?? {};
    final displayName = meta['full_name'] as String? ??
        meta['name'] as String? ??
        user.email?.split('@').first ??
        'User';
    // Seed phone from Supabase auth (populated when user signs up with
    // email+phone or phone OTP). Google Sign-In does not provide a phone.
    final phone = user.phone?.isNotEmpty == true
        ? user.phone
        : (meta['phone'] as String?)?.isNotEmpty == true
            ? meta['phone'] as String?
            : null;

    await _client.from('profiles').insert({
      'id': userId,
      'display_name': displayName,
      'avatar_url': meta['avatar_url'],
      'phone': phone,
    });

    profile = await fetchProfile(userId);
    return profile!;
  }

  Future<void> updateLanguage(String language) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');
    await _client.from('profiles').update({
      'language': language,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');
    await _client.from('profiles').update({
      ...fields,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // ── Listings ────────────────────────────────────────────────────────────────

  static const int kPageSize = 30;

  Future<List<Listing>> fetchListings({
    Set<String>? savedIds,
    int limit = kPageSize,
    int offset = 0,
  }) async {
    final rows = await _client
        .from('listings')
        .select('*, profiles!seller_id(display_name, avatar_url, phone, rating, reviews_count)')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final userId = currentUserId;
    final favorites = savedIds ??
        (userId != null ? await _fetchFavoriteIds(userId) : <String>{});

    return (rows as List)
        .map((row) => Listing.fromJson(
              row as Map<String, dynamic>,
              isSaved: favorites.contains(row['id'] as String),
              isOwnedByCurrentUser: row['seller_id'] == userId,
            ))
        .toList();
  }

  Future<List<Service>> fetchServices({
    int limit = kPageSize,
    int offset = 0,
  }) async {
    final rows = await _client
        .from('services')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (rows as List)
        .map((row) => Service.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> _fetchFavoriteIds(String userId) async {
    final rows = await _client
        .from('favorites')
        .select('listing_id')
        .eq('user_id', userId);
    return (rows as List)
        .map((r) => (r as Map<String, dynamic>)['listing_id'] as String)
        .toSet();
  }

  Future<Listing> createListing({
    required String category,
    required String title,
    required String price,
    required String imageUrl,
    required String location,
    required String conditionOrStatus,
    required String description,
    String? spec1Label,
    String? spec1Value,
    String? spec2Label,
    String? spec2Value,
    String? spec3Label,
    String? spec3Value,
    String? spec4Label,
    String? spec4Value,
    required String sellerName,
    required String sellerImage,
    String? sellerPhone,
    String originalLanguage = 'en',
    List<String> imageUrls = const [],
  }) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    final row = await _client
        .from('listings')
        .insert({
          'seller_id': userId,
          'category': category,
          'title': title,
          'price': price,
          'image_url': imageUrl,
          'location': location,
          'condition_or_status': conditionOrStatus,
          'description': description,
          'spec1_label': spec1Label,
          'spec1_value': spec1Value,
          'spec2_label': spec2Label,
          'spec2_value': spec2Value,
          'spec3_label': spec3Label,
          'spec3_value': spec3Value,
          'spec4_label': spec4Label,
          'spec4_value': spec4Value,
          'original_language': originalLanguage,
          'title_translations': <String, String>{},
          'description_translations': <String, String>{},
          'image_urls': imageUrls,
        })
        .select('*, profiles!seller_id(display_name, avatar_url, phone, rating, reviews_count)')
        .single();

    return Listing.fromJson(row, isOwnedByCurrentUser: true);
  }

  /// Updates an existing listing row. Only the provided fields are changed.
  Future<void> updateListing(
    String listingId,
    Map<String, dynamic> fields,
  ) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');
    await _client.from('listings').update({
      ...fields,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', listingId).eq('seller_id', userId);
  }

  Future<void> deleteListing(String listingId) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');
    await _client
        .from('listings')
        .delete()
        .eq('id', listingId)
        .eq('owner_id', userId);
  }

  Future<void> toggleFavorite(String listingId, bool currentlySaved) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    if (currentlySaved) {
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('listing_id', listingId);
    } else {
      await _client.from('favorites').insert({
        'user_id': userId,
        'listing_id': listingId,
      });
    }
  }

  // ── Chat ────────────────────────────────────────────────────────────────────

  Future<List<ChatSession>> fetchChatSessions() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final threads = await _client
        .from('chat_threads')
        .select('*, listings(title)')
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('created_at', ascending: false);

    final sessions = <ChatSession>[];
    for (final thread in threads as List) {
      final t = thread as Map<String, dynamic>;
      final threadId = t['id'] as String;
      final buyerId = t['buyer_id'] as String;
      final sellerId = t['seller_id'] as String;
      final partnerId = buyerId == userId ? sellerId : buyerId;

      final partner = await fetchProfile(partnerId);
      final listingData = t['listings'] as Map<String, dynamic>?;
      final listingTitle = listingData?['title'] as String? ?? '';

      final messages = await _client
          .from('chat_messages')
          .select()
          .eq('thread_id', threadId)
          .order('created_at', ascending: true);

      final chatMessages = (messages as List).map((m) {
        final msg = m as Map<String, dynamic>;
        return ChatMessage.fromJson(msg, currentUserId: userId);
      }).toList();

      final unreadCount = chatMessages
          .where((m) => !m.isMe)
          .length; // simplified unread count

      sessions.add(ChatSession(
        id: threadId,
        partnerName: partner?.displayName ?? 'User',
        partnerAvatar: partner?.avatarUrl ?? '',
        listingTitle: listingTitle,
        listingId: t['listing_id'] as String?,
        messages: chatMessages,
        unreadCount: unreadCount > 0 ? 1 : 0,
      ));
    }
    return sessions;
  }

  Future<String> getOrCreateThread({
    required String listingId,
    required String sellerId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    final existing = await _client
        .from('chat_threads')
        .select('id')
        .eq('listing_id', listingId)
        .eq('buyer_id', userId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final created = await _client
        .from('chat_threads')
        .insert({
          'listing_id': listingId,
          'buyer_id': userId,
          'seller_id': sellerId,
        })
        .select('id')
        .single();

    return created['id'] as String;
  }

  /// Gets or creates a direct chat thread between the poster and an applicant
  /// for a specific hiring application. Uses [applicationId] as a stable
  /// correlation key via the listing_id column (nullable FK) so each
  /// application gets its own thread.
  Future<String> getOrCreateApplicationThread({
    required String applicantId,
    required String posterId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    // Poster initiates: poster = seller_id, applicant = buyer_id.
    // We look up an existing thread between these two users with no listing.
    final existing = await _client
        .from('chat_threads')
        .select('id')
        .eq('buyer_id', applicantId)
        .eq('seller_id', posterId)
        .isFilter('listing_id', null)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final created = await _client
        .from('chat_threads')
        .insert({
          'buyer_id': applicantId,
          'seller_id': posterId,
          // listing_id intentionally null — this is a hiring chat
        })
        .select('id')
        .single();

    return created['id'] as String;
  }

  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    final row = await _client
        .from('chat_messages')
        .insert({
          'thread_id': threadId,
          'sender_id': userId,
          'text': text,
        })
        .select()
        .single();

    return ChatMessage.fromJson(row, currentUserId: userId);
  }

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

  // ── Services ─────────────────────────────────────────────────────────────────

  /// Inserts a new service row and returns the Supabase-assigned id.
  Future<String> insertService(Map<String, dynamic> fields) async {
    final row = await _client
        .from('services')
        .insert(fields)
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Updates an existing service row by id.
  Future<void> updateService(String serviceId, Map<String, dynamic> fields) async {
    await _client.from('services').update({
      ...fields,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', serviceId);
  }

  /// Hard-deletes a service row. No-op if the row no longer exists.
  Future<void> deleteService(String serviceId) async {
    await _client.from('services').delete().eq('id', serviceId);
  }

  // ── Hiring posts ──────────────────────────────────────────────────────────────

  /// Inserts a new hiring post and returns the Supabase-assigned id.
  Future<String> insertHiringPost(Map<String, dynamic> fields) async {
    final row = await _client
        .from('hiring_posts')
        .insert(fields)
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Updates an existing hiring post row by id.
  Future<void> updateHiringPost(String postId, Map<String, dynamic> fields) async {
    await _client.from('hiring_posts').update({
      ...fields,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', postId);
  }

  /// Hard-deletes a hiring post row.
  Future<void> deleteHiringPost(String postId) async {
    await _client.from('hiring_posts').delete().eq('id', postId);
  }

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
    String? reportedUserId,
    String? details,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    await _client.from('reports').insert({
      'reporter_id': userId,
      'listing_id': listingId,
      'reported_user_id': reportedUserId,
      'reason': reason,
      'details': details,
    });
  }

  // ── Hiring posts ─────────────────────────────────────────────────────────────

  /// Fetches all hiring posts visible to the current user:
  /// open posts (public) + the user's own closed posts (per RLS).
  Future<List<HiringPost>> fetchHiringPosts({
    int limit = kPageSize,
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
    // Join service_reviews → services to filter by owner_id.
    final rows = await _client
        .from('service_reviews')
        .select('*, profiles(display_name, avatar_url), services!inner(owner_id)')
        .eq('services.owner_id', userId)
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
