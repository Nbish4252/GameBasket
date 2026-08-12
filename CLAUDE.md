Project context

GameBasket is a social app for logging and rating games, similar to Letterboxd. Stack: SwiftUI (iOS) + Supabase (Postgres, Auth, Edge Functions) + IGDB (metadata) + Steam Web API (playtime sync).

This repo is a portfolio piece I'll be showing to recruiters and engineers during job applications, alongside the app itself. Commit hygiene, README quality, and code clarity matter as much as functionality — this repo needs to read as evidence of good engineering judgment, not just a working app.

Git & commit rules
Never make one large commit for multiple unrelated changes. Commit in small, logical chunks — one feature, file group, or fix per commit.
Use conventional commit messages: feat:, fix:, chore:, docs:, refactor:, test:. Keep the summary line under ~65 chars, add a short body if the "why" isn't obvious from the diff.
Before committing, briefly state the plan for how you're splitting the work into commits, so I can confirm before you run git commands.
Don't commit secrets, .xcconfig files with real keys, or generated files (.xcodeproj, DerivedData, etc.) — check .gitignore covers these.
Working style
Ask clarifying questions before writing code for anything non-trivial rather than guessing at scope.
Explain Supabase-specific choices as you go (I'm new to Supabase). You don't need to over-explain SwiftUI or general architecture — I'm comfortable there.
When you're not sure an API call is correct (e.g. supabase-swift methods), say so explicitly rather than presenting it as verified.
Prefer proposing a short plan before large multi-file changes, so I can approve direction before you scaffold a lot of files at once.
Documentation
Keep the README current: what the app does, tech stack, architecture decisions (and why), and setup instructions. Treat it as something a recruiter or engineer will actually read.
When making a non-obvious architectural decision, note the reasoning in a commit message or README, not just the code — I want the "why" preserved for interview storytelling later.
