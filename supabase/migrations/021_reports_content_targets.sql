-- Migration 021: Widen reports table to support service and hiring-post targets
-- Adds: service_id, hiring_post_id, target_type, status
-- Keeps: existing listing_id, reported_user_id, reason, details, reporter_id

-- ── New columns ────────────────────────────────────────────────────────────────

alter table public.reports
  add column if not exists service_id uuid
    references public.services (id) on delete set null,

  add column if not exists hiring_post_id uuid
    references public.hiring_posts (id) on delete set null,

  -- target_type lets admin filter reports by content type without joining
  add column if not exists target_type text
    check (target_type in ('listing', 'service', 'hiring_post', 'user')),

  -- status tracks moderation lifecycle
  add column if not exists status text not null default 'pending'
    check (status in ('pending', 'dismissed', 'actioned'));

-- ── At-least-one-target constraint ────────────────────────────────────────────
-- Ensures every report is attached to something (listing, service, hiring post
-- or a user). Prevents empty/orphan rows.

alter table public.reports
  drop constraint if exists reports_has_target,
  add constraint reports_has_target check (
    listing_id      is not null or
    service_id      is not null or
    hiring_post_id  is not null or
    reported_user_id is not null
  );

-- ── Anti-spam uniqueness: one open (pending) report per reporter+target ────────
-- We use a partial unique index so the same user cannot flood the queue with
-- duplicate pending reports for the same target.

drop index if exists reports_unique_pending_listing;
create unique index reports_unique_pending_listing
  on public.reports (reporter_id, listing_id)
  where listing_id is not null and status = 'pending';

drop index if exists reports_unique_pending_service;
create unique index reports_unique_pending_service
  on public.reports (reporter_id, service_id)
  where service_id is not null and status = 'pending';

drop index if exists reports_unique_pending_hiring;
create unique index reports_unique_pending_hiring
  on public.reports (reporter_id, hiring_post_id)
  where hiring_post_id is not null and status = 'pending';

-- ── Indexes for admin filter queries ──────────────────────────────────────────

create index if not exists reports_target_type_idx  on public.reports (target_type);
create index if not exists reports_status_idx        on public.reports (status);
create index if not exists reports_service_id_idx    on public.reports (service_id)    where service_id    is not null;
create index if not exists reports_hiring_post_id_idx on public.reports (hiring_post_id) where hiring_post_id is not null;

-- ── Existing RLS policies remain unchanged ────────────────────────────────────
-- "Users can view their own reports"  (auth.uid() = reporter_id)
-- "Users can submit reports"          (auth.uid() = reporter_id)
-- Admin reads via service role (bypasses RLS) — no change needed.
