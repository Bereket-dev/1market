-- Add fayda_verified column to profiles to track Fayda identity verification status
alter table public.profiles
  add column if not exists fayda_verified boolean not null default false;

-- Add onboarding_complete column if it doesn't exist (for older instances)
alter table public.profiles
  add column if not exists onboarding_complete boolean not null default false;
