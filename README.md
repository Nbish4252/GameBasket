# GameBasket

A social app for logging and rating the games you play — SwiftUI (iOS) + Supabase.

## Repo layout

```
gamebasket/
├── ios/                      # SwiftUI app
│   ├── project.yml           # XcodeGen spec — generates the .xcodeproj (not committed)
│   └── GameBasket/
│       ├── App/               # App entry, root routing, app-wide state
│       ├── Models/             # Codable structs mirroring the Postgres schema
│       ├── Services/           # Supabase client, auth bridge, data access
│       └── Features/           # One folder per screen area
└── supabase/
    ├── migrations/            # SQL schema, applied via the Supabase CLI
    └── functions/             # Edge Functions (Deno/TS)
        ├── igdb-search/       # Proxies IGDB, caches results into `games`
        ├── steam-sync/        # Pulls a linked Steam library + playtime
        └── recommend-games/   # Claude-powered recs from the caller's highly-rated logs
```

`igdb-search` doubles as the cache-warmer for `games` — there's no separate sync job for MVP; if a bulk refresh job turns out to be needed later, add it as its own function then.

## One-time setup

### Supabase

1. Install the CLI: `brew install supabase/tap/supabase`
2. `cd supabase && supabase init` — this fills in `config.toml` (left out of this scaffold so it always matches your installed CLI version) without touching the `migrations/`/`functions/` already here.
3. `supabase login` and `supabase link --project-ref <your-project-ref>` (create the project at supabase.com first).
4. In the dashboard, go to Authentication → Providers → Google: enable it, add the Web OAuth client's ID (see iOS step 2 below) to the allowed Client IDs, and turn on **Skip nonce checks**. This last one isn't optional for this app: GoogleSignIn-iOS's `signInWithPresentingViewController` API has no way to set or retrieve the nonce it embeds in the ID token, so Supabase's nonce verification (which hashes whatever value you send and compares it to the token's claim) can never succeed — there's no value we could send that would match. Signature, audience, issuer, and expiry checks on the token all still apply; only the replay-protection nonce check is skipped.
5. Apply the schema: `supabase db push`
6. Set Edge Function secrets:
   ```
   supabase secrets set IGDB_CLIENT_ID=... IGDB_CLIENT_SECRET=... STEAM_API_KEY=... ANTHROPIC_API_KEY=...
   ```
   (IGDB creds come from a Twitch dev app; Steam key from https://steamcommunity.com/dev/apikey; Anthropic key from https://console.anthropic.com)
7. Deploy functions: `supabase functions deploy igdb-search && supabase functions deploy steam-sync && supabase functions deploy recommend-games`

### iOS

1. Install XcodeGen: `brew install xcodegen`
2. `cd ios && cp GameBasket/Secrets.xcconfig.example GameBasket/Secrets.xcconfig` and fill in:
   - `SUPABASE_URL` / `SUPABASE_ANON_KEY` (Project Settings → API in the Supabase dashboard)
   - `GOOGLE_CLIENT_ID` / `GOOGLE_REVERSED_CLIENT_ID` — from an **iOS** OAuth client in Google Cloud Console for bundle ID `com.gamebasket.app`. `GOOGLE_REVERSED_CLIENT_ID` is the same ID with its segments reversed (`client-id.apps.googleusercontent.com` → `com.googleusercontent.apps.client-id`).
   - `GOOGLE_SERVER_CLIENT_ID` — from a separate **Web** OAuth client in the same Google Cloud project. This is required, not optional: it's passed as `GIDConfiguration`'s `serverClientID` so the ID token Google issues has an audience Supabase's Google provider actually accepts. That same Web client ID also needs to be added to the allowed Client IDs list in the Supabase dashboard (Authentication → Providers → Google).
3. `xcodegen generate`, then open `GameBasket.xcodeproj`.

## Notes

- `supabase-swift`'s and GoogleSignIn's APIs shift between versions; `AuthService`'s calls have been compiled and run successfully against the resolved versions (supabase-swift 2.54.1, GoogleSignIn-iOS 7.1.0) — anything elsewhere in `Services/` that hasn't been exercised yet should still be treated as unverified until it's actually run.
- Google Sign-In requires **Skip nonce checks** enabled on Supabase's Google provider (see Supabase setup step 4) — GoogleSignIn-iOS's sign-in API doesn't expose the nonce it embeds in the ID token, so Supabase's normal nonce verification has no value we could supply that would ever match.
- Ratings are stored as half-heart units (`smallint` 1–10) to represent 0.5–5♥ — hearts instead of stars, a deliberate break from Letterboxd's rating unit so it never reads as a price tag.
- Logs default to `playing` status, not `completed` — people tend to log a game when they start it, not after they finish it.
- `log_participants` tags real co-op partners on a log ("Played With") — something a film tracker has no equivalent for, since films aren't played together. Only the log's owner can add/remove tags; the tagged friend has no write access of their own.
- RLS: `profiles`, `games`, `logs`, `follows`, `log_likes`, and `log_participants` are publicly readable but writable only by their owner (for `log_participants`, "owner" means whoever owns the parent log, not the tagged friend); `games` and `steam_library` writes are restricted to the service role (i.e. only the Edge Functions can write them); `steam_library` reads are owner-only.
- `recommend-games` uses Claude's structured outputs (`output_config: {format: {type: "json_schema", ...}}`) so the response is guaranteed-parseable JSON — no free-text parsing on the client. Uses Claude Haiku 4.5, not Opus/Sonnet: this is a short, low-stakes extraction/recommendation task (a handful of titles in, a handful out), and Haiku is ~5x cheaper at that tier — the kind of workload where a bigger model doesn't buy meaningfully better output. Returns an early, uncalled-Claude empty result if the caller has no highly-rated (≥4.0 heart) logs yet, both to avoid spending a call on insufficient signal and because "log a few games you love" is a better empty state than a generic recommendation.
