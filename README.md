# 1market – East Ethiopia Marketplace

Flutter marketplace app for East Ethiopia (buy, sell, hire, find services).

**Store-facing name:** 1market  
**Slogan:** One Place. Many Possibilities.  
**Application ID:** `com.jigjigamarket.koolan` (unchanged for Firebase / Play continuity)

## Run Locally

**Prerequisites:** [Flutter SDK](https://flutter.dev/docs/get-started/install) and [Android Studio](https://developer.android.com/studio)

1. Copy `.env.example` to `.env` and fill in your Supabase / OAuth values.
2. Sync client-safe keys into the app (also runs automatically before Android builds):

```bash
dart run tool/sync_local_env.dart
```

3. Run:

```bash
flutter run
```

The app bundles **Supabase URL + anon key** in `assets/config/local.env`. That is normal — the anon key is a public client key protected by Row Level Security. Never put the **service-role** key in the app.

## Android / Firebase

- Application ID: `com.jigjigamarket.koolan`
- Firebase: `android/app/google-services.json`
- Google Services plugin + Firebase BoM / Analytics / Crashlytics are wired in Gradle

## Release (Google Play)

### 1. Upload signing

```bash
./tool/create_upload_keystore.sh
cp android/key.properties.example android/key.properties
# edit key.properties with storeFile path + passwords
```

`android/key.properties` and `*.jks` / `*.keystore` are gitignored.  
Credentials backup (outside repo): `~/.koolan-keys/credentials.txt` — keep an offline copy.

### 2. Legal URLs

Update `lib/core/config/legal_urls.dart` with your live Privacy Policy and Terms pages (required by Play Console). Settings opens these links in the browser.

Store listing copy, data-safety answers, and screenshot checklist: [`docs/play_store_listing.md`](docs/play_store_listing.md).

### 3. Build App Bundle

```bash
dart run tool/sync_local_env.dart
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Release builds enable R8 minify + resource shrinking. Version is `pubspec.yaml` → `version: x.y.z+build` (`versionName` + `versionCode`).

### 4. Play Console checklist

Paste pack: [`docs/play_console_paste.md`](docs/play_console_paste.md).

- [ ] Short + full store description
- [ ] Phone screenshots (≥2) + feature graphic (`assets/promo/feature_graphic_1024x500.png`)
- [ ] Content rating questionnaire
- [ ] Data safety form (location, photos, personal info, messages)
- [ ] Privacy Policy URL + Terms URL (must match in-app links)
- [ ] Contact email (`support@1market.app`)
- [ ] Upload AAB to internal testing (manual, or `tool/upload_play_internal.py` with a service account)

### 5. Smoke test before upload

- Cold start shows branded splash/icon
- Email + Google sign-in
- Create listing with photo; browse offline with cache
- Chat unread badge; language switch en ↔ am ↔ so
- Kill app; reopen; session restored

> Facebook Login is deferred — see [`docs/facebook_signin_next_release.md`](docs/facebook_signin_next_release.md).

## Debug APK

```bash
flutter build apk --release
```

APK path: `build/app/outputs/flutter-apk/app-release.apk` (uses debug signing if `key.properties` is missing).
