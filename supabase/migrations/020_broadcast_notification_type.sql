-- Migration 020: allow admin broadcast notification type
--
-- The koolan-admin site inserts app_notifications rows with type = 'broadcast'
-- when sending mass (or single-user admin) push notifications. Widen the CHECK
-- constraint so those inserts succeed and still fire the existing push webhook.

ALTER TABLE public.app_notifications
  DROP CONSTRAINT IF EXISTS app_notifications_type_check;

ALTER TABLE public.app_notifications
  ADD CONSTRAINT app_notifications_type_check
  CHECK (type IN (
    'new_application',
    'status_changed',
    'new_listing_nearby',
    'new_message',
    'broadcast'
  ));
