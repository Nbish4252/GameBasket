-- "Played With" tagging — real co-op partners on a log, not just
-- reviewers. Only the log's owner can tag/untag participants; the
-- tagged friend has no write access of their own here.
create table public.log_participants (
  log_id uuid not null references public.logs (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (log_id, profile_id)
);

create index log_participants_profile_id_idx on public.log_participants (profile_id);

alter table public.log_participants enable row level security;

create policy "Log participants are publicly readable"
  on public.log_participants for select
  using (true);

create policy "Log owners can tag participants"
  on public.log_participants for insert
  with check (
    auth.uid() = (select user_id from public.logs where id = log_id)
  );

create policy "Log owners can remove participant tags"
  on public.log_participants for delete
  using (
    auth.uid() = (select user_id from public.logs where id = log_id)
  );
