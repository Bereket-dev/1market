-- Migration 031: delete_own_account RPC for Play Store account-deletion
--
-- Google Play requires apps that create accounts to let users delete them
-- from within the app. This security-definer function:
--   1. Soft-deletes the caller's marketplace content (tombstones for sync)
--   2. Clears PII on the profile row
--   3. Deletes the auth.users row (profiles cascade via ON DELETE CASCADE)
--
-- Call from the client as:  await client.rpc('delete_own_account');

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Soft-delete marketplace content so other clients tombstone via delta sync.
  update public.listings
    set deleted_at = now(), updated_at = now()
    where seller_id = uid and deleted_at is null;

  update public.services
    set deleted_at = now(), updated_at = now()
    where owner_id = uid and deleted_at is null;

  update public.hiring_posts
    set deleted_at = now(), updated_at = now()
    where poster_id = uid and deleted_at is null;

  -- Scrub PII before auth delete (cascade removes the row; this covers
  -- any brief window where the profile still exists).
  update public.profiles
    set
      display_name = 'Deleted user',
      avatar_url = null,
      bio = null,
      phone = null,
      fcm_token = null,
      updated_at = now()
    where id = uid;

  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;

comment on function public.delete_own_account() is
  'Lets the signed-in user permanently delete their account and soft-delete their listings/services/jobs.';
