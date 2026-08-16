#!/usr/bin/env bash
# Create a Play upload keystore outside the repo (never commit it).
set -euo pipefail

OUT_DIR="${HOME}/.koolan-keys"
KEYSTORE="${OUT_DIR}/koolan-upload.jks"
ALIAS="upload"
PROPS="$(cd "$(dirname "$0")/.." && pwd)/android/key.properties"

mkdir -p "$OUT_DIR"

if [[ -f "$KEYSTORE" ]]; then
  echo "Keystore already exists: $KEYSTORE"
  echo "Refusing to overwrite. Delete it manually if you intend to rotate."
  exit 1
fi

echo "Generating upload keystore at $KEYSTORE"
keytool -genkey -v \
  -keystore "$KEYSTORE" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias "$ALIAS"

echo
echo "Wrote keystore. Create android/key.properties from the example:"
echo "  cp android/key.properties.example android/key.properties"
echo
echo "Then set:"
echo "  storeFile=$KEYSTORE"
echo "  keyAlias=$ALIAS"
echo "  storePassword=<the password you just entered>"
echo "  keyPassword=<same or key password>"
echo
echo "Target properties file: $PROPS"
echo
echo "Build a Play App Bundle with:"
echo "  flutter build appbundle --release"
