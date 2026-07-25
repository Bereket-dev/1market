-- Performance indexes for all hot query paths.
-- Every foreign key and filter column that appears in a SELECT without an
-- existing index gets one here.  All use IF NOT EXISTS so this is safe to
-- re-run and safe to apply on top of the existing schema.

-- ── services ─────────────────────────────────────────────────────────────────
-- fetchReviewsForUser step-1: SELECT id FROM services WHERE owner_id = ?
create index if not exists idx_services_owner_id
  on public.services (owner_id);

-- ── listings ──────────────────────────────────────────────────────────────────
-- fetchListings join: profiles!seller_id(...)
create index if not exists idx_listings_seller_id
  on public.listings (seller_id);

-- ── chat_threads ──────────────────────────────────────────────────────────────
-- fetchChatSessions: OR filter on buyer_id / seller_id
create index if not exists idx_chat_threads_buyer_id
  on public.chat_threads (buyer_id);

create index if not exists idx_chat_threads_seller_id
  on public.chat_threads (seller_id);

-- getOrCreateThread: WHERE listing_id = ? AND buyer_id = ?
create index if not exists idx_chat_threads_listing_buyer
  on public.chat_threads (listing_id, buyer_id);

-- ── chat_messages ─────────────────────────────────────────────────────────────
-- Embedded join in fetchChatSessions: chat_messages WHERE thread_id = ?
-- Also used in active_chat_screen real-time subscription.
create index if not exists idx_chat_messages_thread_id
  on public.chat_messages (thread_id);

-- ── applications ──────────────────────────────────────────────────────────────
-- Applicant view: WHERE applicant_id = ?
create index if not exists idx_applications_applicant_id
  on public.applications (applicant_id);

-- Poster view: WHERE hiring_post_id = ?
create index if not exists idx_applications_hiring_post_id
  on public.applications (hiring_post_id);

-- ── app_notifications ─────────────────────────────────────────────────────────
-- fetchNotifications: WHERE user_id = ? ORDER BY created_at DESC
create index if not exists idx_app_notifications_user_id
  on public.app_notifications (user_id, created_at desc);

-- ── hiring_posts ─────────────────────────────────────────────────────────────
-- Browse: WHERE status = 'open' ORDER BY created_at DESC
create index if not exists idx_hiring_posts_status_created
  on public.hiring_posts (status, created_at desc);

-- My posts: WHERE poster_id = ?
create index if not exists idx_hiring_posts_poster_id
  on public.hiring_posts (poster_id);

-- ── favorites ─────────────────────────────────────────────────────────────────
-- fetchFavoriteIds: WHERE user_id = ?
create index if not exists idx_favorites_user_id
  on public.favorites (user_id);
