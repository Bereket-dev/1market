-- Add translation columns to listings table
-- These columns support multi-language listings (en / am / so).

alter table public.listings
  add column if not exists original_language text not null default 'en',
  add column if not exists title_translations jsonb not null default '{}'::jsonb,
  add column if not exists description_translations jsonb not null default '{}'::jsonb,
  add column if not exists updated_at timestamptz not null default now();
