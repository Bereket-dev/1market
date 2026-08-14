# Exception Handling & Error Resilience Plan

**Scope:** Flutter Android app before cybersecurity student testing, then public release.  
**Goal:** Fail safely, never leak internals to users or the APK, and leave a crash trail when testers break things.

---

## Current state (brief)

- Global handlers, Crashlytics, `ErrorWidget`, bootstrap retry, and safe UI
  error mapping are in place.
- `.env` is not shipped as an asset; Cloudinary signing goes through the
  `cloudinary-sign` Edge Function (API secret stays server-side).
- Defensive JSON parsing (`SafeParse`) and session-expiry sign-out are wired.
- Offline queues (CV, photos, listing images) only retry on transient network failures.
- Sync queue drops corrupted Hive entries and notifies the user.

---

## Must-have before cybersecurity students test

### 1. Global error handlers (`lib/main.dart`)
- [x] `FlutterError.onError` for framework errors
- [x] `PlatformDispatcher.instance.onError` for platform/async errors
- [x] `runZonedGuarded` around app startup
- Without these, uncaught async crashes die quietly during testing.

### 2. Crash reporting (Firebase Crashlytics preferred)
- [x] Add Crashlytics (Firebase already in the project)
- [x] Report fatal and non-fatal errors
- [x] Strip PII before send (phone, email, tokens, auth headers)
- Students will crash the app; you need a trail.

### 3. User-safe error messages
- [x] Stop showing `e.toString()` in auth/UI (`auth_screen.dart`, `auth_gate_content.dart`, similar screens)
- [x] Map to friendly strings via `AppStrings`: network, wrong password, session expired, try again
- [x] Never show stack traces, URLs, or backend payloads in the UI

### 4. Secrets out of the APK (critical for students)
- [x] Remove `.env` from `pubspec.yaml` assets for release builds
- [x] Prefer `--dart-define` only for **public** keys (Supabase URL + anon key, Cloudinary cloud name)
- [x] Move Cloudinary signed uploads (API secret) to a Supabase Edge Function, or use a tightly scoped unsigned upload preset
- Students will extract secrets from the APK in minutes. Exception handling does not protect secrets; architecture does.

### 5. Init failure UX
- [x] If Firebase/Supabase init fails, do not continue half-broken
- [x] Show a retry screen: “Can’t connect — check network / try again”

---

## Must-have before public launch

### 6. Network / timeout policy
- [x] Timeouts + retries on sync, uploads, chat
- [x] Classify `SocketException` / timeout vs server 4xx/5xx
- [x] Offline queue only for true network failures (CV, photos, listing wizard)

### 7. Defensive JSON parsing
- [x] Wrap `fromJson` / model parsing so bad or malicious API data does not crash the app
- [x] Skip bad rows; log once (Crashlytics non-fatal in release)

### 8. Session expiry handling
- [x] On `401` / JWT expired: sign out cleanly
- [x] Clear sensitive local cache
- [x] Route to auth with “Session expired”

### 9. Release logging
- [x] Gate all diagnostics with `if (kDebugMode) debugPrint(...)`
- [x] Never log tokens, auth headers, full request bodies, or local file paths in release

### 10. Custom `ErrorWidget.builder`
- [x] Replace the red error screen with a calm “Something went wrong”
- [x] Optional “Report” action
- [x] No exception text in release builds

---

## Nice-to-have (after students, before wide public)

- [x] Central `AppError` / `Result` type so services don’t invent ad-hoc catch styles
- [ ] Rate-limit / backoff on auth and report endpoints
- [ ] Integrity checks on sync queue entries (corrupted Hive payload → drop + notify, don’t crash)
- [ ] Play App Signing + R8 minify verification (Gradle already has proguard hooks)

---

## What not to overbuild

Don’t wrap every line in `try/catch`. Prefer:

1. **Boundaries** — UI actions, sync jobs, uploads, auth, init  
2. **Global catch-all** — zone + Flutter/platform handlers  
3. **Crashlytics** — fatal + selected non-fatals  

---

## Staging note for security students

- Give testers a **staging** Supabase / Cloudinary project, not production.
- Assume they will reverse the APK — treat anything in the client as public.
- Exception handling improves resilience and UX; it does not replace secret hygiene or RLS.

---

## Suggested implementation order

```text
1. Global handlers + Crashlytics + ErrorWidget          ✅
2. Safe auth/UI error mapping (no e.toString in UI)     ✅
3. Secrets: stop shipping .env; move Cloudinary signing ✅
4. Init failure retry screen                            ✅
5. Network/timeout + session expiry + defensive parsing  ✅
6. Log cleanup for release                              ✅
```

### Deploy notes (Cloudinary signing)

```bash
# Set Edge Function secrets (never put these in the APK):
supabase secrets set \
  CLOUDINARY_CLOUD_NAME=... \
  CLOUDINARY_API_KEY=... \
  CLOUDINARY_API_SECRET=...

supabase functions deploy cloudinary-sign

# Client release build — public values only:
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=... \
  --dart-define=CLOUD_NAME=...
```

Local debug can still pass `CLOUD_API_KEY` / `CLOUD_API_SECRET` via
`--dart-define-from-file=.env` as a fallback when the Edge Function is down.

---

## Related docs

- `docs/release_prep_plan.md` — branding, cold start, signing, l10n, demo content removal
