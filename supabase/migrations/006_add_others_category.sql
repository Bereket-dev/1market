-- Migration: add 'OTHERS' to the listings category check constraint.
--
-- Strategy: PostgreSQL does not support ALTER CONSTRAINT. We must drop the
-- old constraint and add a new one. This is safe because no existing rows
-- have category='OTHERS', so no data is lost or invalidated.

alter table public.listings
  drop constraint if exists listings_category_check;

alter table public.listings
  add constraint listings_category_check
    check (category in ('CARS', 'HOUSES', 'LAND', 'SKILLS', 'OTHERS'));
