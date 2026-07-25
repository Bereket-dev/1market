-- Speed up reviews lookup on the service detail screen.
-- Without this index every fetchReviewsForService does a full table scan.

create index if not exists idx_service_reviews_service_id
  on public.service_reviews (service_id);

-- Secondary index so the upsert duplicate check on (service_id, reviewer_id) is fast.
create unique index if not exists idx_service_reviews_service_reviewer
  on public.service_reviews (service_id, reviewer_id);
