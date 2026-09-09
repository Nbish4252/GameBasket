-- Comments on a log/review — the piece of the review-detail screen that
-- needed real schema, not just a new query. Scoped to what was actually
-- asked for this pass: post + list + count, no edit and no delete policy
-- yet (nothing in the UI needs them right now; trivial to add later).
create table public.log_comments (
  id uuid primary key default gen_random_uuid(),
  log_id uuid not null references public.logs (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create index log_comments_log_id_idx on public.log_comments (log_id);

alter table public.log_comments enable row level security;

create policy "Comments are publicly readable"
  on public.log_comments for select
  using (true);

create policy "Users can comment as themselves"
  on public.log_comments for insert
  with check (auth.uid() = user_id);
