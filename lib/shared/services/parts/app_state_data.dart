// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Data loading, navigation & listings ───────────────────────────────────────

extension AppStateData on KoolanAppState {
  Future<void> loadAllData() async {
    isLoadingData = true;
    dataError = null;
    notifyListeners();
    try {
      if (_repo == null) {
        // No authenticated session — attempt a read-only repo using the anon
        // key so guest users can still browse listings and services.
        final client = AppSupabaseConfig.clientOrNull();
        if (client == null) {
          allListings = [];
          chatSessions = [];
          return;
        }
        final anonRepo = SupabaseRepository(client);
        _anonRepo = anonRepo;
        final listings = await anonRepo.fetchListings(
          limit: SupabaseRepository.kPageSize,
          offset: 0,
        );
        allListings = listings;
        hasMoreListings = listings.length >= SupabaseRepository.kPageSize;
        await app_local.LocalStorage.saveListingsCache(
          listings.map((l) => l.toJson()).toList(),
        );
        try {
          final services = await anonRepo.fetchServices(
            limit: SupabaseRepository.kPageSize,
            offset: 0,
          );
          allServices = services;
          hasMoreServices = services.length >= SupabaseRepository.kPageSize;
          await app_local.LocalStorage.saveServicesCache(
            services.map((s) => s.toJson()).toList(),
          );
        } catch (e) {
          debugPrint('fetchServices (guest) failed: $e');
        }
        try {
          final posts = await anonRepo.fetchHiringPosts(
            limit: SupabaseRepository.kPageSize,
            offset: 0,
          );
          allHiringPosts = posts;
          hasMoreHiringPosts = posts.length >= SupabaseRepository.kPageSize;
        } catch (e) {
          debugPrint('fetchHiringPosts (guest) failed: $e');
        }
        chatSessions = [];
        return;
      }
      final listings = await _repo!.fetchListings(
        limit: SupabaseRepository.kPageSize,
        offset: 0,
      );
      allListings = listings;
      hasMoreListings = listings.length >= SupabaseRepository.kPageSize;
      await app_local.LocalStorage.saveListingsCache(
        listings.map((l) => l.toJson()).toList(),
      );
      final services = await _repo!.fetchServices(
        limit: SupabaseRepository.kPageSize,
        offset: 0,
      );
      allServices = services;
      hasMoreServices = services.length >= SupabaseRepository.kPageSize;
      await app_local.LocalStorage.saveServicesCache(
        services.map((s) => s.toJson()).toList(),
      );
      try {
        final raw = await _repo!.fetchChatSessions();
        chatSessions = await _enrichChatSessions(raw);
      } catch (e) {
        debugPrint('fetchChatSessions failed: $e');
      }
      try {
        final posts = await _repo!.fetchHiringPosts(
          limit: SupabaseRepository.kPageSize,
          offset: 0,
        );
        hasMoreHiringPosts = posts.length >= SupabaseRepository.kPageSize;
        final myPostIds = posts
            .where((p) => p.posterId == currentUser?.id)
            .map((p) => p.id)
            .toList();
        final counts = await _repo!.fetchApplicantCounts(myPostIds);
        allHiringPosts = posts.map((p) {
          final count = counts[p.id] ?? 0;
          return count > 0 ? p.copyWith(applicantCount: count) : p;
        }).toList();
      } catch (e) {
        debugPrint('fetchHiringPosts failed: $e');
      }
      try {
        myApplications = await _repo!.fetchMyApplications();
      } catch (e) {
        debugPrint('fetchMyApplications failed: $e');
      }
      try {
        notifications = await _repo!.fetchNotifications();
      } catch (e) {
        debugPrint('fetchNotifications failed: $e');
      }
    } on SocketException catch (e) {
      debugPrint('fetchListings offline (SocketException): $e');
      await _serveListingsFromCache();
    } on HandshakeException catch (e) {
      debugPrint('fetchListings offline (HandshakeException): $e');
      await _serveListingsFromCache();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final isNetworkError =
          msg.contains('network') ||
          msg.contains('socket') ||
          msg.contains('connection') ||
          msg.contains('host lookup') ||
          msg.contains('failed host') ||
          msg.contains('errno = 7') ||
          msg.contains('errno = 101') ||
          msg.contains('errno = 111');

      if (isNetworkError) {
        debugPrint('fetchListings network error: $e');
        await _serveListingsFromCache();
      } else {
        debugPrint('fetchListings error: $e');
        dataError = e.toString();
      }
    } finally {
      isLoadingData = false;
      notifyListeners();
    }
  }

