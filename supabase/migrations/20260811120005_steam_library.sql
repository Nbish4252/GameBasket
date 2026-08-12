create table public.steam_library (
  user_id uuid not null references public.profiles (id) on delete cascade,
  steam_app_id integer not null,
  playtime_minutes integer not null default 0,
  last_synced_at timestamptz not null default now(),
  primary key (user_id, steam_app_id)
);

alter table public.steam_library enable row level security;

create policy "Users can read their own steam library"
  on public.steam_library for select
  using (auth.uid() = user_id);

-- No insert/update policy: only the steam-sync Edge Function (service
-- role) writes here. Playtime data defaults to private, unlike logs.
