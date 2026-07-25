-- Migration: add fcm_token column to profiles
-- Stores the Firebase Cloud Messaging device token so the backend can send
-- targeted push notifications to individual users.

alter table profiles
  add column if not exists fcm_token text;

-- Index for quick lookup when broadcasting to a specific user.
create index if not exists idx_profiles_fcm_token
  on profiles (fcm_token)
  where fcm_token is not null;
