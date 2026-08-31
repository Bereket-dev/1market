// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of '../app_state.dart';

// ── Data loading, navigation & listings ───────────────────────────────────────

extension AppStateData on OnemarketAppState {
  // ── MarketplaceRepository accessor ───────────────────────────────────────────

  MarketplaceRepository? _ensureMarketplaceRepo() {
    final repo = _repo ?? _anonRepo;
    if (repo == null) return null;
    // Always bind to the current auth client (guest anon ↔ signed-in).
    _marketplaceRepo = MarketplaceRepository(
      supabaseRepo: repo,
      observability: syncObservability,
    );
    return _marketplaceRepo;
  }

  // ── Local-first load + background sync ───────────────────────────────────────
  //
  // Strategy:
  //   1. Immediately read the Hive mirror → render content (< 1 ms).
  //   2. If no local data → set isLoadingData = true (full-screen spinner path).
  //   3. Set isRefreshing = true → subtle background indicator.
  //   4. Run delta/full fetch in background.
  //   5. Merge results; notifyListeners() with surgical updates.
  //   6. Clear isRefreshing; advance lastSuccessfulSyncAt.

  Future<void> loadAllData({bool forceRefresh = false}) async {
    dataError = null;

    final marketRepo = _ensureMarketplaceRepo();

    // ── Step 1: read from local mirror ───────────────────────────────────────
    if (marketRepo != null) {
      await _serveFromLocalMirror(marketRepo);
    }

    // ── Step 2: decide loading state ─────────────────────────────────────────
    final hasLocalData =
        allListings.isNotEmpty ||
        allServices.isNotEmpty ||
        allHiringPosts.isNotEmpty;

    if (!hasLocalData) {
      // No cache at all → show full-screen spinner until first data arrives.
      isLoadingData = true;
    }
    isRefreshing = true;
    notifyListeners();

    // ── Step 3: background network sync ──────────────────────────────────────
    try {
      if (_repo == null) {
        await _guestLoadOrSync(marketRepo, forceRefresh: forceRefresh);
      } else {
        await _authedLoadOrSync(marketRepo, forceRefresh: forceRefresh);
      }
      // Mark successful sync time.
      final now = DateTime.now();
      lastSuccessfulSyncAt = now;
      await HiveSyncStore.instance.setLastSyncedAt(now);
    } on SocketException catch (e) {
      if (kDebugMode) debugPrint('[loadAllData] offline (SocketException): $e');
      if (!hasLocalData) await _serveListingsFromCache();
    } on HandshakeException catch (e) {
      if (kDebugMode)
        debugPrint('[loadAllData] offline (HandshakeException): $e');
      if (!hasLocalData) await _serveListingsFromCache();
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
        if (kDebugMode) debugPrint('[loadAllData] network error: $e');
        if (!hasLocalData) await _serveListingsFromCache();
      } else {
        if (kDebugMode) debugPrint('[loadAllData] error: $e');
        reportDataError(e);
      }
    } finally {
      isLoadingData = false;
      isRefreshing = false;
      notifyListeners();
    }
  }

  /// Reads entities from the Hive mirror without touching the network.
  Future<void> _serveFromLocalMirror(MarketplaceRepository repo) async {
    final userId = currentUser?.id;
    // Favorites are best-effort here; we use an empty set if not yet loaded.
    final savedIds = <String>{};

    final localListings = await repo.loadListingsFromLocal(
      currentUserId: userId,
      savedIds: savedIds,
    );
    final localServices = await repo.loadServicesFromLocal();
    final localPosts = await repo.loadHiringPostsFromLocal();

    if (localListings.isNotEmpty) allListings = localListings;
    if (localServices.isNotEmpty) allServices = localServices;
    if (localPosts.isNotEmpty) allHiringPosts = localPosts;
  }

  // ── Guest path ────────────────────────────────────────────────────────────

  Future<void> _guestLoadOrSync(
    MarketplaceRepository? marketRepo, {
    bool forceRefresh = false,
  }) async {
    final client = AppSupabaseConfig.clientOrNull();
    if (client == null) {
      allListings = [];
      chatSessions = [];
      return;
    }
    final anonRepo = SupabaseRepository(client);
    _anonRepo = anonRepo;
    _marketplaceRepo = MarketplaceRepository(
      supabaseRepo: anonRepo,
      observability: syncObservability,
    );

    // Prefer cold seed whenever the Hive mirror has no listings — a version
    // cursor alone must never skip the first full fetch.
    final hasMirrorData =
        allListings.isNotEmpty && _marketplaceRepo!.hasListingsMirrorData;

    // Promos are independent of the marketplace seed — fetch in parallel so
    // the carousel can paint images without waiting for listings/Hive.
    final promosFuture = _fetchHomePromos(anonRepo);

    if (hasMirrorData) {
      await _syncInboundPriority1(
        _marketplaceRepo!,
        userId: null,
        forceRefresh: forceRefresh,
      );
      // If sync left the in-memory feed empty, fall back to a full seed.
      if (allListings.isEmpty) {
        try {
          await _coldSeedPriority1(anonRepo, _marketplaceRepo!);
        } catch (e) {
          if (kDebugMode)
            debugPrint('[guestLoadOrSync] fallback coldSeed failed: $e');
        }
      }
    } else {
      // No local mirror — full cold seed.  Wrapped so any unexpected error
      // doesn't reach loadAllData's outer catch, which would call
      // reportDataError() even when data was successfully fetched and set on
      // allListings by an earlier step inside _coldSeedPriority1.
      try {
        await _coldSeedPriority1(anonRepo, _marketplaceRepo!);
      } catch (e) {
        if (kDebugMode) debugPrint('[guestLoadOrSync] coldSeed failed: $e');
      }
    }

    await promosFuture;
    chatSessions = [];
  }

  /// Loads home promo cards and notifies so the carousel can refresh early.
  Future<void> _fetchHomePromos(SupabaseRepository repo) async {
    try {
      homePromos = await repo.fetchHomePromos();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[loadAllData] fetchHomePromos failed: $e');
    }
  }

  // ── Authed path ───────────────────────────────────────────────────────────

  Future<void> _authedLoadOrSync(
    MarketplaceRepository? marketRepo, {
    bool forceRefresh = false,
  }) async {
    final repo = _repo!;
    final userId = currentUser?.id;
    final market =
        marketRepo ??
        (_marketplaceRepo = MarketplaceRepository(
          supabaseRepo: repo,
          observability: syncObservability,
        ));

    final hasMirrorData =
        allListings.isNotEmpty && market.hasListingsMirrorData;

    if (hasMirrorData) {
      // P1 → P2 → P3 prioritized inbound sync.
      await _syncInboundPriority1(
        market,
        userId: userId,
        forceRefresh: forceRefresh,
      );
      notifyListeners();

      if (allListings.isEmpty) {
        await _coldSeedPriority1(repo, market);
        notifyListeners();
      }

      await _syncInboundPriority2(repo, userId: userId);
      notifyListeners();

      await _syncInboundPriority3(repo);
    } else {
      await _coldSeedPriority1(repo, market);
      notifyListeners();

      await _syncInboundPriority2(repo, userId: userId);
      await _syncInboundPriority3(repo);
    }

    await _fetchHomePromos(repo);
  }

  // ── Prioritized inbound sync (Phase 2) ────────────────────────────────────

  /// P1: listings, services, hiring — marketplace feed content.
  ///
  /// When a user city is known from the profile and [forceRefresh] is false,
  /// uses [MarketplaceRepository.syncWithRegionalPriority] to prefetch the
  /// user's city first, then nearby cities, then all regions.
  ///
  /// Falls back to individual delta syncs when city is unknown or the user
  /// explicitly requests a full refresh.
  Future<void> _syncInboundPriority1(
    MarketplaceRepository marketRepo, {
    String? userId,
    bool forceRefresh = false,
  }) async {
    marketRepo.beginSyncCycle();

    // Use the profile's city field as the regional anchor.
    // profile is loaded in P2, so it may be null on first ever launch —
    // _regionalTiers defaults to Dire Dawa (East Ethiopia launch city).
    final userCity = profile?.city;

    if (userCity != null && !forceRefresh) {
      // Tiered regional sync on updated_at fallback; no-ops to one version
      // pass when the monotonic cursor is active.
      await marketRepo.syncWithRegionalPriority(
        userCity: userCity,
        currentUserId: userId,
        savedIds: const {},
        forceRefresh: false,
      );

      // After regional sync the local mirror is up to date; read it back.
      final mergedListings = await marketRepo.loadListingsFromLocal(
        currentUserId: userId,
        savedIds: const {},
      );
      _applyListingsMerge(mergedListings);

      final mergedServices = await marketRepo.loadServicesFromLocal();
      _applyServicesMerge(mergedServices);

      final mergedPosts = await marketRepo.loadHiringPostsFromLocal();
      _applyHiringPostsMerge(mergedPosts);
    } else {
      // No city known (first launch, guest, or force-refresh) — standard
      // unfiltered delta sync.
      final mergedListings = await marketRepo.syncListingsDelta(
        currentUserId: userId,
        savedIds: const {},
        forceRefresh: forceRefresh,
      );
      _applyListingsMerge(mergedListings);

      final mergedServices = await marketRepo.syncServicesDelta(
        forceRefresh: forceRefresh,
      );
      _applyServicesMerge(mergedServices);

      final mergedPosts = await marketRepo.syncHiringPostsDelta(
        forceRefresh: forceRefresh,
      );
      _applyHiringPostsMerge(mergedPosts);
    }
  }

  /// P2: favorites flags, own profile, applications.
  Future<void> _syncInboundPriority2(
    SupabaseRepository repo, {
    String? userId,
  }) async {
    if (userId != null) {
      try {
        final savedIds = await repo.fetchFavoriteIds(userId);
        _applySavedFlags(savedIds);
      } catch (e) {
        if (kDebugMode) debugPrint('[P2] fetchFavoriteIds failed: $e');
      }
    }
    try {
      final resolved = await repo.ensureProfile();
      profile = resolved;
      await app_local.LocalStorage.saveProfileCache(resolved.toJson());
    } catch (e) {
      if (kDebugMode) debugPrint('[P2] ensureProfile failed: $e');
    }
    try {
      myApplications = await repo.fetchMyApplications();
    } catch (e) {
      if (kDebugMode) debugPrint('[P2] fetchMyApplications failed: $e');
    }
  }

  /// P3: notifications (non-blocking for feed render).
  Future<void> _syncInboundPriority3(SupabaseRepository repo) async {
    try {
      notifications = await repo.fetchNotifications();
    } catch (e) {
      if (kDebugMode) debugPrint('[P3] fetchNotifications failed: $e');
    }
  }

  void _applySavedFlags(Set<String> savedIds) {
    if (allListings.isEmpty) return;
    allListings = allListings
        .map((l) => l.copyWith(isSaved: savedIds.contains(l.id)))
        .toList();
  }

  /// Cold cache seed with resumable offset persistence.
  ///
  /// Each phase (listings / services / hiring) is fully isolated: a Hive write
  /// failure in the mirror-seed step never discards already-fetched network
  /// data. The in-memory lists are always updated before any Hive I/O so the
  /// UI can render even when local storage is unavailable (e.g. first launch
  /// after clearing app data).
  Future<void> _coldSeedPriority1(
    SupabaseRepository repo,
    MarketplaceRepository marketRepo,
  ) async {
    // ── Listings ──────────────────────────────────────────────────────────────
    const listingsEntity = 'listings';
    try {
      await HiveSyncStore.instance.setInProgressEntity(listingsEntity);
    } catch (e) {
      if (kDebugMode)
        debugPrint('[coldSeed] setInProgressEntity failed (non-fatal): $e');
    }
    final listingsOffset =
        HiveSyncStore.instance.getSeedOffset(listingsEntity) ?? 0;

    try {
      final listings = await repo.fetchListings(
        limit: SupabaseRepository.kPageSize,
        offset: listingsOffset,
      );
      // Update in-memory state FIRST so the UI can render regardless of
      // whether the Hive mirror write succeeds below.
      allListings = listings;
      hasMoreListings = listings.length >= SupabaseRepository.kPageSize;

      // Best-effort cache writes — failures must not prevent data from
      // appearing in the UI.
      try {
        await app_local.LocalStorage.saveListingsCache(
          listings.map((l) => l.toJson()).toList(),
        );
      } catch (e) {
        if (kDebugMode)
          debugPrint('[coldSeed] saveListingsCache failed (non-fatal): $e');
      }
      try {
        await marketRepo.seedListingsMirror(listings);
        await HiveSyncStore.instance.clearSeedOffset(listingsEntity);
      } catch (e) {
        if (kDebugMode)
          debugPrint('[coldSeed] seedListingsMirror failed (non-fatal): $e');
      }
    } catch (e) {
      // Network fetch itself failed — save offset for resumable retry but do
      // NOT rethrow so services/hiring can still be attempted.
      if (kDebugMode) debugPrint('[coldSeed] fetchListings failed: $e');
      try {
        await HiveSyncStore.instance.setSeedOffset(
          listingsEntity,
          listingsOffset,
        );
      } catch (_) {}
    }

    // ── Services ──────────────────────────────────────────────────────────────
    try {
      final services = await repo.fetchServices(
        limit: SupabaseRepository.kPageSize,
        offset: 0,
      );
      allServices = services;
      hasMoreServices = services.length >= SupabaseRepository.kPageSize;
      try {
        await app_local.LocalStorage.saveServicesCache(
          services.map((s) => s.toJson()).toList(),
        );
      } catch (e) {
        if (kDebugMode)
          debugPrint('[coldSeed] saveServicesCache failed (non-fatal): $e');
      }
      try {
        await marketRepo.seedServicesMirror(services);
      } catch (e) {
        if (kDebugMode)
          debugPrint('[coldSeed] seedServicesMirror failed (non-fatal): $e');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[coldSeed] fetchServices failed: $e');
    }

    // ── Hiring posts ──────────────────────────────────────────────────────────
    try {
      final userId = currentUser?.id;
      final posts = await repo.fetchHiringPosts(
        limit: SupabaseRepository.kPageSize,
        offset: 0,
      );
      hasMoreHiringPosts = posts.length >= SupabaseRepository.kPageSize;
      final myPostIds = posts
          .where((p) => p.posterId == userId)
          .map((p) => p.id)
          .toList();
      final counts = await repo.fetchApplicantCounts(myPostIds);
      allHiringPosts = posts.map((p) {
        final count = counts[p.id] ?? 0;
        return count > 0 ? p.copyWith(applicantCount: count) : p;
      }).toList();
      try {
        await marketRepo.seedHiringPostsMirror(allHiringPosts);
      } catch (e) {
        if (kDebugMode)
          debugPrint('[coldSeed] seedHiringPostsMirror failed (non-fatal): $e');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[coldSeed] fetchHiringPosts failed: $e');
    }

    await HiveSyncStore.instance.setInProgressEntity(null);

    // ── Phase 4: bootstrap version cursor to server tip ───────────────────
    //
    // After cold seed the mirror is populated via full-page fetch. Jump the
    // monotonic cursor to max(marketplace_changes.version) WITHOUT replaying
    // change-log payloads (that would re-download everything). Subsequent
    // syncs then use get_changes_since(tip) for true deltas.
    //
    // Only bootstrap when no version is stored so we never overwrite a
    // valid high-water mark from a previous session.
    final existingVersion = HiveSyncStore.instance.getSyncVersion();
    if (existingVersion == null) {
      final tip = await marketRepo.bootstrapSyncVersionToLatest();
      if (kDebugMode) {
        debugPrint(
          tip == null
              ? '[coldSeed] version cursor bootstrap skipped (RPC unavailable)'
              : '[coldSeed] version cursor bootstrapped to v$tip',
        );
      }
    }
  }

  // ── Surgical list update helpers ──────────────────────────────────────────
  //
  // Instead of replacing the entire list (which triggers a full rebuild of
  // every card), these helpers apply only the items that changed.

  void _applyListingsMerge(List<Listing> merged) {
    if (merged.isEmpty) return;
    allListings = merged;
    hasMoreListings = merged.length >= SupabaseRepository.kPageSize;
  }

  void _applyServicesMerge(List<Service> merged) {
    if (merged.isEmpty) return;
    allServices = merged;
    hasMoreServices = merged.length >= SupabaseRepository.kPageSize;
  }

  void _applyHiringPostsMerge(List<HiringPost> merged) {
    if (merged.isEmpty) return;
    allHiringPosts = merged;
    hasMoreHiringPosts = merged.length >= SupabaseRepository.kPageSize;
  }

  // ── Legacy cache fallback (SharedPreferences) ────────────────────────────
  //
  // Used only when: (a) the mirror is empty, and (b) network fails.
  // Once the mirror is seeded this path is never hit.

  Future<void> _serveListingsFromCache() async {
    if (allListings.isNotEmpty || allServices.isNotEmpty) return;
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
      allServices =
          SafeParse.mapList(
                servicesCached,
                Service.fromJson,
                context: 'services_cache',
              )
              .where(
                (service) => service.ownerId == userId || service.availability,
              )
              .toList();
    }
    if (allListings.isNotEmpty || allServices.isNotEmpty) {
      dataError = s.errorOfflineCached;
    } else {
      dataError = s.errorOfflineNoCache;
    }
  }

  // ── Lazy chat loader ──────────────────────────────────────────────────────
  //
  // Chat sessions are NOT loaded during app-open (they are O(N messages) and
  // irrelevant to the marketplace feed).  Call this when the user enters the
  // Messages tab.

  Future<void> loadChatOnTabEntry() async {
    // Always refresh so unread badges stay current when returning to Messages.
    if (_repo == null) return;
    try {
      await refreshChatSessions();
    } catch (e) {
      if (kDebugMode) debugPrint('[loadChatOnTabEntry] failed: $e');
    }
  }

  // ── Navigation actions ────────────────────────────────────────────────────

  void pushScreen(OnemarketScreen screen) {
    navigationStack.add(screen);
    notifyListeners();
  }

  void popScreen() {
    if (navigationStack.length > 1) {
      navigationStack.removeLast();
      notifyListeners();
    }
  }

  // Replace the current route with one notification so transitions do not
  // observe an intermediate screen while a wizard is being dismissed.
  void replaceTopScreen(OnemarketScreen screen) {
    if (navigationStack.length > 1) navigationStack.removeLast();
    navigationStack.add(screen);
    notifyListeners();
  }

  void switchTab(OnemarketScreen rootTab) {
    navigationStack
      ..clear()
      ..add(HomeScreenRoute());
    if (rootTab is! HomeScreenRoute) {
      navigationStack.add(rootTab);
    }
    if (rootTab is MessagesScreenRoute) {
      unawaited(loadChatOnTabEntry());
    }
    notifyListeners();
  }

  // ── Filter actions ────────────────────────────────────────────────────────

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    // Kick off an async index search; result stored in searchIndexResults.
    // getFilteredListings() will use the cached result on next build().
    unawaited(_updateSearchResults(query));
    notifyListeners();
  }

  // ── Phase 3: Search index integration ────────────────────────────────────
  //
  // [searchIndexResults] and [lastIndexedQuery] are declared on OnemarketAppState
  // (extensions can't hold instance fields in Dart).  The async query result
  // is cached there so the synchronous getFilteredListings() can use it.

  Future<void> _updateSearchResults(String query) async {
    if (query.trim().isEmpty) {
      searchIndexResults = null;
      lastIndexedQuery = '';
      notifyListeners();
      return;
    }
    try {
      final ids = await SearchIndexService.instance.query(query);
      searchIndexResults = ids.isEmpty ? null : ids;
      lastIndexedQuery = query;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[AppState] search index query failed: $e');
      searchIndexResults = null;
      notifyListeners();
    }
  }

  // ── Data Saver toggle (Phase 3) ───────────────────────────────────────────

  /// Toggles the Data Saver mode and persists the preference.
  ///
  /// When enabled:
  ///   • ImagePrefetchService skips all background prefetch.
  ///   • Sync interval is extended (gated by NetworkMonitor).
  Future<void> toggleDataSaver() async {
    dataSaverEnabled = !dataSaverEnabled;
    ImagePrefetchService.instance.dataSaverEnabled = dataSaverEnabled;
    if (dataSaverEnabled) {
      ImagePrefetchService.instance.cancelAll();
    }
    await app_local.LocalStorage.saveDataSaverEnabled(dataSaverEnabled);
    notifyListeners();
  }

  // ── Pagination: load more ─────────────────────────────────────────────────

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

  // ── Listing helpers ───────────────────────────────────────────────────────

  /// Returns filtered listings using the local search index when a query is
  /// active. The index result is cached asynchronously via [setSearchQuery];
  /// when the cache is stale (race between typing and index result) it falls
  /// back to in-memory substring filtering so the UI is never blank.
  List<Listing> getFilteredListings() {
    // Category filter — always applied in memory.
    Iterable<Listing> base = allListings.where(
      (l) => !l.isHidden && l.deletedAt == null,
    );
    if (selectedCategory != 'ALL') {
      base = base.where((l) => l.category == selectedCategory);
    }

    final q = searchQuery.trim();
    if (q.isEmpty) return base.toList();

    // Use index results when the cached query matches the current query.
    final cached = searchIndexResults;
    if (cached != null && lastIndexedQuery == q) {
      return base.where((l) => cached.contains(l.id)).toList();
    }

    // Fallback: synchronous substring search (covers initial keystrokes before
    // the async index result arrives).
    final lower = q.toLowerCase();
    return base.where((l) {
      return l.title.toLowerCase().contains(lower) ||
          l.location.toLowerCase().contains(lower) ||
          l.category.toLowerCase().contains(lower) ||
          l.description.toLowerCase().contains(lower);
    }).toList();
  }

  List<Listing> getSavedListings() =>
      allListings.where((l) => l.isSaved).toList();

  List<Listing> getMyListings() => allListings
      .where((l) => l.isOwnedByCurrentUser && l.deletedAt == null)
      .toList();

  Future<void> loadMyListings() async {
    try {
      final mine = await _repo?.fetchMyListings();
      if (mine == null) return;
      final byId = {for (final listing in allListings) listing.id: listing};
      for (final listing in mine) {
        byId[listing.id] = listing;
      }
      allListings = byId.values.toList();
      notifyListeners();
    } catch (e) {
      reportDataError(e);
    }
  }

  /// Soft-deletes [listingId] so all clients learn about its removal.
  /// No offline-queue path — requires connectivity.
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

  Future<void> setListingHidden(String listingId, bool hidden) async {
    final index = allListings.indexWhere((l) => l.id == listingId);
    if (index == -1) return;
    final listing = allListings[index];
    allListings[index] = listing.copyWith(isHidden: hidden);
    notifyListeners();
    try {
      await _repo?.setListingHidden(listingId, hidden);
    } catch (e) {
      allListings[index] = listing;
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
    final primaryImageUrl = mergedUrls.isNotEmpty
        ? mergedUrls.first
        : listing.imageUrl;

    final priceStr = (price.startsWith('ETB') || price.startsWith(r'$'))
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

  // ── Save / Bookmark ───────────────────────────────────────────────────────

  Future<void> toggleSaveListing(String listingId) async {
    final index = allListings.indexWhere((l) => l.id == listingId);
    if (index == -1) return;
    final listing = allListings[index];
    final newSaved = !listing.isSaved;
    allListings[index] = listing.copyWith(isSaved: newSaved);
    notifyListeners();

    final userId = currentUser?.id;
    if (userId == null) {
      dataError = s.errorSupabaseUnavailable;
      notifyListeners();
      return;
    }

    // Durable queue — survives restarts; SyncService retries with backoff.
    await syncService.enqueueFavoriteToggle(
      listingId: listingId,
      isSaved: newSaved,
      userId: userId,
      localUpdatedAt: DateTime.now().toUtc(),
    );
    unawaited(refreshSyncQueueCounts());
  }

  // ── Comparison ────────────────────────────────────────────────────────────

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
