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
        └── steam-sync/        # Pulls a linked Steam library + playtime
```

`igdb-search` doubles as the cache-warmer for `games` — there's no separate sync job for MVP; if a bulk refresh job turns out to be needed later, add it as its own function then.

## One-time setup

### Supabase

1. Install the CLI: `brew install supabase/tap/supabase`
2. `cd supabase && supabase init` — this fills in `config.toml` (left out of this scaffold so it always matches your installed CLI version) without touching the `migrations/`/`functions/` already here.
3. `supabase login` and `supabase link --project-ref <your-project-ref>` (create the project at supabase.com first).
4. Apply the schema: `supabase db push`
5. Set Edge Function secrets:
   ```
   supabase secrets set IGDB_CLIENT_ID=... IGDB_CLIENT_SECRET=... STEAM_API_KEY=...
   ```
   (IGDB creds come from a Twitch dev app; Steam key from https://steamcommunity.com/dev/apikey)
6. Deploy functions: `supabase functions deploy igdb-search && supabase functions deploy steam-sync`

### iOS

1. Install XcodeGen: `brew install xcodegen`
2. `cd ios && cp GameBasket/Secrets.xcconfig.example GameBasket/Secrets.xcconfig` and fill in your Supabase project URL/anon key (Project Settings → API in the Supabase dashboard) and your Google reversed client ID.
3. Drop your `GoogleService-Info.plist` into `GameBasket/` (gitignored).
4. `xcodegen generate`, then open `GameBasket.xcodeproj`.
5. Wire your existing GoogleSignIn button into `Features/Auth/SignInView.swift`, calling `AuthService.signInWithGoogle` on success — see the TODO there.

## Notes

- `supabase-swift`'s API shifts between versions; the calls in `Services/` are best-effort against the current SDK and haven't been compiled against a resolved package yet — check them against autocomplete once Xcode pulls the dependency.
- Ratings are stored as half-heart units (`smallint` 1–10) to represent 0.5–5♥ — hearts instead of stars, a deliberate break from Letterboxd's rating unit so it never reads as a price tag.
- Logs default to `playing` status, not `completed` — people tend to log a game when they start it, not after they finish it.
- RLS: `profiles`, `games`, `logs`, `follows`, `log_likes` are publicly readable but writable only by their owner; `games` and `steam_library` writes are restricted to the service role (i.e. only the Edge Functions can write them); `steam_library` reads are owner-only.
