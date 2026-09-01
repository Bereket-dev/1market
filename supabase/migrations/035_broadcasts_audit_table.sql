-- Migration 035: broadcasts audit table
-- Stores one row per admin-initiated broadcast for history/reporting.

CREATE TABLE IF NOT EXISTS public.broadcasts (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title       text NOT NULL,
  body        text NOT NULL,
  payload     jsonb NOT NULL DEFAULT '{}',
  audience    text NOT NULL DEFAULT 'all_fcm',
  sent_count  integer NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Only admins (service role) can insert/read broadcasts.
ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service role full access"
  ON public.broadcasts
  USING (true)
  WITH CHECK (true);
