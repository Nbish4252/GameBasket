create extension if not exists pg_trgm;

create table public.games (
  id bigint primary key, -- reuses the IGDB game id directly
  name text not null,
  cover_url text,
  first_release_date date,
  genres text[] not null default '{}',
  steam_app_id integer,
  summary text,
  synced_at timestamptz not null default now()
);

create index games_steam_app_id_idx on public.games (steam_app_id);
create index games_name_trgm_idx on public.games using gin (name gin_trgm_ops);

alter table public.games enable row level security;

create policy "Games are publicly readable"
  on public.games for select
  using (true);

-- No insert/update/delete policy: RLS blocks all writes for anon/
-- authenticated roles by default when no policy grants them. Only the
-- igdb-search Edge Function (using the service role key, which bypasses
-- RLS) writes to this table.
