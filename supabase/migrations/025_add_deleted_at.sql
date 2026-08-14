-- Migration 025: add deleted_at tombstone for delta sync
--
-- Purpose:
--   Phase 1 delta sync uses an updated_at cursor.  Hard-deleted rows
--   disappear silently — clients that loaded the row before deletion will
--   never learn to remove it.  Adding deleted_at lets the delta query
--   surface tombstones:
--
--     WHERE updated_at > :cursor OR deleted_at > :cursor
--
--   The client then removes any row where deleted_at IS NOT NULL or
--   is_hidden = true.
--
--   NOTE: This migration only adds the column and index.  The application
--   still issues hard DELETEs for admin/moderation.  For user-initiated
--   deletes the app should set deleted_at = now() instead so clients
--   learn about the removal via the delta cursor.
--   (Moderation hard-deletes are fine — content should disappear instantly
--    rather than lingering in client caches.)

-- ── listings ────────────────────────────────────────────────────────────────

alter table public.listings
  add column if not exists deleted_at timestamptz;

-- Index for the delta query: rows changed or soft-deleted since cursor.
create index if not exists idx_listings_delta
  on public.listings (updated_at asc, id asc);

-- Separate index for tombstone sweeps.
create index if not exists idx_listings_deleted_at
  on public.listings (deleted_at asc)
  where deleted_at is not null;

-- ── services ─────────────────────────────────────────────────────────────────

alter table public.services
  add column if not exists deleted_at timestamptz;

create index if not exists idx_services_delta
  on public.services (updated_at asc, id asc);

create index if not exists idx_services_deleted_at
  on public.services (deleted_at asc)
  where deleted_at is not null;

-- ── hiring_posts ─────────────────────────────────────────────────────────────

alter table public.hiring_posts
  add column if not exists deleted_at timestamptz;

create index if not exists idx_hiring_posts_delta
  on public.hiring_posts (updated_at asc, id asc);

create index if not exists idx_hiring_posts_deleted_at
  on public.hiring_posts (deleted_at asc)
  where deleted_at is not null;
