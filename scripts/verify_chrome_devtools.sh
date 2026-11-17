#!/usr/bin/env bash
# Verify the chrome-devtools CLI can open saucedemo.com and save a screenshot.
# Uses headless + isolated browser (no persistent profile). Daemon is stopped
# on exit, even on failure.
set -euo pipefail
cd "$(dirname "$0")/.."

CDT="npx -y -p chrome-devtools-mcp@latest chrome-devtools"
OUT="artifacts/chrome-devtools-cli-saucedemo.png"
mkdir -p artifacts

cleanup() {
  $CDT stop >/dev/null 2>&1 || true
}
trap cleanup EXIT

$CDT stop >/dev/null 2>&1 || true # clean slate (kills stale daemon/socket)
$CDT start --headless --isolated
$CDT navigate_page 1 --url "https://www.saucedemo.com"
$CDT take_screenshot 1 --filePath "$OUT"

test -s "$OUT"
echo "OK: $OUT ($(stat -c%s "$OUT") bytes)"
