# Koolan – Jigjiga Marketplace

A Flutter marketplace app for Jigjiga.

## Run Locally

**Prerequisites:** [Flutter SDK](https://flutter.dev/docs/get-started/install) and [Android Studio](https://developer.android.com/studio)

1. Open Android Studio
2. Select **Open** and choose the directory containing this project
3. Allow Android Studio to fix any incompatibilities as it imports the project
4. Copy `.env.example` to `.env` and fill in your Supabase values.

5. Sync client-safe keys into the app (runs automatically before Android builds):

```bash
dart run tool/sync_local_env.dart
```

6. Run or build — no extra flags needed:

```bash
flutter run
flutter build apk --release
```

The app bundles **Supabase URL + anon key** in `assets/config/local.env`. That is normal — the anon key is a public client key protected by Row Level Security, not a secret. Never put the **service-role** key in the app.

## Android / Firebase

The Android app ID is `com.jigjigamarket.koolan`. Firebase is configured via `android/app/google-services.json` (download from the [Firebase console](https://console.firebase.google.com/) if missing).

Gradle setup:
- Google Services plugin `4.5.0` in `android/settings.gradle.kts`
- Firebase BoM `34.16.0` + Analytics in `android/app/build.gradle.kts`

## Build APK

```bash
dart run tool/sync_local_env.dart   # if not built via Android Gradle yet
flutter build apk --release
```

The APK will be at `build/outputs/flutter-apk/app-release.apk`.
