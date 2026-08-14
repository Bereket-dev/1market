part of '../supabase_repository.dart';

// ── Listings ──────────────────────────────────────────────────────────

extension SupabaseRepositoryListings on SupabaseRepository {
  // ── List projection (card view) ────────────────────────────────────────────
  //
  // Narrow select used for the marketplace feed — drops heavy fields like
  // spec labels, description, and translations so the delta payload is small.
  static const _kListingListSelect =
      'id, category, title, price, image_url, image_urls, location, '
      'condition_or_status, seller_id, updated_at, is_hidden, deleted_at, '
      'profiles!seller_id(display_name, avatar_url, phone, rating, reviews_count)';

  /// Full row select for detail screens (all fields).
  static const _kListingDetailSelect =
      '*, profiles!seller_id(display_name, avatar_url, phone, rating, reviews_count)';

  // ── Listings ────────────────────────────────────────────────────────────────

  Future<List<Listing>> fetchListings({
    Set<String>? savedIds,
    int limit = SupabaseRepository.kPageSize,
    int offset = 0,
  }) async {
    final rows = await _client
        .from('listings')
        .select(_kListingDetailSelect)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final userId = currentUserId;
    final favorites = savedIds ??
        (userId != null ? await _fetchFavoriteIds(userId) : <String>{});

    return SafeParse.mapList(
      rows as List,
      (row) => Listing.fromJson(
        row,
        isSaved: favorites.contains(row['id'] as String?),
        isOwnedByCurrentUser: row['seller_id'] == userId,
      ),
      context: 'listings',
    );
  }

  /// Narrow-select fetch used by delta sync — returns only card-relevant fields.
  /// Includes rows updated OR soft-deleted since [cursor].
  /// Pass [cursor] == null to fetch the first page without a time filter.
  Future<List<Map<String, dynamic>>> fetchListingsDeltaRaw({
    required DateTime? cursor,
    int limit = 100,
  }) async {
    var query = _client
        .from('listings')
        .select(_kListingListSelect);

    if (cursor != null) {
      final iso = cursor.toUtc().toIso8601String();
      // Rows whose updated_at or deleted_at moved past the cursor.
      query = query.or('updated_at.gt.$iso,deleted_at.gt.$iso');
    }

    final rows = await query
        .order('updated_at', ascending: true)
        .limit(limit);

    return (rows as List).cast<Map<String, dynamic>>();
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

    return SafeParse.mapList(
      rows as List,
      Service.fromJson,
      context: 'services',
    );
  }

  /// Delta fetch for services — returns narrow card-relevant fields.
  Future<List<Map<String, dynamic>>> fetchServicesDeltaRaw({
    required DateTime? cursor,
    int limit = 100,
  }) async {
    const select =
        'id, owner_id, title, category, price_range, location, availability, '
        'image_url, image_urls, updated_at, deleted_at';

    var query = _client.from('services').select(select);

    if (cursor != null) {
      final iso = cursor.toUtc().toIso8601String();
      query = query.or('updated_at.gt.$iso,deleted_at.gt.$iso');
    }

    final rows = await query
        .order('updated_at', ascending: true)
        .limit(limit);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Delta fetch for hiring posts — returns narrow card-relevant fields.
  Future<List<Map<String, dynamic>>> fetchHiringPostsDeltaRaw({
    required DateTime? cursor,
    int limit = 100,
  }) async {
    const select =
        'id, poster_id, title, category, location, price_range, status, '
        'image_url, image_urls, updated_at, deleted_at';

    var query = _client.from('hiring_posts').select(select);

    if (cursor != null) {
      final iso = cursor.toUtc().toIso8601String();
      query = query.or('updated_at.gt.$iso,deleted_at.gt.$iso');
    }

    final rows = await query
        .order('updated_at', ascending: true)
        .limit(limit);

    return (rows as List).cast<Map<String, dynamic>>();
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

  /// Public alias used by [AppStateData._authedLoadOrSync] to resolve
  /// saved listing IDs before a delta merge.
  Future<Set<String>> fetchFavoriteIds(String userId) =>
      _fetchFavoriteIds(userId);

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
        .select(_kListingDetailSelect)
        .single();

    return SafeParse.tryMap(
      Map<String, dynamic>.from(row),
      (json) => Listing.fromJson(json, isOwnedByCurrentUser: true),
      context: 'listing_create',
    )!;
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
