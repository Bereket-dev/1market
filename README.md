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

## Build APK

```bash
flutter build apk --release
```

The APK will be at `build/outputs/flutter-apk/app-release.apk`.
