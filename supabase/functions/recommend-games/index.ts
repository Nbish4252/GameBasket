// Recommends a handful of games based on the caller's own highly-rated
// logs, via a single structured-output call to the Claude API — routed
// through Cloudflare AI Gateway (for request logging/caching/analytics)
// rather than hitting api.anthropic.com directly. Expects the caller's
// Supabase JWT (same auth pattern as steam-sync) so we can resolve which
// profile's logs to read.
//
// Required secrets (`supabase secrets set ...`):
//   ANTHROPIC_API_KEY, CLOUDFLARE_API_TOKEN
// Provided automatically by the Supabase runtime:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const CLOUDFLARE_API_TOKEN = Deno.env.get("CLOUDFLARE_API_TOKEN")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Not secrets — an AI Gateway account ID + gateway name are routing
// path segments, not credentials (the credential is CLOUDFLARE_API_TOKEN
// above).
const CLOUDFLARE_ACCOUNT_ID = "48def61faadea331d8b42a1c110c9a60";
const CLOUDFLARE_GATEWAY_ID = "gamebasket";
const ANTHROPIC_MESSAGES_URL =
  `https://gateway.ai.cloudflare.com/v1/${CLOUDFLARE_ACCOUNT_ID}/${CLOUDFLARE_GATEWAY_ID}/anthropic/v1/messages`;

// Half-heart rating units (see logs.rating) — 8 == 4.0 hearts. Below this
// a log doesn't tell us the user *loved* the game, just that they played it.
const LOVED_THRESHOLD = 8;

// json_schema structured outputs don't support minItems/maxItems (see
// claude-api skill's JSON Schema Limitations), so the 3-5 count is a
// prompt instruction, not a schema constraint.
const RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    recommendations: {
      type: "array",
      items: {
        type: "object",
        properties: {
          title: { type: "string" },
          reason: { type: "string" },
        },
        required: ["title", "reason"],
        additionalProperties: false,
      },
    },
  },
  required: ["recommendations"],
  additionalProperties: false,
};

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

  // All logged titles (any rating) so the prompt can tell Claude not to
  // recommend something the user has already played.
  const { data: allLogs, error: allLogsError } = await supabase
    .from("logs")
    .select("games(name)")
    .eq("user_id", userData.user.id);
  if (allLogsError) {
    return new Response(JSON.stringify({ error: allLogsError.message }), { status: 500 });
  }
  const alreadyLogged: string[] = (allLogs ?? []).map((l: any) => l.games?.name).filter(Boolean);

  const lovedGames = alreadyLogged.length === 0
    ? []
    : (await supabase
      .from("logs")
      .select("rating, games(name, genres)")
      .eq("user_id", userData.user.id)
      .gte("rating", LOVED_THRESHOLD)
      .order("rating", { ascending: false })
      .limit(20)).data ?? [];

  if (lovedGames.length === 0) {
    return new Response(JSON.stringify({ recommendations: [], reason: "not_enough_data" }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  const lovedList = lovedGames
    .map((l: any) => `${l.games?.name}${l.games?.genres?.length ? ` (${l.games.genres.join(", ")})` : ""}`)
    .join("\n");

  const prompt = `A player rated these games highly:\n${lovedList}\n\n` +
    (alreadyLogged.length > 0
      ? `They've already played (do not recommend any of these): ${alreadyLogged.join(", ")}\n\n`
      : "") +
    `Recommend 3-5 other real games they'd likely enjoy, with a one-sentence reason each grounded in what they rated highly.`;

  // NOTE ON AUTH HEADERS: Cloudflare's docs are genuinely ambiguous on
  // whether cf-aig-authorization (gateway-access auth) is meant to be
  // sent *alongside* the provider's own x-api-key, or *instead of* it
  // (that "instead of" mode — BYOK/Unified Billing — needs an Anthropic
  // key stored in the Cloudflare dashboard, which hasn't been set up
  // here). Sending both is the safer bet: it keeps our own
  // ANTHROPIC_API_KEY as the credential that actually pays for the
  // Anthropic call, while satisfying Authenticated Gateway if that's
  // enabled on this gateway. If this 401s, the fix is almost certainly
  // in the gateway's dashboard config (Authenticated Gateway on/off),
  // not this code — check that before assuming the header is wrong.
  const anthropicRes = await fetch(ANTHROPIC_MESSAGES_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
      "cf-aig-authorization": `Bearer ${CLOUDFLARE_API_TOKEN}`,
    },
    body: JSON.stringify({
      model: "claude-haiku-4-5",
      max_tokens: 1024,
      messages: [{ role: "user", content: prompt }],
      output_config: {
        format: { type: "json_schema", schema: RESPONSE_SCHEMA },
      },
    }),
  });

  if (!anthropicRes.ok) {
    const errorText = await anthropicRes.text();
    return new Response(JSON.stringify({ error: `Anthropic API error: ${errorText}` }), { status: 502 });
  }

  const anthropicData = await anthropicRes.json();
  const textBlock = anthropicData.content?.find((b: any) => b.type === "text");
  if (!textBlock) {
    return new Response(JSON.stringify({ error: "No text content in Claude response" }), { status: 502 });
  }

  // output_config.format guarantees textBlock.text is valid JSON matching
  // RESPONSE_SCHEMA, so this is returned to the client as-is.
  return new Response(textBlock.text, {
    headers: { "Content-Type": "application/json" },
  });
});
