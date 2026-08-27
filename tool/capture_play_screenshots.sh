#!/usr/bin/env bash
# Capture Play Store phone screenshots from a connected device.
# Unlock the phone first, leave 1market in the foreground, then run:
#   ./tool/capture_play_screenshots.sh [serial]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets/promo/screenshots"
mkdir -p "$OUT"
DEV="${1:-}"
if [[ -z "$DEV" ]]; then
  DEV="$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
fi
if [[ -z "$DEV" ]]; then
  echo "No adb device connected" >&2
  exit 1
fi

shot() {
  local name="$1"
  adb -s "$DEV" shell screencap -p /sdcard/screen.png
  adb -s "$DEV" pull /sdcard/screen.png "$OUT/${name}.png" >/dev/null
  local bytes
  bytes=$(wc -c <"$OUT/${name}.png")
  if [[ "$bytes" -lt 50000 ]]; then
    echo "WARN: $name looks blank/locked (${bytes} bytes)" >&2
  else
    echo "OK $name (${bytes} bytes)"
  fi
}

adb -s "$DEV" shell dumpsys window | grep -q 'mDreamingLockscreen=false' \
  || { echo "Device appears locked — unlock it and retry." >&2; exit 1; }

adb -s "$DEV" shell am start -n com.jigjigamarket.koolan/.MainActivity >/dev/null
sleep 3
echo "Capturing current screen as next shot. Navigate manually between prompts."
n=1
while true; do
  printf "Ready for screenshot %02d (Enter=capture, q=quit): " "$n"
  read -r ans || break
  [[ "$ans" == "q" ]] && break
  shot "$(printf '%02d_screen' "$n")"
  n=$((n + 1))
done
ls -la "$OUT"
