-- Migration 029: public read for marketplace feed (guest browsing)
--
-- The app supports browsing without sign-in. Listings / services / open hiring
-- posts / seller profile snippets must be readable by the anon role.
-- Hidden rows stay invisible. Own drafts/closed hiring posts remain
-- authenticated-only where applicable.

-- ── listings ────────────────────────────────────────────────────────────────

drop policy if exists "Listings are viewable by authenticated users" on public.listings;
drop policy if exists "Listings are publicly readable" on public.listings;
create policy "Listings are publicly readable"
  on public.listings for select
  to anon, authenticated
  using (coalesce(is_hidden, false) = false and deleted_at is null);

-- ── services ────────────────────────────────────────────────────────────────

drop policy if exists "Services are viewable by authenticated users" on public.services;
drop policy if exists "Services are publicly readable" on public.services;
create policy "Services are publicly readable"
  on public.services for select
  to anon, authenticated
  using (coalesce(is_hidden, false) = false and deleted_at is null);

-- ── hiring_posts ────────────────────────────────────────────────────────────
-- Open posts: public. Own posts (any status): owner only.

drop policy if exists "Open hiring posts viewable by authenticated users" on public.hiring_posts;
drop policy if exists "Hiring posts are publicly readable when open" on public.hiring_posts;
create policy "Hiring posts are publicly readable when open"
  on public.hiring_posts for select
  to anon, authenticated
  using (
    coalesce(is_hidden, false) = false
    and deleted_at is null
    and (
      status = 'open'
      or poster_id = auth.uid()
    )
  );

-- ── profiles ────────────────────────────────────────────────────────────────
-- Seller cards on listings need display_name / avatar / rating for guests.

drop policy if exists "Profiles are viewable by authenticated users" on public.profiles;
drop policy if exists "Profiles are publicly readable" on public.profiles;
create policy "Profiles are publicly readable"
  on public.profiles for select
  to anon, authenticated
  using (true);
