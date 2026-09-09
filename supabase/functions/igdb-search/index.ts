// Searches IGDB for games matching a query, upserts the results into
// public.games (so repeat lookups don't cost another IGDB call), and
// returns the matched rows to the caller.
//
// Required secrets (`supabase secrets set ...`):
//   IGDB_CLIENT_ID, IGDB_CLIENT_SECRET  — Twitch dev app used for IGDB auth
// Provided automatically by the Supabase runtime:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const IGDB_CLIENT_ID = Deno.env.get("IGDB_CLIENT_ID")!;
const IGDB_CLIENT_SECRET = Deno.env.get("IGDB_CLIENT_SECRET")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

let cachedToken: { value: string; expiresAt: number } | null = null;

async function getIgdbToken(): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now()) {
    return cachedToken.value;
  }
  const res = await fetch(
    `https://id.twitch.tv/oauth2/token?client_id=${IGDB_CLIENT_ID}&client_secret=${IGDB_CLIENT_SECRET}&grant_type=client_credentials`,
    { method: "POST" },
  );
  const data = await res.json();
  cachedToken = {
    value: data.access_token,
    expiresAt: Date.now() + (data.expires_in - 60) * 1000,
  };
  return cachedToken.value;
}

Deno.serve(async (req) => {
  const { query } = await req.json();
  if (!query || typeof query !== "string") {
    return new Response(JSON.stringify({ error: "Missing `query`" }), { status: 400 });
  }

  const token = await getIgdbToken();
  const igdbRes = await fetch("https://api.igdb.com/v4/games", {
    method: "POST",
    headers: {
      "Client-ID": IGDB_CLIENT_ID,
      Authorization: `Bearer ${token}`,
    },
    body:
      `search "${query}"; fields name, cover.url, first_release_date, genres.name, summary, external_games.uid, external_games.external_game_source, platforms.name, platforms.abbreviation, involved_companies.company.name, involved_companies.developer, websites.url, websites.type; limit 20;`,
  });
  const results = await igdbRes.json();

  // IGDB's external_games.external_game_source enum: 1 = Steam (confirmed
  // empirically against a known game — the field used to be called
  // "category" in older IGDB docs/examples, but the live API only
  // returns data under external_game_source now). uid is the Steam App
  // ID as a string on that entry.
  const STEAM_SOURCE = 1;

  // A second IGDB call: game_time_to_beats isn't embeddable on the
  // /games search the way genres/platforms are (it's a separate
  // endpoint, one row per game_id), so it's fetched in a single batched
  // follow-up request instead of per-game. "normally" (average time
  // including some but not all extras) is used as the one representative
  // estimate rather than exposing hastily/completely too — matches the
  // mockup's single playtime figure without fabricating a min-max range
  // IGDB doesn't actually provide.
  const gameIds: number[] = results.map((g: any) => g.id);
  const timeToBeatByGameId: Record<number, number> = {};
  if (gameIds.length > 0) {
    const timeRes = await fetch("https://api.igdb.com/v4/game_time_to_beats", {
      method: "POST",
      headers: {
        "Client-ID": IGDB_CLIENT_ID,
        Authorization: `Bearer ${token}`,
      },
      body: `fields game_id, normally; where game_id = (${gameIds.join(",")}); limit ${gameIds.length};`,
    });
    const timeResults = await timeRes.json();
    for (const t of timeResults) {
      if (t.game_id != null && t.normally != null) {
        timeToBeatByGameId[t.game_id] = t.normally;
      }
    }
  }

  // websites.category (the field name IGDB's docs list) is confirmed
  // empirically dead — real responses (tested against Portal 2, etc.)
  // return no value for it at all, even requested explicitly. The field
  // that's actually populated live is websites.type: a plain integer
  // using the same enum values category used to document, just under a
  // renamed field IGDB apparently swapped in without updating the docs
  // page (which itself 403s to automated fetches, so this was verified
  // by requesting the field and reading real values back, not the docs).
  const STOREFRONT_LABELS: Record<number, string> = {
    10: "App Store",
    11: "App Store",
    12: "Google Play",
    13: "Steam",
    15: "itch.io",
    16: "Epic Games",
    17: "GOG",
    22: "Xbox",
  };

  const games = results.map((g: any) => {
    const steamEntry = (g.external_games ?? []).find((eg: any) => eg.external_game_source === STEAM_SOURCE);
    const steamAppId = steamEntry ? parseInt(steamEntry.uid, 10) : null;

    const developerEntry = (g.involved_companies ?? []).find((ic: any) => ic.developer === true);
    const playtimeSeconds = timeToBeatByGameId[g.id];

    return {
      id: g.id,
      name: g.name,
      cover_url: g.cover?.url ? `https:${g.cover.url.replace("t_thumb", "t_cover_big")}` : null,
      first_release_date: g.first_release_date
        ? new Date(g.first_release_date * 1000).toISOString().slice(0, 10)
        : null,
      genres: (g.genres ?? []).map((genre: any) => genre.name),
      steam_app_id: Number.isFinite(steamAppId) ? steamAppId : null,
      summary: g.summary ?? null,
      platforms: (g.platforms ?? []).map((p: any) => p.abbreviation ?? p.name).filter(Boolean),
      developer: developerEntry?.company?.name ?? null,
      playtime_estimate_minutes: playtimeSeconds != null ? Math.round(playtimeSeconds / 60) : null,
      store_links: (g.websites ?? [])
        .filter((w: any) => w.type != null && STOREFRONT_LABELS[w.type])
        .map((w: any) => ({ label: STOREFRONT_LABELS[w.type], url: w.url })),
      synced_at: new Date().toISOString(),
    };
  });

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  if (games.length > 0) {
    const { error } = await supabase.from("games").upsert(games);
    if (error) console.error("Failed to cache games:", error);
  }

  return new Response(JSON.stringify(games), {
    headers: { "Content-Type": "application/json" },
  });
});
