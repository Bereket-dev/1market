# Brand Assets

| File | Purpose |
|------|---------|
| `1market_light.png` | Full lockup for light mode (logo + ONE MARKET + slogan) — used for splash |
| `1market_dark.png` | Full lockup for dark mode — used for splash |
| `1market_logo_light.png` | Cropped logo (light) — launcher icon + in-app logo widget |
| `1market_logo_dark.png` | Cropped logo (dark) — in-app logo widget |

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

- In-app UI uses `BrandLogo` (`lib/shared/widgets/brand_logo.dart`) which picks light/dark lockups from theme brightness.
- Keep `android/app/src/main/res/drawable/ic_notification.xml` as a monochrome notification icon.
