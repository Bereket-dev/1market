# Play Console — ready-to-paste answers

Use with package `com.jigjigamarket.koolan`. Privacy / Terms must stay live.

| Field | Value |
|-------|--------|
| App name | 1market |
| Contact email | support@1market.app |
| Privacy Policy | https://1market-privacy-policy.vercel.app/ |
| Terms of Service | https://1market-terms.vercel.app/ |
| Category | Shopping |
| Feature graphic | `assets/promo/feature_graphic_1024x500.png` |
| AAB | `build/app/outputs/bundle/release/app-release.aab` |

---

## Short description

```
Buy, sell & hire across East Ethiopia. Cars, homes, land & local services.
```

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

## Data safety (Play form)

Mark **encrypted in transit** for all collected data.  
Users can request deletion: **Yes** (Settings → Delete account).  
Privacy policy URL: as above.  
Data is **not sold**. Backends: Supabase, Cloudinary, Firebase.

| Data type | Collected | Shared | Purposes |
|-----------|-----------|--------|----------|
| Email | Yes | No (service providers only) | Account management |
| Name | Yes | No | Account, App functionality |
| Phone number | Yes (optional) | No | Account, App functionality |
| Photos | Yes | No | App functionality |
| Approximate location | Yes | No | App functionality |
| Messages / other in-app messages | Yes | No | App functionality |
| App interactions | Yes | Yes (Firebase Analytics) | Analytics |
| Crash logs | Yes | Yes (Crashlytics) | Analytics |
| Device or other IDs (FCM token) | Yes | No | App functionality |

---

## Content rating (IARC — typical answers)

Answer honestly in the questionnaire:

- Target audience: not primarily children  
- User-generated content: **Yes** (listings, chat) — moderated via in-app Report  
- Users can communicate: **Yes**  
- Location sharing: **Yes** (optional, for nearby listings)  
- No gambling; no alcohol/tobacco sales as focus; no violence as core content  
- Do **not** claim Designed for Families  

---

## Account deletion (declaration)

- In-app path: **Settings → Delete account**  
- Production RPC: `delete_own_account` (migration `031` applied)  
- Web URL (if asked): same Privacy Policy page, or note “delete in app only”

---

## Upload steps (manual)

1. [Play Console](https://play.google.com/console) → 1market → **Testing → Internal testing**  
2. Create release → upload `app-release.aab`  
3. Store listing → paste short/full description, upload feature graphic + phone screenshots (≥2)  
4. Complete Data safety + Content rating  
5. Add testers → send link  

Optional API upload (needs a Play Developer API service account JSON):

```bash
export PLAY_SERVICE_ACCOUNT_JSON=/path/to/play-api.json
export PLAY_PACKAGE_NAME=com.jigjigamarket.koolan
python3 tool/upload_play_internal.py
```
