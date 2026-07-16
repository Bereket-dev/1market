---
name: Flutter web on Replit
description: No WebGL in Replit's sandbox; debug dev-server produces blank canvas. Use release build + static server.
---

# Flutter web rendering on Replit

## The rule
Never use `flutter run -d web-server` as the production workflow for Flutter web on Replit. Build a release bundle and serve it statically instead.

**Working workflow command:**
```
python3 -m http.server 5000 --directory build/web
```

**Rebuild after code changes:**
```bash
flutter build web --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

**Why:** Replit's sandbox has no GPU/WebGL. Flutter's CanvasKit (the only renderer in 3.22+, HTML renderer was removed in 3.26) falls back to CPU rendering when WebGL is unavailable. The debug dev-server's CPU fallback silently produces a blank canvas. The release build's CanvasKit initialization path handles the no-WebGL case correctly and renders the full UI.

**Also:** `--web-renderer` CLI flag was removed in Flutter 3.22. Do not attempt to pass it.

**How to apply:** Any Flutter web project on Replit with Flutter 3.22+ should use this build+serve pattern. For development iteration, rebuild via shell then restart the serve workflow.
