-- Migration: 012_push_notification_webhook.sql
--
-- Creates a Postgres webhook (via pg_net + supabase_functions) that fires
-- the push-notification Edge Function whenever a row is inserted into
-- app_notifications. This is what actually delivers the push to the device.
--
-- The Edge Function URL uses the internal Supabase project URL so it works
-- without exposing the function publicly.

-- Enable the http extension (already available on Supabase hosted plans).
create extension if not exists pg_net with schema extensions;

-- ── Webhook function ──────────────────────────────────────────────────────────

create or replace function public.notify_push_on_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  _payload jsonb;
  _service_role_key text;
  _project_url text;
begin
  -- Build the webhook payload — matches what the Edge Function expects.
  _payload := jsonb_build_object(
    'type',   'INSERT',
    'table',  'app_notifications',
    'record', row_to_json(NEW)::jsonb
  );

  -- Read project URL and service key from vault (set once via Supabase dashboard
  -- or `supabase secrets set`). Vault keeps secrets out of migration source.
  select decrypted_secret into _project_url
    from vault.decrypted_secrets where name = 'SUPABASE_URL' limit 1;

  select decrypted_secret into _service_role_key
    from vault.decrypted_secrets where name = 'SUPABASE_SERVICE_ROLE_KEY' limit 1;

  -- Fire-and-forget HTTP POST to the Edge Function.
  perform extensions.http_post(
    url     := _project_url || '/functions/v1/push-notification',
    body    := _payload::text,
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || _service_role_key
    )
  );

  return NEW;
end;
$$;

-- ── Attach trigger ────────────────────────────────────────────────────────────

drop trigger if exists trg_push_on_notification_insert on public.app_notifications;

create trigger trg_push_on_notification_insert
  after insert on public.app_notifications
  for each row
  execute function public.notify_push_on_insert();
