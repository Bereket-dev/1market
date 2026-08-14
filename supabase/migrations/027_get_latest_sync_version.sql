-- Migration 027: get_latest_sync_version RPC
--
-- Returns coalesce(max(version), 0) from marketplace_changes so clients can
-- bootstrap the version cursor to the server high-water mark WITHOUT replaying
-- the full change-log payload history (cold seed / updated_at already filled
-- the local mirror).

create or replace function public.get_latest_sync_version()
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(max(version), 0)::bigint from public.marketplace_changes;
$$;

grant execute on function public.get_latest_sync_version()
  to anon, authenticated;