  Future<void> _serveListingsFromCache() async {
    if (allListings.isNotEmpty || allServices.isNotEmpty) {
      return;
    }
    final listingsCached = await app_local.LocalStorage.getListingsCache();
    if (listingsCached != null && listingsCached.isNotEmpty) {
      final userId = currentUser?.id;
      allListings = listingsCached
          .map(
            (json) => Listing.fromJson(
              json,
              isSaved: json['is_saved'] as bool? ?? false,
              isOwnedByCurrentUser: json['seller_id'] == userId,
            ),
          )
          .toList();
    }
    final servicesCached = await app_local.LocalStorage.getServicesCache();
    if (servicesCached != null && servicesCached.isNotEmpty) {
      final userId = currentUser?.id;
      allServices = servicesCached
          .map((json) => Service.fromJson(json))
          .where((service) => service.ownerId == userId || service.availability)
          .toList();
    }
    if (allListings.isNotEmpty || allServices.isNotEmpty) {
      dataError = 'Showing cached data — you appear to be offline.';
    } else {
      dataError = 'No internet connection and no cached data available.';
    }
  }

  // ── Navigation actions ────────────────────────────────────────────────────────

  void pushScreen(KoolanScreen screen) {
    navigationStack.add(screen);
    notifyListeners();
  }

  void popScreen() {
    if (navigationStack.length > 1) {
      navigationStack.removeLast();
      notifyListeners();
    }
  }

  void switchTab(KoolanScreen rootTab) {
    navigationStack
      ..clear()
      ..add(HomeScreenRoute());
    if (rootTab is! HomeScreenRoute) {
      navigationStack.add(rootTab);
    }
    notifyListeners();
  }

  // ── Filter actions ────────────────────────────────────────────────────────────

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  // ── Pagination: load more ─────────────────────────────────────────────────────

