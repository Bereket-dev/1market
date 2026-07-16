# Koolan – Jigjiga Marketplace

A Flutter marketplace app for Jigjiga, running as a Flutter web build on Replit.

## Stack

- **Framework**: Flutter (web target)
- **Backend**: Supabase (auth, database, realtime)
- **Language**: Dart

## Running on Replit

The workflow **"Start application"** serves a pre-built Flutter release bundle:

```
python3 -m http.server 5000 --directory build/web
```

After any code change, rebuild first:

```bash
flutter build web \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

Then restart the workflow. Supabase credentials are stored as environment variables (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) in the Replit shared environment.

> **Why release build?** Replit's sandbox has no WebGL. Flutter's CanvasKit debug-server falls back to CPU rendering and produces a blank canvas. The release build's CanvasKit initializes correctly even without GPU support.

## Environment variables

| Key                | Description                        |
|--------------------|------------------------------------|
| `SUPABASE_URL`     | Supabase project URL               |
| `SUPABASE_ANON_KEY`| Supabase publishable (anon) key    |

## Project structure

```
lib/
  main.dart              # Entry point — Supabase init
  app.dart               # Root widget + onboarding gate
  core/                  # Config, theme, router, constants
  features/              # Feature modules (home, listings, chat, profile, …)
  shared/                # App state, shared services
supabase/
  migrations/            # SQL schema (profiles, listings, favorites, chat)
android/                 # Android build config
web/                     # Web entry (index.html, manifest)
```

## Database schema

Run `supabase/migrations/001_schema.sql` against your Supabase project to create the required tables (profiles, listings, favorites, messages, reports) with RLS policies.

## Notes

- `pubspec.yaml` SDK constraint relaxed to `>=3.8.0 <4.0.0` and `supabase_flutter` pinned to `^2.15.4` to match the Nix-provided Flutter 3.32.0 / Dart 3.8.0.
- The app uses `--dart-define` to bake credentials in at build time; they are not read from the OS environment at runtime.

## User preferences

_None recorded yet._
