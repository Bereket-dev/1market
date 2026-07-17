-- Koolan Supabase schema: profiles, listings, favorites, chat, reports + RLS

-- ── Profiles ────────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_url text,
  bio text,
  phone text,
  city text,
  language text check (language in ('en', 'am', 'so')),
  preferred_category text,
  rating numeric not null default 5.0,
  reviews_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Profiles are viewable by authenticated users" on public.profiles;
create policy "Profiles are viewable by authenticated users"
  on public.profiles for select
  to authenticated
  using (true);

drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Users can insert their own profile"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── Listings ──────────────────────────────────────────────────────────────────
create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid references public.profiles (id) on delete set null,
  category text not null check (category in ('CARS', 'HOUSES', 'LAND', 'SKILLS')),
  title text not null,
  price text not null,
  image_url text not null,
  location text not null,
  verified boolean not null default false,
  condition_or_status text not null,
  seller_name text not null,
  seller_image text not null default '',
  seller_rating numeric not null default 4.8,
  seller_reviews_count int not null default 12,
  description text not null default '',
  spec1_label text,
  spec1_value text,
  spec2_label text,
  spec2_value text,
  spec3_label text,
  spec3_value text,
  spec4_label text,
  spec4_value text,
  created_at timestamptz not null default now()
);

alter table public.listings enable row level security;

drop policy if exists "Listings are viewable by authenticated users" on public.listings;
create policy "Listings are viewable by authenticated users"
  on public.listings for select
  to authenticated
  using (true);

drop policy if exists "Users can insert their own listings" on public.listings;
create policy "Users can insert their own listings"
  on public.listings for insert
  to authenticated
  with check (auth.uid() = seller_id);

drop policy if exists "Users can update their own listings" on public.listings;
create policy "Users can update their own listings"
  on public.listings for update
  to authenticated
  using (auth.uid() = seller_id)
  with check (auth.uid() = seller_id);

drop policy if exists "Users can delete their own listings" on public.listings;
create policy "Users can delete their own listings"
  on public.listings for delete
  to authenticated
  using (auth.uid() = seller_id);

-- ── Favorites ─────────────────────────────────────────────────────────────────
create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  listing_id uuid not null references public.listings (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, listing_id)
);

alter table public.favorites enable row level security;

drop policy if exists "Users can view their own favorites" on public.favorites;
create policy "Users can view their own favorites"
  on public.favorites for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own favorites" on public.favorites;
create policy "Users can insert their own favorites"
  on public.favorites for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own favorites" on public.favorites;
create policy "Users can delete their own favorites"
  on public.favorites for delete
  to authenticated
  using (auth.uid() = user_id);

-- ── Chat threads ──────────────────────────────────────────────────────────────
create table if not exists public.chat_threads (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references public.listings (id) on delete set null,
  buyer_id uuid not null references public.profiles (id) on delete cascade,
  seller_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (listing_id, buyer_id)
);

alter table public.chat_threads enable row level security;

drop policy if exists "Participants can view their threads" on public.chat_threads;
create policy "Participants can view their threads"
  on public.chat_threads for select
  to authenticated
  using (auth.uid() = buyer_id or auth.uid() = seller_id);

drop policy if exists "Buyers can create threads" on public.chat_threads;
create policy "Buyers can create threads"
  on public.chat_threads for insert
  to authenticated
  with check (auth.uid() = buyer_id);

-- ── Chat messages ─────────────────────────────────────────────────────────────
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.chat_threads (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);

alter table public.chat_messages enable row level security;

drop policy if exists "Participants can view messages in their threads" on public.chat_messages;
create policy "Participants can view messages in their threads"
  on public.chat_messages for select
  to authenticated
  using (
    exists (
      select 1 from public.chat_threads t
      where t.id = thread_id
        and (t.buyer_id = auth.uid() or t.seller_id = auth.uid())
    )
  );

