# Facebook Sign-In — next release

Facebook Login was **removed** from the v1 Play release to avoid Meta app review /
SDK / email-permission friction. Email + Google remain.

Use this checklist when you re-add it in a later release.

## Prerequisites

1. Meta Developer app with **Facebook Login** product enabled.
2. Valid **App ID** + **Client Token** (Settings → Basic / Advanced).
3. Android package `com.jigjigamarket.koolan` + key hashes registered in Meta.
4. Supabase Auth → Providers → **Facebook** enabled with the same App ID / secret.
5. Supabase redirect URL includes `io.supabase.koolan://login-callback/` (already used for Google browser OAuth).

## App wiring (restore)

### 1. Android credentials

`android/app/src/main/res/values/strings.xml` (gitignored):

```xml
<string name="facebook_app_id">YOUR_APP_ID</string>
<string name="fb_login_protocol_scheme">fbYOUR_APP_ID</string>
<string name="facebook_client_token">YOUR_CLIENT_TOKEN</string>
```

Template: keep a copy under `android/strings.xml.example` when re-enabling.

### 2. `AndroidManifest.xml`

Inside `<application>`:

- `meta-data` for `com.facebook.sdk.ApplicationId` + `ClientToken`
- `activity` `com.facebook.FacebookActivity`

### 3. Gradle

`android/app/build.gradle.kts`:

```kotlin
implementation("com.facebook.android:facebook-android-sdk:18.3.0") // pin explicitly
```

`android/app/proguard-rules.pro`:

```
-keep class com.facebook.** { *; }
-dontwarn com.facebook.**
```

### 4. Flutter UI

Restore a **Continue with Facebook** button on:

- `lib/features/onboarding/screens/auth_screen.dart`
- `lib/shared/widgets/widgets/auth_gate_content.dart`

Use Supabase browser OAuth (same pattern as before):

```dart
await client.auth.signInWithOAuth(
  OAuthProvider.facebook,
  redirectTo: AppSupabaseConfig.redirectUrl,
  scopes: 'email,public_profile',
  authScreenLaunchMode: LaunchMode.externalApplication,
);
```

Add `authFacebook` (+ optional failure copy) back to `AppStrings`.

**Require email scope** — without email, Supabase cannot link to an existing
same-email account; surface `authOAuthEmailRequired` on that failure.

### 5. Lifecycle / cancel handling

If using browser OAuth, handle resume-without-session (user cancelled or email
denied) on the auth screen via `WidgetsBindingObserver`, same as the previous
implementation.

## Smoke test

- [ ] Fresh install → Facebook → lands in session / profile setup
- [ ] Existing email account → Facebook with email permission → account linked
- [ ] Deny email → friendly error (no hang / infinite spinner)
- [ ] Auth gate sheet Facebook path from guest browse
- [ ] Cancel mid-flow clears loading + `clearOAuthPending()`

## Notes

- Prefer **native Facebook Login + `signInWithIdToken`** only if Meta + Supabase
  support is validated for your SDK versions; browser OAuth via
  `externalApplication` was the last working approach here.
- Do not ship Facebook until Meta app is out of Development mode (or testers
  are listed) and Play Data safety form mentions the new sign-in path.
