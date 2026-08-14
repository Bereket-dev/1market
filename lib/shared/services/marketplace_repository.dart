import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/errors/safe_parse.dart';
import '../models/hiring_post.dart';
import '../models/listing.dart';
import '../models/service.dart';
import 'image_prefetch_service.dart';
import 'cloudinary_url_builder.dart';
import 'offline/hive_sync_store.dart';
import 'search_index_service.dart';
import 'supabase_repository.dart';
import 'sync_status.dart';

/// Phase 1: local-first marketplace data layer.
///
/// Responsibilities:
///   1. Read cached entities from Hive immediately (< 1 ms, no network).
///   2. Delta-sync changed/deleted rows from Supabase using an updated_at
///      cursor, merge results into Hive, advance the cursor.
///   3. Keep AppState lists up-to-date by returning the merged result.
///
/// Phase 3 additions:
///   • Freshness TTLs: skip delta sync when data was fetched within the TTL
///     unless [forceRefresh] is true (pull-to-refresh).
///   • Search index: index every upserted row so the local token search works.
///   • Cache eviction: enforce mirror caps after each batch upsert.
///
/// Phase 4 additions:
///   • Version cursor: prefer the monotonic marketplace_changes log over the
///     per-entity updated_at cursors. All three entity types share a single
///     global cursor so one RPC call covers the whole feed.
///
/// The repository is a pure data helper — it has no ChangeNotifier and no
/// knowledge of UI state.  AppState calls into it and calls notifyListeners()
/// at the right moments.
class MarketplaceRepository {
  MarketplaceRepository({
    required SupabaseRepository supabaseRepo,
    this.observability,
  }) : _remote = supabaseRepo;

  final SupabaseRepository _remote;

  /// Optional sink for bandwidth observability.  When non-null, every batch
  /// of rows fetched from Supabase is measured and reported via
  /// [SyncObservabilityStatus.addBytesDownloaded].
  final SyncObservabilityStatus? observability;
  final HiveSyncStore _store = HiveSyncStore.instance;

  // ── Entity names used as cursor / TTL keys ───────────────────────────────
  static const _kListings    = 'listings';
  static const _kServices    = 'services';
  static const _kHiringPosts = 'hiring_posts';

  static const _kDeltaBatchSize  = 100;

  // ── Phase 4: version-cursor batch size ───────────────────────────────────
  static const _kChangesBatchSize = 500;

  // ── Phase 3: Freshness TTLs ───────────────────────────────────────────────
  //
  // Default TTLs per entity type.  Pull-to-refresh bypasses these by passing
  // forceRefresh: true.
  static const _kListingsTtl    = Duration(minutes: 5);
  static const _kServicesTtl    = Duration(minutes: 10);
  static const _kHiringPostsTtl = Duration(minutes: 10);

  // ── Phase 4: concurrency / coalesce guards for the shared version pass ───
  //
  // Only one `syncViaCursorVersion` call runs at a time. Concurrent callers
  // await the same Completer. Sequential callers in the same sync cycle
  // (listings → services → hiring) reuse [_versionSyncedThisCycle] so we
  // never issue duplicate get_changes_since RPCs in one refresh.
  Completer<bool>? _versionSyncCompleter;
  bool _versionSyncedThisCycle = false;

  /// Clears the per-refresh coalesce flag. Call at the start of each inbound
  /// sync pass (P1 / regional) so a new refresh can run the version cursor.
  void beginSyncCycle() {
    _versionSyncedThisCycle = false;
  }

  // ── Bandwidth byte counter ────────────────────────────────────────────────

  /// Estimates the wire size of [rows] by JSON-encoding them and reports the
  /// byte count to [observability] when it is non-null.
  ///
  /// Uses UTF-8 character count as a proxy for bytes (accurate for ASCII data;
  /// a small over-estimate for multi-byte characters, which is acceptable for
  /// observability purposes).
  void _countBytes(List<Map<String, dynamic>> rows) {
    if (observability == null) return;
    final bytes = jsonEncode(rows).length;
    observability!.addBytesDownloaded(bytes);
  }

