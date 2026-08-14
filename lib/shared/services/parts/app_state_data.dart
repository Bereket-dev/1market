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
          if (kDebugMode) debugPrint('fetchServices (guest) failed: $e');
        }
        try {
          final posts = await anonRepo.fetchHiringPosts(
            limit: SupabaseRepository.kPageSize,
            offset: 0,
          );
          allHiringPosts = posts;
          hasMoreHiringPosts = posts.length >= SupabaseRepository.kPageSize;
        } catch (e) {
          if (kDebugMode) debugPrint('fetchHiringPosts (guest) failed: $e');
        }
        try {
          homePromos = await anonRepo.fetchHomePromos();
        } catch (e) {
          if (kDebugMode) debugPrint('fetchHomePromos (guest) failed: $e');
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
        if (kDebugMode) debugPrint('fetchChatSessions failed: $e');
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
        if (kDebugMode) debugPrint('fetchHiringPosts failed: $e');
      }
      try {
        myApplications = await _repo!.fetchMyApplications();
      } catch (e) {
        if (kDebugMode) debugPrint('fetchMyApplications failed: $e');
      }
      try {
        notifications = await _repo!.fetchNotifications();
      } catch (e) {
        if (kDebugMode) debugPrint('fetchNotifications failed: $e');
      }
      try {
        homePromos = await _repo!.fetchHomePromos();
      } catch (e) {
        if (kDebugMode) debugPrint('fetchHomePromos failed: $e');
      }
    } on SocketException catch (e) {
      if (kDebugMode) debugPrint('fetchListings offline (SocketException): $e');
      await _serveListingsFromCache();
    } on HandshakeException catch (e) {
      if (kDebugMode) debugPrint('fetchListings offline (HandshakeException): $e');
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
        if (kDebugMode) debugPrint('fetchListings network error: $e');
        await _serveListingsFromCache();
      } else {
        if (kDebugMode) debugPrint('fetchListings error: $e');
        reportDataError(e);
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
      allListings = SafeParse.mapList(
        listingsCached,
        (json) => Listing.fromJson(
          json,
          isSaved: json['is_saved'] as bool? ?? false,
          isOwnedByCurrentUser: json['seller_id'] == userId,
        ),
        context: 'listings_cache',
      );
    }
    final servicesCached = await app_local.LocalStorage.getServicesCache();
    if (servicesCached != null && servicesCached.isNotEmpty) {
      final userId = currentUser?.id;
      allServices = SafeParse.mapList(
        servicesCached,
        Service.fromJson,
        context: 'services_cache',
      ).where((service) => service.ownerId == userId || service.availability).toList();
    }
    if (allListings.isNotEmpty || allServices.isNotEmpty) {
      dataError = s.errorOfflineCached;
    } else {
      dataError = s.errorOfflineNoCache;
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
      if (kDebugMode) debugPrint('loadMoreListings failed: $e');
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
      if (kDebugMode) debugPrint('loadMoreServices failed: $e');
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
      if (kDebugMode) debugPrint('loadMoreHiringPosts failed: $e');
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
      reportDataError(e);
      notifyListeners();
    }
  }

  Future<void> updateListing({
    required Listing listing,
    required String title,
    required String price,
    required String description,
    required String location,
    String? category,
    String? conditionOrStatus,
    String? spec1Value,
    String? spec2Value,
    String? spec3Value,
    String? spec4Value,
    List<String> newImagePaths = const [],
    List<String> existingImageUrls = const [],
  }) async {
    if (_repo == null) {
      dataError = s.errorSupabaseUnavailable;
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

    final resolvedCategory = (category != null && category.isNotEmpty)
        ? category
        : listing.category;

    final updated = listing.copyWith(
      category: resolvedCategory,
      title: title.trim(),
      price: priceStr,
      description: description.trim(),
      location: location.trim(),
      conditionOrStatus: conditionOrStatus ?? listing.conditionOrStatus,
      spec1Value: spec1Value ?? listing.spec1Value,
      spec2Value: spec2Value ?? listing.spec2Value,
      spec3Value: spec3Value ?? listing.spec3Value,
      spec4Value: spec4Value ?? listing.spec4Value,
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
        'category': updated.category,
        'title': updated.title,
        'price': updated.price,
        'description': updated.description,
        'location': updated.location,
        'condition_or_status': updated.conditionOrStatus,
        'spec1_value': updated.spec1Value,
        'spec2_value': updated.spec2Value,
        'spec3_value': updated.spec3Value,
        'spec4_value': updated.spec4Value,
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
      reportDataError(e);
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
        dataError = s.errorSupabaseUnavailable;
        notifyListeners();
        return;
      }
      await _repo!.toggleFavorite(listingId, listing.isSaved);
    } catch (e) {
      allListings[index] = listing;
      reportDataError(e);
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
