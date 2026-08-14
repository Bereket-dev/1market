# Brand Assets

Place the following files here before generating launcher icons and splash screens.

## Required files

| File | Dimensions | Purpose |
|------|-----------|---------|
| `logo.png` | 1024×1024 px | Main app icon (square, transparent bg or solid brand bg) |
| `logo_foreground.png` | 1024×1024 px | Adaptive icon foreground layer (safe-zone content within centre 66%) |
| `splash_logo.png` | 288×288 px | Centred K on transparent bg for pre-Android-12 splash |
| `splash_logo_android12.png` | 1152×1152 px | Android 12+ splash icon (centre safe zone only) |

## Optional

| File | Purpose |
|------|---------|
| `avatar_placeholder.png` | Default avatar when user has no profile photo |
| `banner_placeholder.png` | Default profile banner (currently replaced by brand gradient in code) |

## Generate icons & splash

```bash
# One command — generates PNGs, launcher icons, splash, and fixes launch background
./tool/regenerate_brand.sh
```

Or step by step:

```bash
# Regenerate source PNGs (transparent foreground + brand-blue legacy icon)
python3 tool/generate_brand_assets.py

# Install deps (one-time)
flutter pub get

# Generate launcher icons (requires logo.png + logo_foreground.png)
dart run flutter_launcher_icons

# Generate native splash (requires splash_logo.png)
dart run flutter_native_splash:create
```

## Notes

- **Never commit** private keystore files here — they belong outside the repo.
- The launcher icon background colour is `#00288E` (Koolan brand blue), set in `pubspec.yaml`.
- Keep the existing `android/app/src/main/res/drawable/ic_notification.xml`
  as-is — it is a **monochrome** white-on-transparent notification icon and must
  NOT be replaced with a full-colour launcher image.