  /// Returns true if the entity was fetched within its TTL and forceRefresh
  /// is false — meaning delta sync can be skipped this pass.
  bool _isFresh(String entity, Duration ttl, {required bool forceRefresh}) {
    if (forceRefresh) return false;
    final last = _store.getLastFetchedAt(entity);
    if (last == null) return false;
    return DateTime.now().toUtc().difference(last) < ttl;
  }

  // ── Local read ────────────────────────────────────────────────────────────

  /// Reads all listing summaries from the Hive mirror.
  /// Returns an empty list when no mirror data exists yet.
  Future<List<Listing>> loadListingsFromLocal({
    required String? currentUserId,
    required Set<String> savedIds,
  }) async {
    final jsonStrings = _store.getAllListingsMirror();
    if (jsonStrings.isEmpty) return [];
    return SafeParse.mapList(
      jsonStrings.map((s) => jsonDecode(s) as Map<String, dynamic>).toList(),
      (row) => Listing.fromJson(
        row,
        isSaved: savedIds.contains(row['id'] as String?),
        isOwnedByCurrentUser: row['seller_id'] == currentUserId,
      ),
      context: 'listings_mirror',
    );
  }

  /// Reads all service summaries from the Hive mirror.
  Future<List<Service>> loadServicesFromLocal() async {
    final jsonStrings = _store.getAllServicesMirror();
    if (jsonStrings.isEmpty) return [];
    return SafeParse.mapList(
      jsonStrings.map((s) => jsonDecode(s) as Map<String, dynamic>).toList(),
      Service.fromJson,
      context: 'services_mirror',
    );
  }

  /// Reads all hiring post summaries from the Hive mirror.
  Future<List<HiringPost>> loadHiringPostsFromLocal() async {
    final jsonStrings = _store.getAllHiringPostsMirror();
    if (jsonStrings.isEmpty) return [];
    return SafeParse.mapList(
      jsonStrings.map((s) => jsonDecode(s) as Map<String, dynamic>).toList(),
      HiringPost.fromJson,
      context: 'hiring_posts_mirror',
    );
  }

  // ── Phase 4: Global version-cursor sync ──────────────────────────────────

  /// Syncs all three entity types in a single pass using the monotonic
  /// marketplace_changes version cursor.
  ///
  /// Returns `true` when the version cursor is active and was used (or is
  /// already caught up for this sync cycle), `false` when callers must fall
  /// back to the per-entity updated_at cursor.
  ///
  /// Concurrent callers share one in-flight pass. Sequential callers in the
  /// same cycle (after [beginSyncCycle]) reuse the first result without a
  /// second RPC.
  ///
  /// [userCity] is accepted for API uniformity but is not applied — the
  /// changes log is region-agnostic. City filtering applies only on the
  /// updated_at fallback path.
  Future<bool> syncViaCursorVersion({
    bool forceRefresh = false,
    String? userCity,
  }) async {
    // Already completed a version pass in this sync cycle — reuse result.
    if (_versionSyncedThisCycle) {
      return _store.getSyncVersion() != null;
    }

    final existing = _versionSyncCompleter;
    if (existing != null && !existing.isCompleted) {
      return existing.future;
    }

    final completer = Completer<bool>();
    _versionSyncCompleter = completer;

    try {
      final result = await _syncViaVersionCursor(forceRefresh: forceRefresh);
      if (result) _versionSyncedThisCycle = true;
      completer.complete(result);
    } catch (e, st) {
      completer.completeError(e, st);
    } finally {
      _versionSyncCompleter = null;
    }

    return completer.future;
  }

