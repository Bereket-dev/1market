part of '../supabase_repository.dart';

// ── Chat ──────────────────────────────────────────────────────────

extension SupabaseRepositoryChat on SupabaseRepository {
  // ── Chat ────────────────────────────────────────────────────────────────────

  Future<List<ChatSession>> fetchChatSessions() async {
    final userId = currentUserId;
    if (userId == null) return [];

    // Single query: threads + listing title + all messages + both partner profiles.
    // Previously this was N+1 (fetchProfile + chat_messages per thread in a loop).
    final threads = await _client
        .from('chat_threads')
        .select(
          '*, '
          'listings(title), '
          'buyer:profiles!buyer_id(display_name, avatar_url, phone, id), '
          'seller:profiles!seller_id(display_name, avatar_url, phone, id), '
          'chat_messages(id, sender_id, text, created_at)',
        )
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('created_at', ascending: false);

    final sessions = <ChatSession>[];
    for (final thread in threads as List) {
      final t = thread as Map<String, dynamic>;
      final threadId = t['id'] as String;
      final buyerId = t['buyer_id'] as String;
      // sellerId not used directly; partner is found via isUserBuyer below.
      final isUserBuyer = buyerId == userId;

      // Partner profile already embedded — no extra round-trip.
      final partnerData = isUserBuyer
          ? t['seller'] as Map<String, dynamic>?
          : t['buyer'] as Map<String, dynamic>?;
      final partnerName = partnerData?['display_name'] as String? ?? 'User';
      final partnerAvatar = partnerData?['avatar_url'] as String? ?? '';

      final listingData = t['listings'] as Map<String, dynamic>?;
      final listingTitle = listingData?['title'] as String? ?? '';

      // Messages also embedded — no extra round-trip.
      final rawMessages = (t['chat_messages'] as List?) ?? [];
      final chatMessages = rawMessages.map((m) {
        return ChatMessage.fromJson(
          m as Map<String, dynamic>,
          currentUserId: userId,
        );
      }).toList()
        ..sort((a, b) => a.localUpdatedAt.compareTo(b.localUpdatedAt));

      sessions.add(ChatSession(
        id: threadId,
        partnerName: partnerName,
        partnerAvatar: partnerAvatar,
        listingTitle: listingTitle,
        listingId: t['listing_id'] as String?,
        messages: chatMessages,
        // unreadCount / isArchived applied in AppState from local device state.
        unreadCount: 0,
        partnerPhone: partnerData?['phone'] as String?,
        partnerUserId: partnerData?['id'] as String?,
      ));
    }

    // Sort sessions by last message time, newest first.
    sessions.sort((a, b) {
      final aTime = a.messages.lastOrNull?.localUpdatedAt ?? DateTime(0);
      final bTime = b.messages.lastOrNull?.localUpdatedAt ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

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

}
