-- Migration 013: notify users on new listing and new chat message
--
-- NOTE: The profiles table does not have latitude/longitude columns, so the
-- nearby filter is omitted. All users with an FCM token (except the poster)
-- receive the notification. Add earth_distance filtering once location columns
-- are added to profiles.

-- ── Trigger: notify users when a new listing is posted ───────────────────────
CREATE OR REPLACE FUNCTION public.notify_nearby_users_on_listing()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r RECORD;
BEGIN
  -- Insert notifications for all users who have an FCM token
  -- and are not the poster themselves.
  FOR r IN
    SELECT id
    FROM profiles
    WHERE fcm_token IS NOT NULL
      AND fcm_token <> ''
      AND id <> NEW.seller_id
  LOOP
    INSERT INTO app_notifications (user_id, type, title, body, payload)
    VALUES (
      r.id,
      'new_listing_nearby',
      'New listing nearby',
      NEW.title,
      jsonb_build_object(
        'screen',    'listing_detail',
        'listingId', NEW.id
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_nearby_on_listing_insert ON public.listings;
CREATE TRIGGER trg_notify_nearby_on_listing_insert
  AFTER INSERT ON public.listings
  FOR EACH ROW EXECUTE FUNCTION public.notify_nearby_users_on_listing();

-- ── Trigger: notify the other participant when a chat message is sent ─────────
CREATE OR REPLACE FUNCTION public.notify_on_new_message()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _recipient_id uuid;
  _thread RECORD;
BEGIN
  -- Get the thread to find the other participant.
  SELECT buyer_id, seller_id INTO _thread
  FROM chat_threads WHERE id = NEW.thread_id;

  IF _thread IS NULL THEN RETURN NEW; END IF;

  -- Recipient is the other person.
  IF NEW.sender_id = _thread.buyer_id THEN
    _recipient_id := _thread.seller_id;
  ELSE
    _recipient_id := _thread.buyer_id;
  END IF;

  INSERT INTO app_notifications (user_id, type, title, body, payload)
  VALUES (
    _recipient_id,
    'new_message',
    'New message',
    NEW.text,
    jsonb_build_object(
      'screen',   'chat',
      'threadId', NEW.thread_id
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_new_message ON public.chat_messages;
CREATE TRIGGER trg_notify_on_new_message
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION public.notify_on_new_message();