  /// Boots the version cursor to the server high-water mark without replaying
  /// change-log payloads. Safe when the local mirror was filled by cold seed
  /// or updated_at delta.
  Future<int?> bootstrapSyncVersionToLatest() async {
    try {
      final latest = await _remote.getLatestSyncVersion();
      await _store.setSyncVersion(latest);
      if (kDebugMode) {
        debugPrint(
          '[MarketplaceRepo] bootstrapped sync_version=$latest '
          '(no change-log replay)',
        );
      }
      return latest;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MarketplaceRepo] bootstrap sync_version failed: $e');
      }
      return null;
    }
  }

  Future<void> _stampAllEntityFetchedAt() async {
    final now = DateTime.now().toUtc();
    await _store.setLastFetchedAt(_kListings, now);
    await _store.setLastFetchedAt(_kServices, now);
    await _store.setLastFetchedAt(_kHiringPosts, now);
  }

  /// Internal implementation of the version-cursor sync pass.
  Future<bool> _syncViaVersionCursor({bool forceRefresh = false}) async {
    var storedVersion = _store.getSyncVersion();

    // Uninitialized — jump to tip without replaying history.
    if (storedVersion == null) {
      final bootstrapped = await bootstrapSyncVersionToLatest();
      if (bootstrapped == null) return false;
      await _stampAllEntityFetchedAt();
      return true;
    }

    // Heal sync_version=0 written by the broken cold-seed bootstrap while the
    // change log already had rows. Mirror stayed current via updated_at.
    if (storedVersion == 0) {
      try {
        final latest = await _remote.getLatestSyncVersion();
        if (latest > 0) {
          await _store.setSyncVersion(latest);
          await _stampAllEntityFetchedAt();
          if (kDebugMode) {
            debugPrint(
              '[MarketplaceRepo] healed sync_version 0 → $latest (no replay)',
            );
          }
          return true;
        }
        // latest == 0: empty log; 0 is a valid caught-up cursor — continue.
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[MarketplaceRepo] heal sync_version=0 failed: $e');
        }
        return false;
      }
    }

    final allFresh = !forceRefresh &&
        _isFresh(_kListings, _kListingsTtl, forceRefresh: false) &&
        _isFresh(_kServices, _kServicesTtl, forceRefresh: false) &&
        _isFresh(_kHiringPosts, _kHiringPostsTtl, forceRefresh: false);

    if (allFresh) {
      if (kDebugMode) {
        debugPrint(
          '[MarketplaceRepo] version cursor: all entities fresh — skipping',
        );
      }
      return true;
    }

    if (kDebugMode) {
      debugPrint(
        '[MarketplaceRepo] version cursor sync starting from v$storedVersion',
      );
    }

    var version = storedVersion;
    var totalChanges = 0;

    DateTime? maxListingChangedAt;
    DateTime? maxServiceChangedAt;
    DateTime? maxHiringPostChangedAt;

    try {
      while (true) {
        final changes = await _remote.getChangesSince(
          sinceVersion: version,
          limit: _kChangesBatchSize,
        );

        if (changes.isEmpty) break;

        totalChanges += changes.length;

        final payloads = changes
            .where((c) => c.payload != null)
            .map((c) => c.payload!)
            .toList();
        if (payloads.isNotEmpty) _countBytes(payloads);

        if (kDebugMode) {
          final estimatedBytes = changes.length * 300;
          debugPrint(
            '[MarketplaceRepo] version cursor: received ${changes.length} changes '
            '(~$estimatedBytes bytes estimated), '
            'v${changes.first.version}..v${changes.last.version}',
          );
        }

        final listingRows = <Map<String, dynamic>>[];
        final serviceRows = <Map<String, dynamic>>[];
        final hiringPostRows = <Map<String, dynamic>>[];

        for (final change in changes) {
          final isDelete =
              change.operation == 'DELETE' || change.payload == null;

          switch (change.entityType) {
            case 'listing':
              if (isDelete) {
                await _store.deleteListingMirror(change.entityId);
                await SearchIndexService.instance.removeEntity(change.entityId);
              } else {
                listingRows.add(change.payload!);
              }
              if (maxListingChangedAt == null ||
                  change.changedAt.isAfter(maxListingChangedAt)) {
                maxListingChangedAt = change.changedAt;
              }

            case 'service':
              if (isDelete) {
                await _store.deleteServiceMirror(change.entityId);
                await SearchIndexService.instance.removeEntity(change.entityId);
              } else {
                serviceRows.add(change.payload!);
              }
              if (maxServiceChangedAt == null ||
                  change.changedAt.isAfter(maxServiceChangedAt)) {
                maxServiceChangedAt = change.changedAt;
              }

            case 'hiring_post':
              if (isDelete) {
                await _store.deleteHiringPostMirror(change.entityId);
                await SearchIndexService.instance.removeEntity(change.entityId);
              } else {
                hiringPostRows.add(change.payload!);
              }
              if (maxHiringPostChangedAt == null ||
                  change.changedAt.isAfter(maxHiringPostChangedAt)) {
                maxHiringPostChangedAt = change.changedAt;
              }

            default:
              if (kDebugMode) {
                debugPrint(
                  '[MarketplaceRepo] unknown entity_type: ${change.entityType}',
                );
              }
          }
        }

        if (listingRows.isNotEmpty) {
          await _mergeListingsDelta(listingRows);
          _scheduleImagePrefetch(listingRows);
        }
        if (serviceRows.isNotEmpty) {
          await _mergeServicesDelta(serviceRows);
          _scheduleImagePrefetch(serviceRows);
        }
        if (hiringPostRows.isNotEmpty) {
          await _mergeHiringPostsDelta(hiringPostRows);
          _scheduleImagePrefetch(hiringPostRows);
        }

        final maxVersion = changes
            .map((c) => c.version)
            .reduce((a, b) => a > b ? a : b);
        if (maxVersion > version) {
          version = maxVersion;
          await _store.setSyncVersion(version);
        }

        if (changes.length < _kChangesBatchSize) break;
      }

      // Always stamp TTLs after a successful pass (including empty).
      await _stampAllEntityFetchedAt();

      if (maxListingChangedAt != null) {
        await _store.setSyncCursor(_kListings, maxListingChangedAt);
      }
      if (maxServiceChangedAt != null) {
        await _store.setSyncCursor(_kServices, maxServiceChangedAt);
      }
      if (maxHiringPostChangedAt != null) {
        await _store.setSyncCursor(_kHiringPosts, maxHiringPostChangedAt);
      }

      if (kDebugMode && totalChanges > 0) {
        debugPrint(
          '[MarketplaceRepo] version cursor sync complete: '
          '$totalChanges total changes applied, now at v$version',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MarketplaceRepo] version cursor sync interrupted: $e');
      }
      rethrow;
    }

    return true;
  }

  // ── Delta sync ───────────────────────────────────────────────────────────

  /// Delta-syncs listings from Supabase using the stored cursor.
  ///
  /// Returns the merged list sorted by updated_at descending (newest first).
  /// Advances the cursor to the max updated_at seen in this batch.
  ///
  /// Pass [forceRefresh] = true (e.g. pull-to-refresh) to bypass the TTL.
  ///
  /// When [userCity] is non-null, the updated_at delta query is filtered to
  /// rows whose location contains that city. Pass null (the default) to fetch
  /// all regions — preserving the existing behaviour.
  Future<List<Listing>> syncListingsDelta({
    required String? currentUserId,
    required Set<String> savedIds,
    bool forceRefresh = false,
    String? userCity,
  }) async {
    // Phase 4: try the global version-cursor pass first.
    final usedVersionCursor = await syncViaCursorVersion(
      forceRefresh: forceRefresh,
      userCity: userCity,
    );
    if (usedVersionCursor) {
      return loadListingsFromLocal(
        currentUserId: currentUserId,
        savedIds: savedIds,
      );
    }

    // Phase 3: skip if data is fresh and no forced refresh requested.
    if (_isFresh(_kListings, _kListingsTtl, forceRefresh: forceRefresh)) {
      if (kDebugMode) {
        debugPrint('[MarketplaceRepo] listings within TTL — skipping delta');
      }
      return loadListingsFromLocal(
        currentUserId: currentUserId,
        savedIds: savedIds,
      );
    }

    await _store.setInProgressEntity(_kListings);
    var sessionFetched = _store.getRecordsFetchedThisSession(_kListings);
    var cursor = _store.getSyncCursor(_kListings);

    try {
      while (true) {
        final rows = await _remote.fetchListingsDeltaRaw(
          cursor: cursor,
          limit: _kDeltaBatchSize,
          userCity: userCity,
        );
        if (rows.isEmpty) break;
        _countBytes(rows);

        await _mergeListingsDelta(rows);
        _scheduleImagePrefetch(rows);

        sessionFetched += rows.length;
        await _store.setRecordsFetchedThisSession(_kListings, sessionFetched);

        final maxUpdatedAt = _maxUpdatedAt(rows);
        if (maxUpdatedAt != null) {
          cursor = maxUpdatedAt;
          // Only advance the global cursor when not filtering by city —
          // a city-filtered pass doesn't guarantee all rows up to that
          // timestamp have been seen.
          if (userCity == null) {
            await _store.setSyncCursor(_kListings, maxUpdatedAt);
          }
        }

        if (rows.length < _kDeltaBatchSize) break;
      }

      if (userCity == null) {
        // Advance lastFetchedAt so subsequent syncs respect TTL.
        await _store.setLastFetchedAt(_kListings, DateTime.now().toUtc());
        await _store.clearRecordsFetchedThisSession(_kListings);
        await _store.setInProgressEntity(null);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[MarketplaceRepo] listings delta interrupted after '
          '$sessionFetched rows — will resume from cursor',
        );
      }
      rethrow;
    }

    return loadListingsFromLocal(
      currentUserId: currentUserId,
      savedIds: savedIds,
    );
  }

  /// Delta-syncs services.
  ///
  /// Pass [forceRefresh] = true to bypass the TTL.
  ///
  /// When [userCity] is non-null, filters the delta query to rows whose
  /// location contains that city. Pass null (default) for all regions.
  Future<List<Service>> syncServicesDelta({
    bool forceRefresh = false,
    String? userCity,
  }) async {
    // Phase 4: try the global version-cursor pass first.
    final usedVersionCursor = await syncViaCursorVersion(
      forceRefresh: forceRefresh,
      userCity: userCity,
    );
    if (usedVersionCursor) {
      return loadServicesFromLocal();
    }

    if (_isFresh(_kServices, _kServicesTtl, forceRefresh: forceRefresh)) {
      if (kDebugMode) {
        debugPrint('[MarketplaceRepo] services within TTL — skipping delta');
      }
      return loadServicesFromLocal();
    }

    await _store.setInProgressEntity(_kServices);
    var sessionFetched = _store.getRecordsFetchedThisSession(_kServices);
    var cursor = _store.getSyncCursor(_kServices);

    try {
      while (true) {
        final rows = await _remote.fetchServicesDeltaRaw(
          cursor: cursor,
          limit: _kDeltaBatchSize,
          userCity: userCity,
        );
        if (rows.isEmpty) break;
        _countBytes(rows);

        await _mergeServicesDelta(rows);
        _scheduleImagePrefetch(rows);

        sessionFetched += rows.length;
        await _store.setRecordsFetchedThisSession(_kServices, sessionFetched);

        final maxUpdatedAt = _maxUpdatedAt(rows);
        if (maxUpdatedAt != null) {
          cursor = maxUpdatedAt;
          if (userCity == null) {
            await _store.setSyncCursor(_kServices, maxUpdatedAt);
          }
        }

        if (rows.length < _kDeltaBatchSize) break;
      }

      if (userCity == null) {
        await _store.setLastFetchedAt(_kServices, DateTime.now().toUtc());
        await _store.clearRecordsFetchedThisSession(_kServices);
        await _store.setInProgressEntity(null);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[MarketplaceRepo] services delta interrupted after '
          '$sessionFetched rows — will resume from cursor',
        );
      }
      rethrow;
    }

    return loadServicesFromLocal();
  }

  /// Delta-syncs hiring posts.
  ///
  /// Pass [forceRefresh] = true to bypass the TTL.
  ///
  /// When [userCity] is non-null, filters the delta query to rows whose
  /// location contains that city. Pass null (default) for all regions.
  Future<List<HiringPost>> syncHiringPostsDelta({
    bool forceRefresh = false,
    String? userCity,
  }) async {
    // Phase 4: try the global version-cursor pass first.
    final usedVersionCursor = await syncViaCursorVersion(
      forceRefresh: forceRefresh,
      userCity: userCity,
    );
    if (usedVersionCursor) {
      return loadHiringPostsFromLocal();
    }

    if (_isFresh(_kHiringPosts, _kHiringPostsTtl, forceRefresh: forceRefresh)) {
      if (kDebugMode) {
        debugPrint('[MarketplaceRepo] hiring posts within TTL — skipping delta');
      }
      return loadHiringPostsFromLocal();
    }

    await _store.setInProgressEntity(_kHiringPosts);
    var sessionFetched = _store.getRecordsFetchedThisSession(_kHiringPosts);
    var cursor = _store.getSyncCursor(_kHiringPosts);

    try {
      while (true) {
        final rows = await _remote.fetchHiringPostsDeltaRaw(
          cursor: cursor,
          limit: _kDeltaBatchSize,
          userCity: userCity,
        );
        if (rows.isEmpty) break;
        _countBytes(rows);

        await _mergeHiringPostsDelta(rows);
        _scheduleImagePrefetch(rows);

        sessionFetched += rows.length;
        await _store.setRecordsFetchedThisSession(_kHiringPosts, sessionFetched);

        final maxUpdatedAt = _maxUpdatedAt(rows);
        if (maxUpdatedAt != null) {
          cursor = maxUpdatedAt;
          if (userCity == null) {
            await _store.setSyncCursor(_kHiringPosts, maxUpdatedAt);
          }
        }

        if (rows.length < _kDeltaBatchSize) break;
      }

      if (userCity == null) {
        await _store.setLastFetchedAt(_kHiringPosts, DateTime.now().toUtc());
        await _store.clearRecordsFetchedThisSession(_kHiringPosts);
        await _store.setInProgressEntity(null);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[MarketplaceRepo] hiring delta interrupted after '
          '$sessionFetched rows — will resume from cursor',
        );
      }
      rethrow;
    }

    return loadHiringPostsFromLocal();
  }

  // ── Phase 4.2: Regional priority sync ────────────────────────────────────

  /// Returns location strings to prefetch in priority order.
  ///
  /// Tier 1: user's own city (if known), defaulting to Jigjiga.
  /// Tier 2: nearby Somali Region cities (Dire Dawa, Harar).
  /// Tier 3: other major cities (Addis Ababa, Djibouti).
  ///
  /// The user's city is always first; other cities follow in tier order,
  /// skipping the user's city to avoid duplication.
  static List<String> _regionalTiers(String? userCity) {
    const tier1Default = 'Jigjiga';
    const tier2 = ['Dire Dawa', 'Harar'];
    const tier3 = ['Addis Ababa', 'Djibouti'];

    final city = userCity ?? tier1Default;
    final others = [...tier2, ...tier3].where((c) => c != city).toList();
    return [city, ...others];
  }

  /// Runs a tiered regional sync on the updated_at fallback path only.
  ///
  /// When the version cursor is active, the change log is global — regional
  /// city filters do not apply, so this method runs a single version pass and
  /// returns (avoiding N city × 3 entity network loops).
  ///
  /// Otherwise:
  ///   Pass 1 — user's own city (or Jigjiga default).
  ///   Pass 2 — nearby cities (Dire Dawa, Harar) then other majors.
  ///   Pass 3 — no city filter (advances global cursors + TTL).
  ///
  /// Passes 1–2 do not advance the global sync cursor.
  Future<void> syncWithRegionalPriority({
    required String? userCity,
    required String? currentUserId,
    required Set<String> savedIds,
    bool forceRefresh = false,
  }) async {
    beginSyncCycle();

    // Version cursor is region-agnostic — one pass covers all cities.
    final usedVersion = await syncViaCursorVersion(forceRefresh: forceRefresh);
    if (usedVersion) {
      if (kDebugMode) {
        debugPrint(
          '[MarketplaceRepo] regional sync skipped — version cursor active',
        );
      }
      return;
    }

    final tiers = _regionalTiers(userCity);

    if (kDebugMode) {
      debugPrint('[MarketplaceRepo] regional sync tiers: $tiers');
    }

    for (final city in tiers) {
      await syncListingsDelta(
        currentUserId: currentUserId,
        savedIds: savedIds,
        forceRefresh: forceRefresh,
        userCity: city,
      );
      await syncServicesDelta(forceRefresh: forceRefresh, userCity: city);
      await syncHiringPostsDelta(forceRefresh: forceRefresh, userCity: city);

      if (kDebugMode) {
        debugPrint('[MarketplaceRepo] regional pass done for city: $city');
      }
    }

    if (kDebugMode) {
      debugPrint('[MarketplaceRepo] regional pass 3: full delta (no city filter)');
    }
    await syncListingsDelta(
      currentUserId: currentUserId,
      savedIds: savedIds,
      forceRefresh: forceRefresh,
      userCity: null,
    );
    await syncServicesDelta(forceRefresh: forceRefresh, userCity: null);
    await syncHiringPostsDelta(forceRefresh: forceRefresh, userCity: null);
  }

  // ── Merge logic ──────────────────────────────────────────────────────────

  /// Merge rules (applied to each row in [delta]):
  ///   • deleted_at IS NOT NULL  → remove from mirror + search index.
  ///   • is_hidden == true       → remove from mirror + search index.
  ///   • otherwise               → upsert (insert or overwrite) in mirror + index.
  ///
  /// Calls [HiveSyncStore.enforceListingsMirrorCap] after the batch.
  Future<void> _mergeListingsDelta(List<Map<String, dynamic>> delta) async {
    for (final row in delta) {
      final id = row['id'] as String?;
      if (id == null) continue;

      final isDeleted = row['deleted_at'] != null;
      final isHidden  = row['is_hidden'] as bool? ?? false;

      if (isDeleted || isHidden) {
        await _store.deleteListingMirror(id);
        await SearchIndexService.instance.removeEntity(id);
        if (kDebugMode) debugPrint('[MarketplaceRepo] Tombstoned listing $id');
      } else {
        await _store.upsertListingMirror(id, jsonEncode(row));
        await SearchIndexService.instance.indexListingJson(row);
      }
    }
    // Enforce listing cap after every batch (Phase 3).
    await _store.enforceListingsMirrorCap();
  }

  Future<void> _mergeServicesDelta(List<Map<String, dynamic>> delta) async {
    for (final row in delta) {
      final id = row['id'] as String?;
      if (id == null) continue;

      final isDeleted = row['deleted_at'] != null;

      // Unlike listings, we keep unavailable services in the mirror so the
      // owner can still manage them.  We only tombstone hard-deletes.
      if (isDeleted) {
        await _store.deleteServiceMirror(id);
        await SearchIndexService.instance.removeEntity(id);
        if (kDebugMode) debugPrint('[MarketplaceRepo] Tombstoned service $id');
      } else {
        await _store.upsertServiceMirror(id, jsonEncode(row));
        await SearchIndexService.instance.indexServiceJson(row);
      }
    }
    // Enforce services mirror cap (Phase 3).
    await _store.enforceServicesMirrorCap();
  }

  Future<void> _mergeHiringPostsDelta(
    List<Map<String, dynamic>> delta,
  ) async {
    for (final row in delta) {
      final id = row['id'] as String?;
      if (id == null) continue;

      final isDeleted = row['deleted_at'] != null;

      if (isDeleted) {
        await _store.deleteHiringPostMirror(id);
        await SearchIndexService.instance.removeEntity(id);
        if (kDebugMode) debugPrint('[MarketplaceRepo] Tombstoned hiring post $id');
      } else {
        await _store.upsertHiringPostMirror(id, jsonEncode(row));
        await SearchIndexService.instance.indexHiringPostJson(row);
      }
    }
    // Enforce hiring posts mirror cap (Phase 3).
    await _store.enforceHiringPostsMirrorCap();
  }

  // ── Seeding (first launch / cache miss) ──────────────────────────────────

  /// Seeds the Hive mirror from a full-page fetch result (e.g. from
  /// [SupabaseRepository.fetchListings]).  Used when the mirror is empty
  /// and a full load was already performed by [loadAllData].
  Future<void> seedListingsMirror(List<Listing> listings) async {
    if (listings.isNotEmpty) {
      final bytes = jsonEncode(
        listings.map((l) => l.toJson()).toList(),
      ).length;
      observability?.addBytesDownloaded(bytes);
    }
    for (final l in listings) {
      await _store.upsertListingMirror(l.id, jsonEncode(l.toJson()));
    }
    // Set cursor to earliest updated_at so the next delta only picks up new.
    final latest = listings.fold<DateTime?>(null, (prev, l) {
      final t = l.remoteUpdatedAt ?? l.localUpdatedAt;
      if (prev == null) return t;
      return t.isAfter(prev) ? t : prev;
    });
    if (latest != null) {
      await _store.setSyncCursor(_kListings, latest);
    }
  }

  Future<void> seedServicesMirror(List<Service> services) async {
    if (services.isNotEmpty) {
      final bytes = jsonEncode(
        services.map((s) => s.toJson()).toList(),
      ).length;
      observability?.addBytesDownloaded(bytes);
    }
    for (final s in services) {
      await _store.upsertServiceMirror(s.id, jsonEncode(s.toJson()));
    }
    final latest = services.fold<DateTime?>(null, (prev, s) {
      final t = s.remoteUpdatedAt ?? s.localUpdatedAt;
      if (prev == null) return t;
      return t.isAfter(prev) ? t : prev;
    });
    if (latest != null) {
      await _store.setSyncCursor(_kServices, latest);
    }
  }

  Future<void> seedHiringPostsMirror(List<HiringPost> posts) async {
    if (posts.isNotEmpty) {
      final bytes = jsonEncode(
        posts.map((p) => p.toJson()).toList(),
      ).length;
      observability?.addBytesDownloaded(bytes);
    }
    for (final p in posts) {
      await _store.upsertHiringPostMirror(p.id, jsonEncode(p.toJson()));
    }
    final latest = posts.fold<DateTime?>(null, (prev, p) {
      final t = p.remoteUpdatedAt ?? p.localUpdatedAt;
      if (prev == null) return t;
      return t.isAfter(prev) ? t : prev;
    });
    if (latest != null) {
      await _store.setSyncCursor(_kHiringPosts, latest);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _scheduleImagePrefetch(List<Map<String, dynamic>> rows) {
    final urls = <String>[];
    for (final row in rows) {
      final primary = row['image_url'] as String?;
      if (primary != null && primary.isNotEmpty) {
        urls.add(CloudinaryUrlBuilder.card(primary));
      }
      final gallery = row['image_urls'];
      if (gallery is List && gallery.isNotEmpty) {
        final first = gallery.first;
        if (first is String && first.isNotEmpty) {
          urls.add(CloudinaryUrlBuilder.card(first));
        }
      }
    }
    ImagePrefetchService.instance.scheduleCardImages(urls);
  }

  DateTime? _maxUpdatedAt(List<Map<String, dynamic>> rows) {
    DateTime? max;
    for (final row in rows) {
      final raw = row['updated_at'] as String?;
      if (raw == null) continue;
      final ts = DateTime.tryParse(raw)?.toUtc();
      if (ts == null) continue;
      if (max == null || ts.isAfter(max)) max = ts;
    }
    return max;
  }
}
