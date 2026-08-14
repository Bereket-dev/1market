import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/errors/safe_parse.dart';
import '../models/hiring_post.dart';
import '../models/listing.dart';
import '../models/service.dart';
import 'image_prefetch_service.dart';
import 'offline/hive_sync_store.dart';
import 'supabase_repository.dart';

/// Phase 1: local-first marketplace data layer.
///
/// Responsibilities:
///   1. Read cached entities from Hive immediately (< 1 ms, no network).
///   2. Delta-sync changed/deleted rows from Supabase using an updated_at
///      cursor, merge results into Hive, advance the cursor.
///   3. Keep AppState lists up-to-date by returning the merged result.
///
/// The repository is a pure data helper — it has no ChangeNotifier and no
/// knowledge of UI state.  AppState calls into it and calls notifyListeners()
/// at the right moments.
class MarketplaceRepository {
  MarketplaceRepository({required SupabaseRepository supabaseRepo})
      : _remote = supabaseRepo;

  final SupabaseRepository _remote;
  final HiveSyncStore _store = HiveSyncStore.instance;

  // ── Entity names used as cursor keys ────────────────────────────────────
  static const _kListings    = 'listings';
  static const _kServices    = 'services';
  static const _kHiringPosts = 'hiring_posts';

  static const _kDeltaBatchSize = 100;

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

  // ── Delta sync ───────────────────────────────────────────────────────────

  /// Delta-syncs listings from Supabase using the stored cursor.
  ///
  /// Returns the merged list sorted by updated_at descending (newest first).
  /// Advances the cursor to the max updated_at seen in this batch.
  Future<List<Listing>> syncListingsDelta({
    required String? currentUserId,
    required Set<String> savedIds,
  }) async {
    await _store.setInProgressEntity(_kListings);
    var sessionFetched = _store.getRecordsFetchedThisSession(_kListings);
    var cursor = _store.getSyncCursor(_kListings);

    try {
      while (true) {
        final rows = await _remote.fetchListingsDeltaRaw(
          cursor: cursor,
          limit: _kDeltaBatchSize,
        );
        if (rows.isEmpty) break;

        await _mergeListingsDelta(rows);
        _scheduleImagePrefetch(rows);

        sessionFetched += rows.length;
        await _store.setRecordsFetchedThisSession(_kListings, sessionFetched);

        final maxUpdatedAt = _maxUpdatedAt(rows);
        if (maxUpdatedAt != null) {
          cursor = maxUpdatedAt;
          await _store.setSyncCursor(_kListings, maxUpdatedAt);
        }

        if (rows.length < _kDeltaBatchSize) break;
      }

      await _store.clearRecordsFetchedThisSession(_kListings);
      await _store.setInProgressEntity(null);
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
  Future<List<Service>> syncServicesDelta() async {
    await _store.setInProgressEntity(_kServices);
    var sessionFetched = _store.getRecordsFetchedThisSession(_kServices);
    var cursor = _store.getSyncCursor(_kServices);

    try {
      while (true) {
        final rows = await _remote.fetchServicesDeltaRaw(
          cursor: cursor,
          limit: _kDeltaBatchSize,
        );
        if (rows.isEmpty) break;

        await _mergeServicesDelta(rows);
        _scheduleImagePrefetch(rows);

        sessionFetched += rows.length;
        await _store.setRecordsFetchedThisSession(_kServices, sessionFetched);

        final maxUpdatedAt = _maxUpdatedAt(rows);
        if (maxUpdatedAt != null) {
          cursor = maxUpdatedAt;
          await _store.setSyncCursor(_kServices, maxUpdatedAt);
        }

        if (rows.length < _kDeltaBatchSize) break;
      }

      await _store.clearRecordsFetchedThisSession(_kServices);
      await _store.setInProgressEntity(null);
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
  Future<List<HiringPost>> syncHiringPostsDelta() async {
    await _store.setInProgressEntity(_kHiringPosts);
    var sessionFetched = _store.getRecordsFetchedThisSession(_kHiringPosts);
    var cursor = _store.getSyncCursor(_kHiringPosts);

    try {
      while (true) {
        final rows = await _remote.fetchHiringPostsDeltaRaw(
          cursor: cursor,
          limit: _kDeltaBatchSize,
        );
        if (rows.isEmpty) break;

        await _mergeHiringPostsDelta(rows);
        _scheduleImagePrefetch(rows);

        sessionFetched += rows.length;
        await _store.setRecordsFetchedThisSession(_kHiringPosts, sessionFetched);

        final maxUpdatedAt = _maxUpdatedAt(rows);
        if (maxUpdatedAt != null) {
          cursor = maxUpdatedAt;
          await _store.setSyncCursor(_kHiringPosts, maxUpdatedAt);
        }

        if (rows.length < _kDeltaBatchSize) break;
      }

      await _store.clearRecordsFetchedThisSession(_kHiringPosts);
      await _store.setInProgressEntity(null);
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

  // ── Merge logic ──────────────────────────────────────────────────────────

  /// Merge rules (applied to each row in [delta]):
  ///   • deleted_at IS NOT NULL  → remove from mirror.
  ///   • is_hidden == true       → remove from mirror (moderation).
  ///   • otherwise               → upsert (insert or overwrite) in mirror.
  Future<void> _mergeListingsDelta(List<Map<String, dynamic>> delta) async {
    for (final row in delta) {
      final id = row['id'] as String?;
      if (id == null) continue;

      final isDeleted = row['deleted_at'] != null;
      final isHidden  = row['is_hidden'] as bool? ?? false;

      if (isDeleted || isHidden) {
        await _store.deleteListingMirror(id);
        if (kDebugMode) debugPrint('[MarketplaceRepo] Tombstoned listing $id');
      } else {
        await _store.upsertListingMirror(id, jsonEncode(row));
      }
    }
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
        if (kDebugMode) debugPrint('[MarketplaceRepo] Tombstoned service $id');
      } else {
        await _store.upsertServiceMirror(id, jsonEncode(row));
      }
    }
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
        if (kDebugMode) debugPrint('[MarketplaceRepo] Tombstoned hiring post $id');
      } else {
        await _store.upsertHiringPostMirror(id, jsonEncode(row));
      }
    }
  }

  // ── Seeding (first launch / cache miss) ──────────────────────────────────

  /// Seeds the Hive mirror from a full-page fetch result (e.g. from
  /// [SupabaseRepository.fetchListings]).  Used when the mirror is empty
  /// and a full load was already performed by [loadAllData].
  Future<void> seedListingsMirror(List<Listing> listings) async {
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
      if (primary != null && primary.isNotEmpty) urls.add(primary);
      final gallery = row['image_urls'];
      if (gallery is List && gallery.isNotEmpty) {
        final first = gallery.first;
        if (first is String && first.isNotEmpty) urls.add(first);
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
