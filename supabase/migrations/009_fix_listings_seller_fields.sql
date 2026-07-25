-- Migration 009: fix listings schema alignment with the Flutter app
--
-- Issues fixed:
--   1. seller_name was NOT NULL with no default value, but createListing()
--      does not write it (seller info is read from the joined profiles row).
--      Adding a default of '' prevents insert failures on new listings.
--
--   2. seller_phone column did not exist. Listing.fromJson() falls back to
--      json['seller_phone'] when the joined profiles row has no phone, and
--      the column is referenced in the Listing model's toJson(). Adding it
--      as a nullable text column with no default keeps old rows intact.

-- 1. Give seller_name a safe empty-string default so inserts that omit it
--    (all new listings via createListing) do not fail the NOT NULL check.
alter table public.listings
  alter column seller_name set default '';

-- 2. Add seller_phone for denormalized storage / offline cache round-trips.
alter table public.listings
  add column if not exists seller_phone text;
