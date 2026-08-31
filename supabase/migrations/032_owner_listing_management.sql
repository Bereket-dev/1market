-- Allow owners to manage their own unavailable listings.
-- Public and other users still see only available, non-deleted listings.

drop policy if exists "Listings are publicly readable" on public.listings;
create policy "Listings are publicly readable"
  on public.listings for select
  to anon, authenticated
  using (
    auth.uid() = seller_id
    or (coalesce(is_hidden, false) = false and deleted_at is null)
  );

create index if not exists idx_listings_owner_management
  on public.listings (seller_id, created_at desc)
