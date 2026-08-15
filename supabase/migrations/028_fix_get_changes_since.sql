-- Migration 028: fix get_changes_since aggregate / ORDER BY
--
-- Postgres rejects:
--   SELECT jsonb_agg(...) ORDER BY mc.version LIMIT n
-- because mc.version is neither grouped nor aggregated at the outer level.
--
-- Fix: limit+order in a subquery, then jsonb_agg over that subset.

create or replace function public.get_changes_since(
  since_version bigint,
  row_limit     int default 500
)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(change_row order by version asc),
    '[]'::jsonb
  )
  from (
    select
      mc.version,
      jsonb_build_object(
        'version',     mc.version,
        'entity_type', mc.entity_type,
        'entity_id',   mc.entity_id,
        'operation',   mc.operation,
        'changed_at',  mc.changed_at,
        'payload',     case mc.entity_type
          when 'listing' then (
            select row_to_json(l)::jsonb
            from public.listings l
            where l.id = mc.entity_id
            limit 1
          )
          when 'service' then (
            select row_to_json(s)::jsonb
            from public.services s
            where s.id = mc.entity_id
            limit 1
          )
          when 'hiring_post' then (
            select row_to_json(h)::jsonb
            from public.hiring_posts h
            where h.id = mc.entity_id
            limit 1
          )
          else null
        end
      ) as change_row
    from public.marketplace_changes mc
    where mc.version > since_version
    order by mc.version asc
    limit greatest(row_limit, 1)
  ) capped;
$$;

grant execute on function public.get_changes_since(bigint, int)
  to anon, authenticated;
