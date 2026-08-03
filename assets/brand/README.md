# Brand Assets

Place the following files here before generating launcher icons and splash screens.

## Required files

| File | Dimensions | Purpose |
|------|-----------|---------|
| `logo.png` | 1024×1024 px | Main app icon (square, transparent bg or solid brand bg) |
| `logo_foreground.png` | 1024×1024 px | Adaptive icon foreground layer (safe-zone content within centre 66%) |
| `splash_logo.png` | 288×288 px (1×) | Centred logo on native splash screen |

## Optional

| File | Purpose |
|------|---------|
| `avatar_placeholder.png` | Default avatar when user has no profile photo |
| `banner_placeholder.png` | Default profile banner (currently replaced by brand gradient in code) |

## Generate icons & splash

```bash
# Install deps (one-time)
flutter pub get

# Generate launcher icons (requires logo.png + logo_foreground.png)
flutter pub run flutter_launcher_icons

# Generate native splash (requires splash_logo.png)
flutter pub run flutter_native_splash:create
```

## Notes

- **Never commit** private keystore files here — they belong outside the repo.
- The launcher icon background colour is `#00288E` (Koolan brand blue), set in `pubspec.yaml`.
- Keep the existing `android/app/src/main/res/drawable/ic_notification.xml`
  as-is — it is a **monochrome** white-on-transparent notification icon and must
  NOT be replaced with a full-colour launcher image.
