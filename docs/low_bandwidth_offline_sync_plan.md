# Koolan — Low-Bandwidth & Offline-First Implementation Plan

**Scope:** Flutter Android app targeting Jijiga, Dire Dawa, and broader Ethiopia.  
**Goal:** Make Koolan feel fast and reliable on slow, unstable, and metered mobile networks — not merely “work offline sometimes.”  
**Principle:** Optimize the full path — database → API → JSON → sync → local storage → search → images → UI → user actions.

---

## Executive summary

The recommendations in the original analysis are sound. Koolan already has useful foundations (Hive write queues, image disk cache, pagination, optimistic favorites, profile/listings fallback cache), but the **dominant UX path is still network-first**: opening the marketplace waits on Supabase before showing content.

The highest-impact shift is **local-first rendering with background cloud reconciliation** — show Hive/SharedPreferences data immediately, sync deltas in the background, update only changed cards.

This document maps all 26 recommendations to Koolan’s current codebase, identifies gaps, and defines a phased implementation plan with concrete targets, file touchpoints, and acceptance criteria.

---

## Current state audit

| Area | Today | Gap |
|------|--------|-----|
| **Startup data load** | `loadAllData()` sets `isLoadingData = true`, fetches from Supabase, then renders (`app_state_data.dart`) | Not local-first; users see skeleton/spinner on slow networks |
| **Local cache** | `LocalStorage` (SharedPreferences) stores listings/services JSON; profile cache on init failure | Cache only used **after** network failure, not on every open |
| **Hive read mirror** | `HiveSyncStore` has `_listingsCacheBox`, `_profileCacheBox` | Underused; write queues dominate Hive usage |
| **Outbound sync** | `SyncService` + durable Hive queues for listings, profile, services, chat, hiring, applications | Good foundation; inbound pull sync missing |
| **Conflict handling** | LWW via `updated_at` comparison (2s tolerance) | Works for writes; no monotonic server cursor |
| **Retry policy** | 5s → 15s → 60s backoff in `_retryWithBackoff` | No jitter; failed entries marked `failed` with no `FAILED_REQUIRES_ATTENTION` UX |
| **Connectivity** | Binary online/offline via `connectivity_plus` | No GOOD / LIMITED / POOR quality modes |
| **List queries** | `fetchListings()` uses `select('*, profiles!seller_id(...)')` | Heavy payload for cards; no list vs detail split |
| **Delta sync** | None — full page fetch (`kPageSize = 30`) ordered by `created_at` | Every refresh re-downloads up to 30 full rows |
| **Deletes / tombstones** | Soft hide via `is_hidden`; enqueue uses `deleted_at` in payload for some entities | No `deleted_at` column or tombstone pull sync |
| **Images** | `CachedImageWidget` + `KoolanImageCacheManager` (90d, 2000 files) | Single URL per image; cards may load full-size originals |
| **Search** | In-memory filter over `allListings` via `searchQuery` | No local search index; no background server merge |
| **Chat sync** | Loaded inside `loadAllData()` for signed-in users | Should lazy-load on chat tab entry |
| **Optimistic UI** | Favorites already optimistic (`toggleSaveListing`) | Other actions (follow, profile edits) partially queued but not uniformly optimistic |
| **Architecture** | `KoolanAppState` → `SupabaseRepository` + `SyncService` | No dedicated inbound `SyncEngine`; logic spread across AppState parts |
| **Observability** | Debug `debugPrint` only | No `SyncStatus`, bandwidth telemetry, or “Updated X min ago” indicator |
| **Data Saver** | Not implemented | Settings has no low-data mode |

**Key files today:**

```text
lib/shared/services/app_state.dart
lib/shared/services/parts/app_state_data.dart      ← loadAllData, cache fallback
lib/shared/services/parts/app_state_init.dart      ← init + profile cache
lib/shared/services/offline/sync_service.dart      ← outbound queue only
lib/shared/services/offline/hive_sync_store.dart   ← Hive boxes
lib/shared/services/local_storage.dart             ← SharedPreferences cache
lib/shared/services/supabase_repository.dart       ← fetchListings (heavy select)
lib/shared/widgets/cached_image_widget.dart        ← image disk cache
```

