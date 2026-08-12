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
    body: `search "${query}"; fields name, cover.url, first_release_date, genres.name, summary; limit 20;`,
  });
  const results = await igdbRes.json();

  const games = results.map((g: any) => ({
    id: g.id,
    name: g.name,
    cover_url: g.cover?.url ? `https:${g.cover.url.replace("t_thumb", "t_cover_big")}` : null,
    first_release_date: g.first_release_date
      ? new Date(g.first_release_date * 1000).toISOString().slice(0, 10)
      : null,
    genres: (g.genres ?? []).map((genre: any) => genre.name),
    summary: g.summary ?? null,
    synced_at: new Date().toISOString(),
  }));

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  if (games.length > 0) {
    const { error } = await supabase.from("games").upsert(games);
    if (error) console.error("Failed to cache games:", error);
  }

  return new Response(JSON.stringify(games), {
    headers: { "Content-Type": "application/json" },
  });
});
