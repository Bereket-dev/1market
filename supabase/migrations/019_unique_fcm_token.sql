-- Migration 019: one FCM token belongs to one profile
--
-- Multiple profiles were keeping the same device token after account switches.
-- notify_nearby_users_on_listing() dedupes by fcm_token and skips the seller,
-- so nearby pushes went to a stale token on an old account while the live
-- device token sat on the seller — FCM returned UNREGISTERED and no push
-- appeared on the phone.
--
-- Fix:
--   1. Keep only the newest profile per token; null the rest.
--   2. On every fcm_token write, clear that token from other profiles.

-- ── One-time cleanup ─────────────────────────────────────────────────────────
-- Drop tokens that have not been refreshed recently — these are almost always
-- leftovers from reinstalls / account switches and cause silent FCM misses.
UPDATE public.profiles
SET fcm_token = NULL
WHERE fcm_token IS NOT NULL
  AND fcm_token <> ''
  AND (updated_at IS NULL OR updated_at < now() - interval '7 days');

-- If several profiles still share one token, keep only the newest owner.
UPDATE public.profiles AS p
SET fcm_token = NULL
WHERE p.fcm_token IS NOT NULL
  AND p.fcm_token <> ''
  AND p.id NOT IN (
    SELECT DISTINCT ON (fcm_token) id
    FROM public.profiles
    WHERE fcm_token IS NOT NULL AND fcm_token <> ''
    ORDER BY fcm_token, updated_at DESC NULLS LAST
  );

-- ── Enforce unique ownership going forward ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.ensure_unique_fcm_token()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.fcm_token IS NOT NULL AND NEW.fcm_token <> '' THEN
    UPDATE public.profiles
       SET fcm_token = NULL
     WHERE fcm_token = NEW.fcm_token
       AND id <> NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ensure_unique_fcm_token ON public.profiles;

CREATE TRIGGER trg_ensure_unique_fcm_token
  AFTER INSERT OR UPDATE OF fcm_token ON public.profiles
  FOR EACH ROW
  WHEN (NEW.fcm_token IS NOT NULL AND NEW.fcm_token <> '')
  EXECUTE FUNCTION public.ensure_unique_fcm_token();
