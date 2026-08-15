-- Migration 026: marketplace_changes change-log table + sync_version cursor
--
-- Purpose:
--   Phase 4 monotonic sync cursor.  Instead of relying on updated_at
--   timestamps (susceptible to clock skew and equal-timestamp races), every
--   INSERT / UPDATE / DELETE on listings, services, and hiring_posts appends
--   a row to marketplace_changes with a BIGSERIAL version.
--
--   Client cursor: SELECT * FROM marketplace_changes WHERE version > :cursor
--   ORDER BY version ASC LIMIT 500
--
--   The client advances its stored version to max(version) seen in the batch.
--   Clients that have no stored version fall back to the updated_at cursor
--   (Phase 1–3 behaviour) until they receive their first change-log batch.
--
-- get_changes_since(since_version bigint, row_limit int) RPC:
--   Returns the raw JSON payload for each changed entity so the client can
--   apply the same merge rules as the delta path without extra round-trips.
--
-- NOTE on hard deletes:
--   Moderation hard-deletes bypass this trigger.  They will not appear in
--   the change log — that is intentional (content should disappear instantly).
--   User soft-deletes set deleted_at and appear as UPDATE events with
--   operation = 'DELETE' in the change log.

-- ── Change-log table ─────────────────────────────────────────────────────────

create table if not exists public.marketplace_changes (
  version     bigserial primary key,
  entity_type text        not null, -- 'listing' | 'service' | 'hiring_post'
  entity_id   uuid        not null,
  operation   text        not null, -- 'INSERT' | 'UPDATE' | 'DELETE'
  changed_at  timestamptz not null default now()
);

-- Index for the client cursor query (version > :cursor ORDER BY version ASC).
create index if not exists idx_marketplace_changes_version
  on public.marketplace_changes (version asc);

-- Index for entity lookups (e.g. "has this entity been deleted?").
create index if not exists idx_marketplace_changes_entity
  on public.marketplace_changes (entity_type, entity_id);

-- Row-Level Security: allow anon/authed reads; only triggers write.
alter table public.marketplace_changes enable row level security;

drop policy if exists "marketplace_changes_read" on public.marketplace_changes;
create policy "marketplace_changes_read"
  on public.marketplace_changes
  for select
  using (true);

-- No insert/update/delete policy needed — only the trigger function (SECURITY
-- DEFINER) writes to this table.

-- ── Trigger function ─────────────────────────────────────────────────────────

create or replace function public.record_marketplace_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_operation text;
  v_entity_type text;
begin
  -- Map TG_OP to our operation codes.
  -- For UPDATE with deleted_at set we emit 'DELETE' so the client tombstones.
  if TG_OP = 'DELETE' then
    v_operation := 'DELETE';
  elsif TG_OP = 'UPDATE' and NEW.deleted_at is not null then
    v_operation := 'DELETE';
  elsif TG_OP = 'INSERT' then
    v_operation := 'INSERT';
  else
    v_operation := 'UPDATE';
  end if;

  -- Map table name to entity_type.
  v_entity_type := case TG_TABLE_NAME
    when 'listings'     then 'listing'
    when 'services'     then 'service'
    when 'hiring_posts' then 'hiring_post'
    else TG_TABLE_NAME
  end;

  insert into public.marketplace_changes (entity_type, entity_id, operation)
  values (
    v_entity_type,
    case TG_OP when 'DELETE' then OLD.id else NEW.id end,
    v_operation
  );

  return null; -- AFTER trigger; return value ignored
end;
$$;

-- ── Attach triggers ───────────────────────────────────────────────────────────

drop trigger if exists trg_listings_changes on public.listings;
create trigger trg_listings_changes
  after insert or update or delete
  on public.listings
  for each row
  execute function public.record_marketplace_change();

drop trigger if exists trg_services_changes on public.services;
create trigger trg_services_changes
  after insert or update or delete
  on public.services
  for each row
  execute function public.record_marketplace_change();

drop trigger if exists trg_hiring_posts_changes on public.hiring_posts;
create trigger trg_hiring_posts_changes
  after insert or update or delete
  on public.hiring_posts
  for each row
  execute function public.record_marketplace_change();

-- ── get_changes_since RPC ────────────────────────────────────────────────────
--
-- Returns a single JSON array with full entity payloads for every change-log
-- entry newer than since_version.  The client can deserialise with the same
-- merge rules as the existing delta path.
--
-- Each row:
--   { version, entity_type, entity_id, operation, changed_at,
--     payload: { ...entity columns } | null }
--
-- payload is null when the entity no longer exists (hard-deleted by admin).
-- The client treats null payload the same as deleted_at IS NOT NULL.

create or replace function public.get_changes_since(
  since_version bigint,
  row_limit     int default 500
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_changes jsonb;
begin
  select jsonb_agg(
    jsonb_build_object(
      'version',      mc.version,
      'entity_type',  mc.entity_type,
      'entity_id',    mc.entity_id,
      'operation',    mc.operation,
      'changed_at',   mc.changed_at,
      'payload',      case mc.entity_type
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
    )
    order by mc.version asc
  )
  into v_changes
  from public.marketplace_changes mc
  where mc.version > since_version
  order by mc.version asc
  limit row_limit;

  return coalesce(v_changes, '[]'::jsonb);
end;
$$;

-- Grant execute to anon and authenticated roles.
grant execute on function public.get_changes_since(bigint, int)
  to anon, authenticated;