---

## Recommendation analysis (mapped to Koolan)

### 1. Local-first UX, cloud-authoritative

**Verdict:** Highest priority. Adopt fully.

**Current:** Network-first with offline fallback.  
**Target flow:**

```text
Open app → read local mirror → show marketplace immediately
         → check network quality → delta sync → merge → patch affected UI
```

**Koolan-specific:** Unify cache reads through one `LocalMarketplaceRepository` instead of splitting between `LocalStorage` and unused Hive listing boxes.

---

### 2. Dedicated Sync Engine

**Verdict:** Adopt incrementally. Do not big-bang refactor AppState.

**Current:** `SyncService` handles **outbound** writes only. Inbound fetch lives in `loadAllData()`.  
**Target:**

```text
lib/shared/services/sync/
├── sync_engine.dart
├── sync_metadata.dart
├── parts/
│   ├── listing_sync.dart
│   ├── service_sync.dart
│   ├── hiring_sync.dart
│   ├── notification_sync.dart
│   ├── chat_sync.dart
│   └── profile_sync.dart
```

`SyncEngine` orchestrates priority-ordered pull sync. `SyncService` remains the outbound write flusher (or merges into `SyncEngine` in Phase 2).

---

### 3. Monotonic cursor (`sync_version`)

**Verdict:** Phase 4 (scale). Start with `updated_at` + tombstones.

**Current:** `updated_at` everywhere in schema (`001_schema.sql`).  
**Risk with timestamps:** clock skew, equal timestamps, missed rows. Acceptable for Phase 1 delta if queries use `>= cursor` with tie-breaker (`id`).

