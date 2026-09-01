-- Migration 034: use a dedicated secret for push webhook authentication
CREATE OR REPLACE FUNCTION public.notify_push_on_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  _payload jsonb;
  _project_url text;
  _webhook_secret text;
BEGIN
  SELECT decrypted_secret INTO _project_url FROM vault.decrypted_secrets WHERE name = 'SUPABASE_URL' LIMIT 1;
  SELECT decrypted_secret INTO _webhook_secret FROM vault.decrypted_secrets WHERE name = 'PUSH_WEBHOOK_SECRET' LIMIT 1;
  IF COALESCE(_project_url, '' ) = '' OR COALESCE(_webhook_secret, '' ) = '' THEN
    RAISE WARNING 'Push notification webhook skipped: Vault secrets are missing';
    RETURN NEW;
  END IF;
  _payload := jsonb_build_object(
    'type', 'INSERT', 
    'table', 'app_notifications',
    'record', row_to_json(NEW)::jsonb
  );
  BEGIN
    PERFORM net.http_post(
      url := _project_url || '/functions/v1/push-notification', 
      body := _payload,
      headers := jsonb_build_object(
        'Content-Type', 'application/json', 
        'Authorization', 'Bearer ' || _webhook_secret
      )
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'notify_push_on_insert failed: %', SQLERRM;
  END;
  RETURN NEW;
END;
$fn$;
DROP TRIGGER IF EXISTS trg_push_on_notification_insert ON public.app_notifications;
CREATE TRIGGER trg_push_on_notification_insert AFTER INSERT ON public.app_notifications FOR EACH ROW EXECUTE FUNCTION public.notify_push_on_insert();