drop policy if exists "Participants can send messages in their threads" on public.chat_messages;
create policy "Participants can send messages in their threads"
  on public.chat_messages for insert
  to authenticated
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.chat_threads t
      where t.id = thread_id
        and (t.buyer_id = auth.uid() or t.seller_id = auth.uid())
    )
  );

-- ── Reports ───────────────────────────────────────────────────────────────────
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  listing_id uuid references public.listings (id) on delete set null,
  reported_user_id uuid references public.profiles (id) on delete set null,
  reason text not null,
  details text,
  created_at timestamptz not null default now()
);

alter table public.reports enable row level security;

drop policy if exists "Users can view their own reports" on public.reports;
create policy "Users can view their own reports"
  on public.reports for select
  to authenticated
  using (auth.uid() = reporter_id);

drop policy if exists "Users can submit reports" on public.reports;
create policy "Users can submit reports"
  on public.reports for insert
  to authenticated
  with check (auth.uid() = reporter_id);

-- ── Demo seed data (run once after migration) ─────────────────────────────────
insert into public.listings (
  category, title, price, image_url, location, verified, condition_or_status,
  seller_name, seller_image, seller_rating, seller_reviews_count, description,
  spec1_label, spec1_value, spec2_label, spec2_value, spec3_label, spec3_value,
  spec4_label, spec4_value
) values
  ('LAND', 'Residential Plot in Kebele 02', 'ETB 4,200,000',
   'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=500&q=80',
   'Kebele 02, Jigjiga, Somali Region', true, 'For Sale', 'Ahmed Mohammed',
   'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
   4.9, 124, 'A wide residential land plot in Kebele 02, perfect for family homes.',
   'Size', '1000 sqm', 'Land Use', 'Residential', 'Title Deed', 'Available', 'Road Access', 'Yes (12m)'),
  ('LAND', 'Agricultural Plot in Tuli-Guled', '$28,500',
   'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=500&q=80',
   'Tuli-Guled, Fafan', false, 'For Sale', 'Ahmed Nur',
   'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
   4.8, 31, 'Fertile agricultural land in the Fafan zone.',
   'Size', '2.5 hectares', 'Land Use', 'Agricultural', 'Title Deed', 'Pending', 'Road Access', 'Yes'),
  ('CARS', '2022 Toyota Land Cruiser Prado', '$42,500',
   'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=500&q=80',
   'Downtown, Jigjiga', true, 'For Sale', 'Ahmed Nur',
   'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
   4.9, 124, 'Mint condition luxury SUV, fully loaded.',
   'Year', '2022', 'Mileage', '12,400 km', 'Transmission', 'Automatic', 'Fuel Type', 'Petrol'),
  ('CARS', '2021 Toyota Hilux 2.8 GD-6 Raider', '$42,500',
   'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=500&q=80',
   'Jigjiga Central, Somali Region', true, 'Good Condition', 'Ahmed Nur',
   'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
   4.9, 124, 'Well-maintained Hilux with full service history.',
   'Year', '2021', 'Mileage', '45,000 km', 'Transmission', 'Automatic', 'Fuel Type', 'Diesel'),
  ('HOUSES', 'Modern 4-Bedroom Villa', '$145,000',
   'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=500&q=80',
   'Kebele 04, Jigjiga', true, 'For Sale', 'Ahmed Abdullahi',
   'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
   4.8, 124, 'Ultra-modern villa with private courtyard.',
   'Bedrooms', '4 Bed', 'Bathrooms', '3 Bath', 'Area', '350 m²', 'Security', '24/7'),
  ('SKILLS', 'Hodan Ahmed', 'Unlock for 30 ETB',
   'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=500&q=80',
   'Kebele 03, Jigjiga', true, 'Available', 'Hodan Ahmed',
   'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80',
   5.0, 48, 'Professional housekeeper and plumber.',
   'Category', 'House Help', 'Experience', '2 years', 'Skills', 'Cleaning, Cooking', 'Verified', 'Koolan Verified')
on conflict do nothing;
