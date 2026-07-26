-- Migration 014: fix nearby listing notification
--
-- Two fixes:
--   1. Deduplicate by FCM token — if multiple profiles share the same device
--      token (e.g. test accounts on the same handset), only one notification
--      is sent per physical device.
--   2. Include the listing image URL in the payload so the Edge Function can
--      attach it to the FCM push (shown as a big picture on Android / iOS).
--
-- Also widens the app_notifications.type CHECK constraint to include the
-- new types used by migration 013 (in case the DB is being applied fresh).

-- ── Widen the type constraint ─────────────────────────────────────────────────
ALTER TABLE public.app_notifications
  DROP CONSTRAINT IF EXISTS app_notifications_type_check;

ALTER TABLE public.app_notifications
  ADD CONSTRAINT app_notifications_type_check
  CHECK (type IN (
    'new_application',
    'status_changed',
    'new_listing_nearby',
    'new_message'
  ));

-- ── Trigger function: notify on new listing (deduped + with image) ────────────
CREATE OR REPLACE FUNCTION public.notify_nearby_users_on_listing()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r RECORD;
  _image_url text;
BEGIN
  -- Pick the best available image: prefer first item in image_urls array,
  -- fall back to the legacy image_url column.
  _image_url := COALESCE(
    NULLIF(NEW.image_urls[1], ''),
    NULLIF(NEW.image_url, ''),
    ''
  );

  -- Insert one notification per distinct FCM token (not per profile).
  -- DISTINCT ON (fcm_token) ensures that if several test/secondary accounts
  -- share the same physical device token, only the first profile row wins —
  -- preventing duplicate pushes on a single handset.
  FOR r IN
    SELECT DISTINCT ON (fcm_token) id
    FROM profiles
    WHERE fcm_token IS NOT NULL
      AND fcm_token <> ''
      AND id <> NEW.seller_id
    ORDER BY fcm_token, created_at  -- deterministic tie-break
  LOOP
    INSERT INTO app_notifications (user_id, type, title, body, payload)
    VALUES (
      r.id,
      'new_listing_nearby',
      'New listing nearby',
      NEW.title,
      jsonb_build_object(
        'screen',    'listing_detail',
        'listingId', NEW.id,
        'imageUrl',  _image_url
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$;

-- Re-attach the trigger (idempotent).
DROP TRIGGER IF EXISTS trg_notify_nearby_on_listing_insert ON public.listings;
CREATE TRIGGER trg_notify_nearby_on_listing_insert
  AFTER INSERT ON public.listings
  FOR EACH ROW EXECUTE FUNCTION public.notify_nearby_users_on_listing();
