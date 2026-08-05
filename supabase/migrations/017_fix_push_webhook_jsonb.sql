-- Migration 017: fix push-notification webhook jsonb type error
--
-- Bug: notify_push_on_insert() called http_post with body := _payload::text,
-- but pg_net's http_post requires body jsonb. Posting a listing inserts into
-- app_notifications (via nearby-listing trigger), which fires this webhook and
-- aborted the whole listing INSERT with a Postgres jsonb type exception.
--
-- Also:
--   - Call net.http_post (pg_net's schema on hosted Supabase), not extensions.
--   - Swallow webhook failures so a bad URL/secret never blocks notifications
--     or listing creation.

CREATE OR REPLACE FUNCTION public.notify_push_on_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _payload jsonb;
  _service_role_key text;
  _project_url text;
BEGIN
  SELECT decrypted_secret INTO _project_url
    FROM vault.decrypted_secrets WHERE name = 'SUPABASE_URL' LIMIT 1;

  SELECT decrypted_secret INTO _service_role_key
    FROM vault.decrypted_secrets WHERE name = 'SUPABASE_SERVICE_ROLE_KEY' LIMIT 1;

  -- Missing secrets: skip push rather than fail the INSERT.
  IF _project_url IS NULL OR _service_role_key IS NULL THEN
    RETURN NEW;
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
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || _service_role_key
      )
    );
  EXCEPTION WHEN OTHERS THEN
    -- Never fail the notification (or listing) insert because of push delivery.
    RAISE WARNING 'notify_push_on_insert failed: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$;
