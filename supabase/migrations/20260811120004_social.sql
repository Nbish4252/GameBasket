create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  following_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

alter table public.follows enable row level security;

create policy "Follows are publicly readable"
  on public.follows for select
  using (true);

create policy "Users can follow as themselves"
  on public.follows for insert
  with check (auth.uid() = follower_id);

create policy "Users can unfollow as themselves"
  on public.follows for delete
  using (auth.uid() = follower_id);

create table public.log_likes (
  log_id uuid not null references public.logs (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (log_id, user_id)
);

alter table public.log_likes enable row level security;

create policy "Likes are publicly readable"
  on public.log_likes for select
  using (true);

create policy "Users can like as themselves"
  on public.log_likes for insert
  with check (auth.uid() = user_id);

create policy "Users can unlike as themselves"
  on public.log_likes for delete
  using (auth.uid() = user_id);
