-- Migration 003: profile photo buckets + missing profile columns
--
-- Run this in the Supabase SQL editor or via `supabase db push`.
--
-- What this adds:
--   1. Two storage buckets: 'avatars' and 'banners' (public, 5 MB limit)
--   2. Storage RLS policies — each user can only read/write under their own
--      user-id prefix (e.g. <uid>/avatar.jpg).  Public SELECT is allowed so
--      avatar images are visible to other authenticated users.
--   3. Missing columns on public.profiles:
--        banner_url          text
--        onboarding_complete boolean not null default false

-- ── 1. Storage buckets ───────────────────────────────────────────────────────

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg','image/png','image/webp','image/gif']),
  ('banners', 'banners', true, 5242880, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update
  set file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ── 2. Storage RLS policies — avatars bucket ─────────────────────────────────

-- Any authenticated user can read any avatar (needed to show other users' avatars).
drop policy if exists "Avatars are publicly readable" on storage.objects;
create policy "Avatars are publicly readable"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'avatars');

-- A user can only upload/overwrite their own avatar (path starts with their uid).
drop policy if exists "Users can upload their own avatar" on storage.objects;
create policy "Users can upload their own avatar"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can update their own avatar" on storage.objects;
create policy "Users can update their own avatar"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can delete their own avatar" on storage.objects;
create policy "Users can delete their own avatar"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ── 3. Storage RLS policies — banners bucket ─────────────────────────────────

drop policy if exists "Banners are publicly readable" on storage.objects;
create policy "Banners are publicly readable"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'banners');

drop policy if exists "Users can upload their own banner" on storage.objects;
create policy "Users can upload their own banner"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'banners'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can update their own banner" on storage.objects;
create policy "Users can update their own banner"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'banners'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can delete their own banner" on storage.objects;
create policy "Users can delete their own banner"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'banners'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ── 4. Missing profile columns ───────────────────────────────────────────────

alter table public.profiles
  add column if not exists banner_url          text,
  add column if not exists onboarding_complete boolean not null default false;
