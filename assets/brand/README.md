# Brand Assets

| File | Purpose |
|------|---------|
| `1market_light.png` | Full lockup (mark + ONE MARKET + slogan) — pre-Android 12 splash + Flutter boot |
| `1market_dark.png` | Full lockup dark — pre-Android 12 splash + Flutter boot |
| `1market_logo_light.png` | Icon-only mark — launcher icon + **Android 12+ splash** + in-app |
| `1market_logo_dark.png` | Icon-only mark dark — Android 12+ dark splash + in-app |

## Brand copy

- **Name:** 1market / ONE MARKET
- **Slogan:** One Place. Many Possibilities.

## Regenerate icons & splash

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Notes

- Android 12+ splash icons are **circular**. Use `1market_logo_*` only (never the full lockup).
- Pre-Android 12 splash and Flutter boot screens use the full lockup.
- Keep `android/app/src/main/res/drawable/ic_notification.xml` as a monochrome notification icon.
