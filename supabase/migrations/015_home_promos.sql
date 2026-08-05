-- ── Home Promo Cards ──────────────────────────────────────────────────────────
-- Admin-manageable carousel cards shown on the home screen.
-- Flutter app reads via anon/authenticated SELECT (RLS below).
-- Admin website writes via service_role (bypasses RLS entirely).
--
-- Image hosting: upload to Cloudinary (or a public Supabase `promos` bucket)
-- and store the public HTTPS URL in image_url. null = icon-only card (same as
-- the current hardcoded behaviour).

create table public.home_promos (
  slot        int         primary key check (slot between 1 and 4),
  headline    text        not null,
  subtitle    text        not null default '',
  image_url   text,                          -- nullable; null = icon-only
  theme       text        not null default 'navy'
                check (theme in ('navy', 'teal', 'purple', 'red')),
  is_active   boolean     not null default true,
  updated_at  timestamptz not null default now()
);

-- ── Seed: mirror the current hardcoded English copy ───────────────────────────
insert into public.home_promos (slot, headline, subtitle, theme) values
  (1, 'Jigjiga''s #1 Marketplace',  'Buy, sell, and hire in your city — all in one place.',       'navy'),
  (2, 'Trusted & Verified Sellers', 'Browse real listings from people in your community.',        'teal'),
  (3, 'Post a Listing in 60 Seconds','Cars, houses, land or skills — post for free today.',       'purple'),
  (4, 'Find Top Local Services',     'Hire skilled workers near you — updated daily.',            'red');

-- ── RLS ───────────────────────────────────────────────────────────────────────
alter table public.home_promos enable row level security;

-- Public read: anon and authenticated users see active slots only.
create policy "home_promos_select"
  on public.home_promos
  for select
  to anon, authenticated
  using (is_active = true);

-- No INSERT / UPDATE / DELETE policies for client roles.
-- Admin site uses service_role which bypasses RLS.
