-- Migration 022: Soft-hide content for moderation
-- Adds is_hidden to listings, services, hiring_posts.
-- Admin moderation sets is_hidden = true instead of hard-deleting rows,
-- so content is preserved for auditing but invisible to all users (including owner).
-- Flutter app and API must filter WHERE is_hidden = false on all public queries.

-- ── New columns ────────────────────────────────────────────────────────────────

alter table public.listings
  add column if not exists is_hidden boolean not null default false;

alter table public.services
  add column if not exists is_hidden boolean not null default false;

alter table public.hiring_posts
  add column if not exists is_hidden boolean not null default false;

-- ── Partial indexes (keep visible-content queries fast) ───────────────────────

create index if not exists idx_listings_visible
  on public.listings (id) where is_hidden = false;

create index if not exists idx_services_visible
  on public.services (id) where is_hidden = false;

create index if not exists idx_hiring_posts_visible
  on public.hiring_posts (id) where is_hidden = false;

-- ── RLS hint ──────────────────────────────────────────────────────────────────
-- Add `and is_hidden = false` to the USING clause of your SELECT policies
-- on listings, services, and hiring_posts so hidden rows are invisible to
-- authenticated users. The admin service role bypasses RLS and can still
-- read/update hidden rows.
