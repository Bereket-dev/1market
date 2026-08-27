# 1market — Google Play Store Listing Pack

Use this when filling Play Console. Hosted legal pages must stay live.

| Field | Value |
|-------|--------|
| App name | **1market** |
| Package | `com.jigjigamarket.koolan` |
| Short slogan | One Place. Many Possibilities. |
| Privacy Policy | https://1market-privacy-policy.vercel.app/ |
| Terms of Service | https://1market-terms.vercel.app/ |
| Contact email | `support@1market.app` (also in `LegalUrls.playStoreContactEmail`) |
| Category | Shopping (or Lifestyle) |
| Feature graphic | `assets/promo/feature_graphic_1024x500.png` (1024×500) |

---

## Short description (≤ 80 chars)

```
Buy, sell & hire across East Ethiopia. Cars, homes, land & local services.
```

(78 characters)

## Full description

```
1market is East Ethiopia’s marketplace — one place for cars, houses, land, skills, and local hiring.

• Browse listings near you and chat with sellers
• Post a listing with photos in minutes
• Find and hire skilled local service providers
• Apply to open jobs with your service profile
• Works in English, Amharic, and Somali
• Offline-friendly browsing with cached listings

One Place. Many Possibilities.
```

---

## Screenshots (phone)

Capture on a mid-size phone (or Play screenshot sizes: 16:9 or 9:16). Minimum 2; aim for 4–8.

Suggested sequence (use a signed-in test account with real sample data):

1. Home — promo + categories + nearby listings  
2. Listing detail with photos  
3. Messages / chat thread  
4. Services browse or service detail  
5. Post wizard (mid-flow)  
6. Language / settings (optional)

Save under `assets/promo/screenshots/` (create as needed; not required in the APK).

```bash
# With a device connected:
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png assets/promo/screenshots/01_home.png
```

---

## Content rating (IARC questionnaire — typical answers)

Answer honestly in Play Console. Expected profile for this app:

- No user-generated content that is primarily for kids  
- User-generated listings/messages → yes (moderation via in-app Report)  
- No gambling, no alcohol/tobacco sales focus, no violence as core content  
- Location sharing for nearby listings → yes (optional permission)  
- Users can communicate (chat) → yes  

Expect a mature / teen-or-up rating depending on UGC answers — do not claim “Designed for Families” unless you meet those rules.

---

## Data safety form (summary)

Declare what the app **collects** and **shares** (share = to third parties / servers you don’t fully control).

| Data type | Collected? | Shared? | Purpose | Notes |
|-----------|------------|---------|---------|-------|
| Email | Yes | No* | Account | Supabase Auth |
| Name / profile | Yes | No* | Account, marketplace | Display name, bio |
| Phone | Yes (optional) | No* | Contact sellers | Profile + listings |
| Photos | Yes | No* | Listings / profile / CV | Cloudinary CDN |
| Location | Yes (approx) | No* | Nearby listings / push | OS permission |
| Messages | Yes | No* | Chat | Stored in Supabase |
| App activity | Yes | Analytics | Crashlytics / Analytics | Firebase |
| Device / push token | Yes | No* | Notifications | FCM |

\* “Shared” = not sold. Data is processed by your backends (Supabase, Cloudinary, Firebase). In Play’s form, mark **encrypted in transit**, **users can request deletion** (Settings → Delete account), and link Privacy Policy.

Account deletion: migration `031_delete_own_account.sql` **applied to production** (`delete_own_account` RPC). In-app path: Settings → Delete account.

Ready-to-paste Play Console answers: [`docs/play_console_paste.md`](play_console_paste.md).

---

## In-app consistency

- Launcher label / `MaterialApp` title: **1market**  
- Settings → Privacy / Terms open `LegalUrls`  
- Facebook login uses existing Supabase OAuth (browser); no separate ID-token helper in release  

---

## Smoke test (signed release AAB)

```bash
dart run tool/sync_local_env.dart
flutter build appbundle --release
# Install on device (optional):
# bundletool or upload to internal testing track
```

Checklist:

- [ ] Cold start: branded splash → home  
- [ ] Email + Google sign-in  
- [ ] Facebook sign-in (if Meta app + Supabase provider configured)  
- [ ] Create listing **with photo**  
- [ ] Chat unread badge; archive  
- [ ] Language en ↔ am ↔ so (including home promo)  
- [ ] Airplane mode: cached browse works  
- [ ] Kill app → reopen → session restored  
- [ ] Report sheet on listing/service/job  
- [ ] Service review form only after accepted hire (not for own service)  
- [ ] Settings → Delete account (after applying migration 031)  
