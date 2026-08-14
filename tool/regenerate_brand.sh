#!/usr/bin/env bash
# Regenerate launcher icons + native splash from assets/brand sources.
set -euo pipefail
cd "$(dirname "$0")/.."

python3 tool/generate_brand_assets.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create

# flutter_native_splash always emits a stretched 1×1 background bitmap.
# Use solid brand colours instead so only the centred logo PNG is drawn.
for f in \
  android/app/src/main/res/drawable/launch_background.xml \
  android/app/src/main/res/drawable-v21/launch_background.xml \
  android/app/src/main/res/drawable-night/launch_background.xml \
  android/app/src/main/res/drawable-night-v21/launch_background.xml
do
  cat > "$f" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_background" />
    <item>
        <bitmap android:gravity="center" android:src="@drawable/splash" />
    </item>
</layer-list>
EOF
done

echo "Brand assets regenerated."
