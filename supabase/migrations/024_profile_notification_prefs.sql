-- Migration 024: per-user notification preferences on profiles
--
-- notif_messages_enabled is synced from the app settings toggle so the
-- push-notification Edge Function can skip new_message pushes when off.
-- notif_push_enabled mirrors the master toggle for server-side checks.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS notif_push_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS notif_messages_enabled boolean NOT NULL DEFAULT true;
