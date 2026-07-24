-- Add image_urls array to services and hiring_posts for multi-image carousel support.
-- image_url (singular) is kept as the primary thumbnail / cover image.
-- image_urls (plural) stores the full ordered list; the carousel merges both.

alter table public.services
  add column if not exists image_urls text[] not null default '{}'::text[];

alter table public.hiring_posts
  add column if not exists image_urls text[] not null default '{}'::text[];
