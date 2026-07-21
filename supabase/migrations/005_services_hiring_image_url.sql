-- Add image_url column to services and hiring_posts tables.
-- A single cover image URL stored in Cloudinary.

alter table public.services
  add column if not exists image_url text not null default '';

alter table public.hiring_posts
  add column if not exists image_url text not null default '';
