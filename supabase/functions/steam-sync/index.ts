// Pulls the caller's owned games + playtime from the Steam Web API and
// upserts them into public.steam_library. Expects the caller's Supabase
// JWT (the iOS app calls this authenticated) so we can resolve which
// profile — and which linked steam_id — to sync.
//
// Required secrets (`supabase secrets set ...`):
//   STEAM_API_KEY
// Provided automatically by the Supabase runtime:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const STEAM_API_KEY = Deno.env.get("STEAM_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing Authorization header" }), { status: 401 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const { data: userData, error: userError } = await supabase.auth.getUser(
    authHeader.replace("Bearer ", ""),
  );
  if (userError || !userData.user) {
    return new Response(JSON.stringify({ error: "Invalid session" }), { status: 401 });
  }

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("steam_id")
    .eq("id", userData.user.id)
    .single();
  if (profileError || !profile?.steam_id) {
    return new Response(JSON.stringify({ error: "No linked Steam account" }), { status: 400 });
  }

  const steamRes = await fetch(
    `https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=${STEAM_API_KEY}&steamid=${profile.steam_id}&include_appinfo=false&format=json`,
  );
  const steamData = await steamRes.json();
  const games = steamData.response?.games ?? [];

  const rows = games.map((g: any) => ({
    user_id: userData.user.id,
    steam_app_id: g.appid,
    playtime_minutes: g.playtime_forever,
    last_synced_at: new Date().toISOString(),
  }));

  if (rows.length > 0) {
    const { error } = await supabase.from("steam_library").upsert(rows);
    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }
  }

  return new Response(JSON.stringify({ synced: rows.length }), {
    headers: { "Content-Type": "application/json" },
  });
});
