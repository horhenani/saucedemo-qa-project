#!/usr/bin/env bash
# Verify plain headless Chrome can open saucedemo.com and save a screenshot.
# --virtual-time-budget lets the SPA finish rendering before the shot is taken.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="artifacts/chrome-headless-saucedemo.png"
mkdir -p artifacts

google-chrome --headless=new --no-first-run --disable-gpu \
  --window-size=1280,720 --virtual-time-budget=8000 \
  --screenshot="$OUT" https://www.saucedemo.com

test -s "$OUT"
echo "OK: $OUT ($(stat -c%s "$OUT") bytes)"