**Future migration:** Postgres sequence or `BIGSERIAL sync_version` on a central change log (see #4).

---

### 4. Server-side change log

**Verdict:** Phase 4. Best long-term design for multi-entity sync.

**Proposed table:**

```sql
create table public.marketplace_changes (
  version     bigserial primary key,
  entity_type text not null,  -- listing | service | hiring_post | ...
  entity_id   uuid not null,
  operation   text not null,  -- INSERT | UPDATE | DELETE
  created_at  timestamptz not null default now()
);
```

**Trigger-based** append on listings/services/hiring_posts changes. Client: `GET changes WHERE version > :cursor LIMIT 500`.

Until then: per-table delta queries with `updated_at` + `deleted_at IS NULL` filters.

---

### 5. Aggressive image optimization

**Verdict:** Phase 1 — critical for Ethiopia.

**Current:** Cloudinary uploads exist; delivery URLs appear to use originals.  
**Target sizes:**

| Context | Transform | Target size |
|---------|-----------|-------------|
| Marketplace card | `w_320,h_240,c_fill,q_auto:low,f_auto` | 30–80 KB |
| List row / compact | `w_240` | 20–50 KB |
| Detail hero | `w_800` | 120–250 KB |
| Full-screen viewer | `w_1280` | 250–500 KB |

**Implementation:**

- Store `public_id` in DB; build transform URLs client-side via `CloudinaryUrlBuilder`.
- Migrate existing `image_url` / `image_urls` gradually (dual-read: transform if public_id present, else legacy URL).
- Card widgets (`car_card.dart`, `service_card`, hiring tiles) must never request original URLs.

---

### 6. Local-first search

**Verdict:** Phase 3.

**Current:** `setSearchQuery` filters `allListings` in memory — fine for hundreds of rows, degrades at scale.  
**Target:** Lightweight inverted index in Hive (`search_index` box: `token → [entityId]`). Optional server search merges new results when online.

---

### 7. Stale-while-revalidate (SWR)

**Verdict:** Phase 1 — core UX pattern.

Show cached price/availability immediately; background sync updates individual cards when cloud differs. Pair with “Updated 3 min ago” indicator (#20).

---

### 8. Prioritized sync on app open

**Verdict:** Phase 1–2.

| Priority | Entities | When |
|----------|----------|------|
| P1 | Listings, services, hiring (first page + delta) | App open / foreground |
| P2 | Favorites, own profile, unread counts | After P1 completes |
| P3 | Notifications | Background / pull-to-refresh |
| P4 | Home promos, analytics | Lazy / TTL cache |
| Lazy | Chat threads + messages | On chat tab / thread open only |

**Change:** Remove `fetchChatSessions()` from `loadAllData()`; add `ChatSync.syncOnTabEnter()`.

---

### 9. Network-quality modes

**Verdict:** Phase 3.

```text
GOOD     → normal images, prefetch next page
LIMITED  → thumbnails, delta only, no prefetch
POOR     → metadata sync only; images on tap
OFFLINE  → Hive + outbound queue
```

**Signals:** `connectivity_plus` + recent request latency / failure rate (rolling window in `NetworkMonitor`).

---

### 10. Data Saver mode

**Verdict:** Phase 3. User-facing toggle in Settings.

When enabled: thumbnails only, no prefetch, longer sync interval, chat media tap-to-download, skip promo media. Persist in `LocalStorage` / profile.

---

### 11. Separate metadata from media

**Verdict:** Phase 1 architecture rule.

Sync pipeline must never `await` image downloads. Metadata sync completes independently; `ImagePrefetchService` schedules downloads by priority and network mode.

---

### 12. Resumable sync

**Verdict:** Phase 2.

Persist in `SyncMetadata`:

```text
last_listings_cursor
last_services_cursor
in_progress_entity
records_fetched_this_session
```

On connection drop, resume from cursor — do not re-fetch page 0.

---

### 13. Compression & selective fields

**Verdict:** Phase 1–2.

- Supabase/PostgREST already supports gzip when client sends `Accept-Encoding: gzip` (verify on device).
- Replace `select('*')` with list projections (see #14).
- Add Supabase RPC or views for card-optimized rows if joins remain heavy.

---

### 14. List vs detail queries

**Verdict:** Phase 1.

**List projection (listings):**

```dart
'id, category, title, price, image_url, location, condition_or_status,
 seller_id, updated_at, is_hidden,
 profiles!seller_id(display_name, avatar_url, rating)'
```

**Detail fetch:** full row + gallery + specs + seller phone on demand.

Add `fetchListingById(id)` if not present; detail screens call it when local copy is stale or incomplete.

---

### 15. Optimistic UI for user actions

**Verdict:** Partially done — extend.

| Action | Status | Next step |
|--------|--------|-----------|
| Favorite | ✅ Optimistic | Queue retry on failure instead of immediate revert |
| Profile edit | ✅ Hive queue | Surface pending state in UI |
| Chat send | ✅ Pending messages box | Already queued |
| Create listing | ✅ Draft queue | Show “Syncing…” badge |
| Follow / save service | ❌ | Add optimistic + queue |

---

### 16. Durable Sync Queue

**Verdict:** Mostly done — harden.

Hive boxes survive restart. Gaps:

- Unify queue entry schema (`attempt_count`, `next_attempt`, `status`, `error`).
- Favorites not in queue today — add `SyncEntityType.favorite`.

---

### 17. Exponential backoff with jitter

**Verdict:** Phase 2.

Extend `_retryWithBackoff` delays to `10s → 30s → 1m → 5m → 15m` with random jitter ±20%. Persist `next_attempt` per entry so sync pass skips entries not yet due.

---

### 18. Stop retrying forever

**Verdict:** Phase 2.

After N attempts (e.g. 8), set `status = failed_requires_attention`. Settings → “Sync issues” shows failed ops with retry/discard actions.

---

### 19. Sync observability

**Verdict:** Phase 2 (debug panel); Phase 3 (Crashlytics custom keys).

```dart
class SyncStatus {
  DateTime? lastSuccessfulSync;
  DateTime? lastAttempt;
  int pendingOperations;
  int failedOperations;
  int bytesDownloaded;
  int bytesUploaded;
  Duration? lastSyncDuration;
}
```

Expose in dev menu; log aggregates in debug builds.

---

### 20. “Last updated” indicator

**Verdict:** Phase 1 UI polish.

Reuse existing offline strings in `app_strings.dart` (`errorOfflineCached`). Add banner: “Updated 3 min ago” / “Offline · showing saved listings” in `app_shell.dart` or home header.

Store `lastSuccessfulSyncAt` in `SyncMetadata`.

---

### 21. Freshness by category

**Verdict:** Phase 2–3.

| Data | TTL / strategy |
|------|----------------|
| Listings / services / hiring | Continuous delta |
| Price / availability | High priority in delta |
| Profile (self) | 6h or on edit |
| Categories / app config | 7d |
| Home promos | 4h |
| Static help | 30d |

Implement via per-entity `lastFetchedAt` in `SyncMetadata`; skip network if within TTL unless user pull-to-refresh.

---

### 22. Reduce AppState responsibility

**Verdict:** Incremental — Phase 2–4.

```text
UI → KoolanAppState (thin) → MarketplaceRepository → SyncEngine → Hive
```

Move fetch/merge logic out of `app_state_data.dart` into repository + sync parts. AppState holds UI-facing lists and delegates refresh to repository streams/notifiers.

**Do not** migrate to Riverpod in the same phase — minimize churn.

---

### 23. SQLite / Drift later

**Verdict:** Phase 4 only if local row count > ~10k or search/filter CPU becomes measurable.

Hive remains correct for Phase 1–3. Trigger: marketplace open latency or search lag on mid-range Android devices in Ethiopia.

---

### 24. Cache eviction

**Verdict:** Phase 3–4.

Policies:

- Keep: favorites, recently viewed, own listings, current region, last 7 days viewed.
- Evict: unseen listings older than 30d, expired hiring posts, orphaned image cache entries.
- Cap: e.g. 50 MB metadata + 200 MB images (tunable).

`HiveSyncStore._enforceImageCacheLimit()` already exists — extend with listing record caps.

---

### 25. Regional caching

**Verdict:** Phase 4 (when multi-city expansion is active).

Priority sync for user’s `location` / preferred region (Jijiga first). Secondary fetch for nearby woredas. Low priority for distant regions — fetch on explicit filter change only.

---

### 26. Bandwidth telemetry

**Verdict:** Phase 2 (debug); Phase 4 (production sampling).

Wrap Supabase HTTP client or repository layer to count request/response bytes. Log in debug:

```text
Initial sync:     target < 2 MB
Normal refresh:   target < 100 KB
No-change delta:  target < 10 KB
Card thumbnail:   target < 80 KB
```

---

## Target architecture

```text
                 ┌─────────────────────┐
                 │         UI          │
                 │  (screens/widgets)  │
                 └──────────┬──────────┘
                            │
                 ┌──────────▼──────────┐
                 │   KoolanAppState    │  ← thin: lists, filters, navigation
                 └──────────┬──────────┘
                            │
                 ┌──────────▼──────────┐
                 │ MarketplaceRepository│  ← read local, trigger sync
                 └──────────┬──────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
     ┌────────▼────────┐         ┌────────▼────────┐
     │  HiveSyncStore  │         │   SyncEngine    │
     │  (local mirror) │◄────────│  pull + merge   │
     └────────┬────────┘         └────────┬────────┘
              │                           │
              │                  ┌──────▼──────┐
              │                  │ SyncService │  ← outbound queue (existing)
              │                  └──────┬──────┘
              │                           │
              └─────────────┬─────────────┘
                            │
                   ┌────────▼────────┐
                   │ NetworkMonitor  │
                   │ GOOD/LIMITED/…  │
                   └────────┬────────┘
                            │
                   ┌────────▼────────┐
                   │    Supabase     │
                   │  (+ change log  │
                   │   in Phase 4)   │
                   └────────┬────────┘
                            │
                   ┌────────▼────────┐
                   │   Cloudinary    │
                   │  sized delivery │
                   └─────────────────┘
```

---

## Phased implementation plan

### Phase 1 — Biggest immediate UX wins (2–3 weeks)

**Objective:** User never waits on network to see the marketplace.

#### 1.1 Local-first boot path

- [ ] Add `MarketplaceRepository` with `loadFromLocal()` and `refreshInBackground()`.
- [ ] Change `loadAllData()`:
  1. Read listings/services/hiring from Hive (migrate from SharedPreferences gradually).
  2. `notifyListeners()` immediately — **do not** set `isLoadingData = true` when local data exists.
  3. Set `isRefreshing = true` (new flag) for subtle background indicator.
  4. Run delta/full fetch; merge; `notifyListeners()` with surgical list updates.
- [ ] Wire home screen to show content when `allListings.isNotEmpty` even if `isRefreshing`.

**Files:** `app_state_data.dart`, new `marketplace_repository.dart`, `hive_sync_store.dart`

#### 1.2 Consolidate local mirror in Hive

- [ ] Move listings/services/hiring cache from `LocalStorage` → `HiveSyncStore` keyed boxes (per-entity or chunked pages).
- [ ] Store `SyncMetadata`: `lastSyncAt`, cursors per entity type.
- [ ] One-time migration: on first launch after update, copy SharedPreferences cache into Hive.

#### 1.3 Delta pull sync (timestamp cursor)

- [ ] Migration: add `deleted_at timestamptz` to `listings`, `services`, `hiring_posts` (soft delete for sync; keep `is_hidden` for moderation).
- [ ] Repository methods:

```sql
-- listings delta
WHERE (updated_at > :cursor OR deleted_at > :cursor)
ORDER BY updated_at ASC
LIMIT 100
```

- [ ] Client merge rules:
  - Upsert changed rows into Hive.
  - Remove rows where `deleted_at IS NOT NULL` or `is_hidden = true`.
  - Advance cursor to max `updated_at` seen.

#### 1.4 List vs detail queries

- [ ] Add `fetchListingSummaries()` with narrow `select(...)`.
- [ ] Detail screens fetch full listing on open if needed.
- [ ] Apply same pattern to services and hiring posts.

#### 1.5 Image thumbnails for cards

- [ ] Add `lib/shared/services/cloudinary_url_builder.dart` with size presets.
- [ ] Update card widgets to use thumbnail URLs.
- [ ] Upload pipeline: request eager transformations or store `public_id`.

#### 1.6 Stale-while-revalidate UI

- [ ] Add “Updated X min ago” / offline banner component.
- [ ] Patch individual list items on merge instead of replacing entire `allListings`.

**Phase 1 acceptance criteria:**

- Cold open with cached data: marketplace visible in **< 300 ms** (no full-screen spinner).
- Normal refresh on unchanged data: **< 100 KB** JSON downloaded (measure in debug).
- Listing card image: **< 80 KB** on LIMITED network mode (manual test).
- Deleted/hidden listing disappears after delta sync without full reload.

---

### Phase 2 — Reliability & outbound hardening (2–3 weeks)

**Objective:** Writes and sync survive bad networks; user trust in pending state.

#### 2.1 Sync queue schema upgrade

- [ ] Extend `SyncQueueEntry` with `attemptCount`, `lastAttempt`, `nextAttempt`, `lastError`.
- [ ] Add favorite toggle to outbound queue.
- [ ] On favorite failure: revert UI **only** after max retries, not first error.

#### 2.2 Backoff + failure cap

- [ ] Replace fixed retry with exponential backoff + jitter.
- [ ] Status `failed_requires_attention` after 8 attempts.
- [ ] Settings screen: “Pending sync” section listing failed operations.

#### 2.3 Resumable inbound sync

- [ ] Persist partial pagination cursor when sync interrupted.
- [ ] Resume on reconnect (hook into existing `SyncService` connectivity listener).

#### 2.4 Prioritized sync scheduler

- [ ] P1 listings/services/hiring → P2 favorites/profile → P3 notifications.
- [ ] Remove chat from app-open sync; lazy load on chat entry.

#### 2.5 Sync observability (debug)

- [ ] Implement `SyncStatus` model; dev-only overlay or settings debug section.
- [ ] Track bytes up/down per session.

#### 2.6 Metadata/media decoupling

- [ ] Extract `ImagePrefetchService` — never block `SyncEngine` on images.

**Phase 2 acceptance criteria:**

- Airplane mode → favorite → kill app → reopen → still queued → syncs when online.
- Failed sync after 8 tries surfaces user-visible “needs attention” state.
- Chat open does not block marketplace load (measurable via startup trace).

---

### Phase 3 — Advanced low-bandwidth UX (2–4 weeks)

**Objective:** Adapt behavior to network quality and user data preferences.

#### 3.1 NetworkMonitor

- [ ] Classify GOOD / LIMITED / POOR / OFFLINE.
- [ ] Feed into sync frequency, image quality, prefetch gates.

#### 3.2 Data Saver setting

- [ ] Toggle in `settings_screen.dart`.
- [ ] When on: thumbnails only, no prefetch, longer sync interval, tap-to-load chat media.

#### 3.3 Freshness TTLs

- [ ] Per-entity TTL in `SyncMetadata`; skip redundant fetches.

#### 3.4 Local search index

- [ ] Token index in Hive for title/location/category search.
- [ ] Optional background server search merge when GOOD network.

#### 3.5 Cache eviction

- [ ] Max listing count / max disk MB; LRU eviction for non-favorites.

#### 3.6 HTTP compression verification

- [ ] Confirm gzip/br on Supabase responses from Android client.
- [ ] Audit all repository `select()` calls for field bloat.

**Phase 3 acceptance criteria:**

- Data Saver reduces first-screen bytes by **≥ 50%** vs normal mode (debug telemetry).
- Search returns results in **< 50 ms** for 5k local listings.
- POOR mode: marketplace loads with zero image bytes until scroll settles.

---

### Phase 4 — Scale & server-side evolution (ongoing)

**Objective:** Robust multi-entity sync at 10k+ local rows and multi-region rollout.

#### 4.1 Server change log + `sync_version`

- [ ] `marketplace_changes` table + triggers on listings/services/hiring_posts/favorites.
- [ ] Edge Function or RPC: `get_changes_since(version)`.
- [ ] Client migrates from `updated_at` cursor to monotonic version.

#### 4.2 Regional priority sync

- [ ] Index/list filter by user region; tiered prefetch for Jijiga → Dire Dawa → other.

#### 4.3 SQLite / Drift evaluation

- [ ] Benchmark Hive full-scan search vs Drift indexed queries at 10k/50k rows.
- [ ] Migrate only if profiling proves need.

#### 4.4 Production bandwidth sampling

- [ ] Anonymous aggregate metrics (Crashlytics custom keys or PostHog-style events).
- [ ] Alerts if p95 refresh exceeds targets.

---

## Database migrations (summary)

| Migration | Purpose | Phase |
|-----------|---------|-------|
| `0xx_add_deleted_at.sql` | Tombstone sync for listings/services/hiring | 1 |
| `0xx_list_summary_view.sql` | Optional view for card-optimized rows | 1 |
| `0xx_marketplace_changes.sql` | Change log + triggers | 4 |
| `0xx_sync_version_seq.sql` | Monotonic version if not using change log PK | 4 |

**Phase 1 `deleted_at` example:**

```sql
alter table public.listings
  add column if not exists deleted_at timestamptz;

create index if not exists idx_listings_updated_at
  on public.listings (updated_at asc)
  where deleted_at is null and is_hidden = false;
```

Replace hard `DELETE` in app with `UPDATE deleted_at = now()` where soft-delete is appropriate (keep hard delete for admin/moderation if required).

---

## Bandwidth & performance targets

| Scenario | Target | Measurement |
|----------|--------|-------------|
| Cold open (cached) | UI visible < 300 ms | Flutter timeline / manual |
| Initial sync (empty cache) | < 2 MB total | Debug telemetry |
| Normal refresh (changes exist) | < 100 KB JSON | Repository byte counter |
| No-change delta | < 10 KB | Empty delta response |
| Marketplace card image | 30–80 KB | Network inspector |
| Listing detail (first paint) | Metadata < 50 KB; hero image < 250 KB | Screen trace |
| Search (local) | < 50 ms for 5k rows | Dart benchmark |

---

## Testing plan

### Manual (Ethiopia-realistic)

- [ ] Throttle network to 2G / 128 kbps — marketplace still opens instantly from cache.
- [ ] Toggle airplane mode mid-sync — resume without duplicate rows.
- [ ] Kill app with pending favorite — survives restart and syncs.
- [ ] Data Saver on — confirm no full-size images on feed.
- [ ] Price change on server — card updates in place with “Updated just now”.

### Automated

- [ ] Unit tests: merge logic (upsert, tombstone, cursor advance).
- [ ] Unit tests: backoff schedule + jitter bounds.
- [ ] Widget test: home shows cached listings without spinner when `isLoadingData == false`.
- [ ] Integration test: offline favorite queued in Hive box.

---

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Dual cache (SharedPreferences + Hive) during migration | One-time migration + deprecate SharedPreferences listing cache in Phase 1 |
| `updated_at` missed updates | Use `>= cursor` with id tie-break; move to change log in Phase 4 |
| AppState refactor scope creep | Repository extraction only; no state-management framework change |
| Cloudinary transform breakage on legacy URLs | Dual-read: transform when `public_id` present, else legacy URL |
| Increased local storage use | Eviction policy in Phase 3; cap image cache (already 2000 files) |

---

## Priority order (quick reference)

```text
Phase 1 — Immediate impact
  1. Local-first rendering (Hive mirror)
  2. Stale-while-revalidate + last-updated UI
  3. Delta sync (updated_at + deleted_at)
  4. List vs detail queries
  5. Image thumbnails on cards
  6. Pagination (already exists — wire into delta)

Phase 2 — Reliability
  7. Durable queue hardening (attempt metadata)
  8. Backoff + jitter + failure cap
  9. Resumable sync
  10. Prioritized sync + lazy chat
  11. Sync observability (debug)

Phase 3 — Low-bandwidth UX
  12. Network quality modes
  13. Data Saver setting
  14. Compression + field audit
  15. Lazy media prefetch
  16. Local search index
  17. Cache eviction

Phase 4 — Scale
  18. marketplace_changes + sync_version
  19. Regional caching
  20. SQLite/Drift if needed
  21. Production bandwidth telemetry
```

---

## Relationship to other docs

- **`exception_handling_release_plan.md`** — error surfaces, Crashlytics, safe offline queue behavior (already partially done).
- **`release_prep_plan.md`** — cold start, branding, l10n; local-first boot reduces perceived cold-start latency.
- This plan focuses on **ongoing sync architecture** and **Ethiopia network conditions**, not store listing polish.

---

## Key idea (unchanged, still correct)

> Don't optimize only database synchronization.  
> Optimize the entire path: **database → API → JSON → sync → local storage → search → images → UI → user actions.**

That is what makes Koolan genuinely good in low-connectivity environments — not simply smaller Supabase requests.
