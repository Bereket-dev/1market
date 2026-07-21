# Koolan – Jigjiga Marketplace

A Flutter marketplace app for Jigjiga.

## Run Locally

**Prerequisites:** [Flutter SDK](https://flutter.dev/docs/get-started/install) and [Android Studio](https://developer.android.com/studio)

1. Open Android Studio
2. Select **Open** and choose the directory containing this project
3. Allow Android Studio to fix any incompatibilities as it imports the project
4. Run the app with Supabase config:

```bash
flutter run --dart-define=SUPABASE_URL=your_supabase_url --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Android / Firebase

The Android app ID is `com.jigjigamarket.koolan`. Firebase is configured via `android/app/google-services.json` (download from the [Firebase console](https://console.firebase.google.com/) if missing).

Gradle setup:
- Google Services plugin `4.5.0` in `android/settings.gradle.kts`
- Firebase BoM `34.16.0` + Analytics in `android/app/build.gradle.kts`

## Build APK

```bash
flutter build apk --release
```

The APK will be at `build/outputs/flutter-apk/app-release.apk`.
