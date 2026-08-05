-- Migration 018: make push webhook work without Vault secrets
--
-- Edge Function secrets (supabase secrets) ≠ Postgres Vault secrets.
-- notify_push_on_insert() was reading vault.decrypted_secrets for SUPABASE_URL
-- / SUPABASE_SERVICE_ROLE_KEY; those rows were never created, so the trigger
-- silently returned and never called the Edge Function — even though
-- app_notifications rows were inserted correctly.
--
-- Fix: call the project Edge Function URL directly. verify_jwt is disabled on
-- push-notification, so no service-role bearer is required for the HTTP hop.
-- The function still uses its own injected service role for FCM/profile lookup.

CREATE OR REPLACE FUNCTION public.notify_push_on_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _payload jsonb;
  _project_url text;
  _service_role_key text;
BEGIN
  -- Prefer Vault when configured; fall back to this project's public URL.
  SELECT decrypted_secret INTO _project_url
    FROM vault.decrypted_secrets WHERE name = 'SUPABASE_URL' LIMIT 1;

  SELECT decrypted_secret INTO _service_role_key
    FROM vault.decrypted_secrets WHERE name = 'SUPABASE_SERVICE_ROLE_KEY' LIMIT 1;

  IF _project_url IS NULL OR _project_url = '' THEN
    _project_url := 'https://hrjxoygflvxfensmclcl.supabase.co';
  END IF;

  _payload := jsonb_build_object(
    'type',   'INSERT',
    'table',  'app_notifications',
    'record', row_to_json(NEW)::jsonb
  );

  BEGIN
    PERFORM net.http_post(
      url     := _project_url || '/functions/v1/push-notification',
      body    := _payload,
      headers := CASE
        WHEN _service_role_key IS NOT NULL AND _service_role_key <> '' THEN
          jsonb_build_object(
            'Content-Type',  'application/json',
            'Authorization', 'Bearer ' || _service_role_key
          )
        ELSE
          jsonb_build_object(
            'Content-Type', 'application/json'
          )
      END
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'notify_push_on_insert failed: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$;
