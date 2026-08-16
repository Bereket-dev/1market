-- Migration 030: backfill default promo images
--
-- The original hardcoded carousel used Unsplash URLs. When promos moved to
-- `home_promos`, seed rows left `image_url` null (icon-only). Guests and
-- post-clear-data launches then showed gradient cards with no photos even
-- though anon SELECT already works.
--
-- Only fill rows that still have a null/empty image_url so admin overrides
-- are preserved.

update public.home_promos
set
  image_url = case slot
    when 1 then 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&w=600&q=80'
    when 2 then 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?auto=format&fit=crop&w=600&q=80'
    when 3 then 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=600&q=80'
    when 4 then 'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?auto=format&fit=crop&w=600&q=80'
    else image_url
  end,
  updated_at = now()
where coalesce(nullif(trim(image_url), ''), '') = '';
