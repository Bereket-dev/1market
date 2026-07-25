part of '../supabase_repository.dart';

// ── Listings ──────────────────────────────────────────────────────────

extension SupabaseRepositoryListings on SupabaseRepository {
  // ── Listings ────────────────────────────────────────────────────────────────

  Future<List<Listing>> fetchListings({
    Set<String>? savedIds,
    int limit = SupabaseRepository.kPageSize,
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
    int limit = SupabaseRepository.kPageSize,
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
        .eq('seller_id', userId);
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

}