  /// Appends the next page of listings to [allListings].
  Future<void> loadMoreListings() async {
    if (isLoadingMore || !hasMoreListings) return;
    final repo = _repo ?? _anonRepo;
    if (repo == null) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await repo.fetchListings(
        limit: SupabaseRepository.kPageSize,
        offset: allListings.length,
      );
      final existingIds = allListings.map((l) => l.id).toSet();
      final newItems = page.where((l) => !existingIds.contains(l.id)).toList();
      allListings = [...allListings, ...newItems];
      hasMoreListings = page.length >= SupabaseRepository.kPageSize;
    } catch (e) {
      debugPrint('loadMoreListings failed: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Appends the next page of services to [allServices].
  Future<void> loadMoreServices() async {
    if (isLoadingMore || !hasMoreServices) return;
    final repo = _repo ?? _anonRepo;
    if (repo == null) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await repo.fetchServices(
        limit: SupabaseRepository.kPageSize,
        offset: allServices.length,
      );
      final existingIds = allServices.map((s) => s.id).toSet();
      final newItems = page.where((s) => !existingIds.contains(s.id)).toList();
      allServices = [...allServices, ...newItems];
      hasMoreServices = page.length >= SupabaseRepository.kPageSize;
    } catch (e) {
      debugPrint('loadMoreServices failed: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Appends the next page of hiring posts to [allHiringPosts].
  Future<void> loadMoreHiringPosts() async {
    if (isLoadingMore || !hasMoreHiringPosts) return;
    final repo = _repo ?? _anonRepo;
    if (repo == null) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await repo.fetchHiringPosts(
        limit: SupabaseRepository.kPageSize,
        offset: allHiringPosts.length,
      );
      final existingIds = allHiringPosts.map((p) => p.id).toSet();
      final newItems = page.where((p) => !existingIds.contains(p.id)).toList();
      allHiringPosts = [...allHiringPosts, ...newItems];
      hasMoreHiringPosts = page.length >= SupabaseRepository.kPageSize;
    } catch (e) {
      debugPrint('loadMoreHiringPosts failed: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Listing helpers ───────────────────────────────────────────────────────────

  List<Listing> getFilteredListings() {
    return allListings.where((listing) {
      final matchesCategory =
          selectedCategory == 'ALL' || listing.category == selectedCategory;
      final q = searchQuery.toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          listing.title.toLowerCase().contains(q) ||
          listing.location.toLowerCase().contains(q) ||
          listing.description.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<Listing> getSavedListings() =>
      allListings.where((l) => l.isSaved).toList();

  List<Listing> getMyListings() =>
      allListings.where((l) => l.isOwnedByCurrentUser).toList();

  /// Optimistically removes [listingId] from [allListings] and deletes it
  /// from Supabase. No offline-queue path — requires connectivity.
  Future<void> deleteListing(String listingId) async {
    allListings.removeWhere((l) => l.id == listingId);
    notifyListeners();
    try {
      await _repo?.deleteListing(listingId);
    } catch (e) {
      dataError = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateListing({
    required Listing listing,
    required String title,
    required String price,
    required String description,
    required String location,
    List<String> newImagePaths = const [],
    List<String> existingImageUrls = const [],
  }) async {
    if (_repo == null) {
      dataError = 'Supabase unavailable';
      notifyListeners();
      return;
    }

    final userId = currentUser?.id ?? '';
    final uploadedUrls = <String>[];

    for (int i = 0; i < newImagePaths.length; i++) {
      final file = File(newImagePaths[i]);
      if (!await file.exists()) continue;
      final result = await CloudinaryUploadService.instance.uploadListingImage(
        imageFile: file,
        userId: userId,
        listingId: listing.id,
        index: existingImageUrls.length + i,
      );
      if (result is CloudinaryUploadSuccess) {
        uploadedUrls.add(result.secureUrl);
      }
    }

    final mergedUrls = [...existingImageUrls, ...uploadedUrls];
    final primaryImageUrl =
        mergedUrls.isNotEmpty ? mergedUrls.first : listing.imageUrl;

    final priceStr =
        (price.startsWith('ETB') || price.startsWith(r'$'))
            ? price.trim()
            : 'ETB ${price.trim()}';

    final updated = listing.copyWith(
      title: title.trim(),
      price: priceStr,
      description: description.trim(),
      location: location.trim(),
      imageUrl: primaryImageUrl,
      imageUrls: mergedUrls,
      localUpdatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    final idx = allListings.indexWhere((l) => l.id == listing.id);
    if (idx != -1) allListings[idx] = updated;
    notifyListeners();

    try {
      await _repo!.updateListing(listing.id, {
        'title': updated.title,
        'price': updated.price,
        'description': updated.description,
        'location': updated.location,
        'image_url': primaryImageUrl,
        'image_urls': mergedUrls,
      });
      if (idx != -1) {
        allListings[idx] = updated.copyWith(syncStatus: SyncStatus.synced);
      }
    } catch (e) {
      if (idx != -1) {
        allListings[idx] = updated.copyWith(syncStatus: SyncStatus.failed);
      }
      dataError = e.toString();
    }
    notifyListeners();
  }

  // ── Save / Bookmark ───────────────────────────────────────────────────────────

  Future<void> toggleSaveListing(String listingId) async {
    final index = allListings.indexWhere((l) => l.id == listingId);
    if (index == -1) return;
    final listing = allListings[index];
    final newSaved = !listing.isSaved;
    allListings[index] = listing.copyWith(isSaved: newSaved);
    notifyListeners();
    try {
      if (_repo == null) {
        dataError = 'Supabase unavailable';
        notifyListeners();
        return;
      }
      await _repo!.toggleFavorite(listingId, listing.isSaved);
    } catch (e) {
      allListings[index] = listing;
      dataError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Comparison ────────────────────────────────────────────────────────────────

  void toggleCompareMode() {
    compareModeEnabled = !compareModeEnabled;
    if (!compareModeEnabled) selectedCompareIds.clear();
    notifyListeners();
  }

  void toggleCompareSelection(String id) {
    if (selectedCompareIds.contains(id)) {
      selectedCompareIds.remove(id);
    } else if (selectedCompareIds.length < 2) {
      selectedCompareIds.add(id);
    }
    notifyListeners();
  }
}
