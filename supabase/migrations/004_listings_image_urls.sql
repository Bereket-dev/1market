-- Add image_urls array column to listings table.
-- This stores additional Cloudinary image URLs for a listing beyond the
-- primary image_url thumbnail. The first entry is used as the fallback
-- thumbnail when image_url is empty.

alter table public.listings
  add column if not exists image_urls text[] not null default '{}'::text[];
