create table public.logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  game_id bigint not null references public.games (id) on delete cascade,
  rating smallint check (rating between 1 and 10), -- half-heart units: 1 = 0.5♥, 10 = 5♥
  review text,
  played_on date,
  status text not null default 'completed'
    check (status in ('playing', 'completed', 'backlog', 'abandoned')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index logs_user_id_idx on public.logs (user_id);
create index logs_game_id_idx on public.logs (game_id);
create index logs_created_at_idx on public.logs (created_at desc);

create function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger logs_set_updated_at
  before update on public.logs
  for each row execute function public.set_updated_at();

alter table public.logs enable row level security;

create policy "Logs are publicly readable"
  on public.logs for select
  using (true);

create policy "Users can insert their own logs"
  on public.logs for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own logs"
  on public.logs for update
  using (auth.uid() = user_id);

create policy "Users can delete their own logs"
  on public.logs for delete
  using (auth.uid() = user_id);
