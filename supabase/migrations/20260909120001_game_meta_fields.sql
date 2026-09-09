-- Fields sourced from IGDB but not previously stored: platform list,
-- developer/studio, an estimated "time to beat" (IGDB's
-- game_time_to_beats.normally, in minutes — a single representative
-- estimate rather than a fabricated min-max range, since that's what
-- IGDB actually gives us), and storefront links (Steam/GOG/etc, from
-- IGDB's websites field filtered to storefront categories).
--
-- No new RLS policies needed: these are new columns on the existing
-- public.games table, so its existing "publicly readable, service-role
-- writable" policies already cover them.
alter table public.games
  add column platforms text[] not null default '{}',
  add column developer text,
  add column playtime_estimate_minutes integer,
  add column store_links jsonb not null default '[]';

comment on column public.games.store_links is
  'Array of {"label": text, "url": text} objects — storefront links from IGDB''s websites field (Steam, GOG, App Store, etc), not a dedicated table since this is denormalized IGDB data, same as genres/platforms.';
