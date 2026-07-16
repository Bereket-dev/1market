import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat.dart';
import '../models/listing.dart';
import '../models/profile.dart';

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

    await _client.from('profiles').insert({
      'id': userId,
      'display_name': displayName,
      'avatar_url': meta['avatar_url'],
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

  Future<List<Listing>> fetchListings({Set<String>? savedIds}) async {
    final rows = await _client
        .from('listings')
        .select()
        .order('created_at', ascending: false);

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
          'verified': true,
          'condition_or_status': conditionOrStatus,
          'seller_name': sellerName,
          'seller_image': sellerImage,
          'seller_rating': 5.0,
          'seller_reviews_count': 1,
          'description': description,
          'spec1_label': spec1Label,
          'spec1_value': spec1Value,
          'spec2_label': spec2Label,
          'spec2_value': spec2Value,
          'spec3_label': spec3Label,
          'spec3_value': spec3Value,
          'spec4_label': spec4Label,
          'spec4_value': spec4Value,
        })
        .select()
        .single();

    return Listing.fromJson(row, isOwnedByCurrentUser: true);
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
}
