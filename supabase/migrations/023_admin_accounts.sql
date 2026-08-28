-- Migration 023: Admin accounts table
-- Stores admin users with roles and permissions for the 1market admin portal.
-- super_admin is seeded from env at server startup; all other admins are created
-- through the admin portal by the super_admin.

create table if not exists public.admin_accounts (
  id           uuid primary key default gen_random_uuid(),
  email        text not null unique,
  password_hash text not null,
  role         text not null default 'admin'
                 check (role in ('super_admin', 'admin')),
  -- Granular permission flags (super_admin always has all)
  perm_users         boolean not null default true,
  perm_listings      boolean not null default true,
  perm_services      boolean not null default true,
  perm_hiring        boolean not null default true,
  perm_reports       boolean not null default true,
  perm_chat          boolean not null default false,
  perm_notifications boolean not null default false,
  perm_promos        boolean not null default false,
  is_active    boolean not null default true,
  created_by   uuid references public.admin_accounts(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- Only the server (service role) reads/writes this table — no RLS needed for
-- public users, but enable RLS and deny all to be safe.
alter table public.admin_accounts enable row level security;

-- Service role bypasses RLS so the admin server can still read/write.
-- No policies = no access for anon/authenticated roles.

create index if not exists idx_admin_accounts_email    on public.admin_accounts(email);
create index if not exists idx_admin_accounts_role     on public.admin_accounts(role);
create index if not exists idx_admin_accounts_active   on public.admin_accounts(is_active);
