#!/usr/bin/env bash
# Read-only recon of https://www.saucedemo.com via the chrome-devtools CLI.
#
# Scope: map routes/screens and per-user bugs by OBSERVATION only.
# Allowed interactions: login/logout (required to try each demo user),
# client-side sort change, typing into (never submitting) the checkout form.
# Forbidden: add/remove cart items, checkout submit, reset app state.
# The browser runs --headless --isolated; the profile is discarded on stop.
#
# Outputs: screenshots/cli-*.png, recon/*.txt|json (+ recon/run.log when redirected)
# Usage: ./agent/recon-commands.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CDT="npx -y -p chrome-devtools-mcp@latest chrome-devtools"
PASS="secret_sauce"
PAGE=1
mkdir -p screenshots recon

cleanup() { $CDT stop >/dev/null 2>&1 || true; }
trap cleanup EXIT
$CDT stop >/dev/null 2>&1 || true # clean slate
$CDT start --headless --isolated >/dev/null
echo "== daemon started =="
$CDT list_pages

# --- helpers ---------------------------------------------------------------
snap() { $CDT take_snapshot "$PAGE"; }                       # full a11y snapshot to stdout
shot() { $CDT take_screenshot "$PAGE" --filePath "$1" >/dev/null; echo "shot: $1"; }
js() { $CDT evaluate_script "$1" --pageId "$PAGE" --output-format=json; }  # read-only DOM read
# first uid on the line matching $1 in snapshot $2
uid_of() { echo "$2" | grep "$1" | sed -n '1p' | sed 's/.*uid=\([0-9_]*\).*/\1/'; }
goto() { $CDT navigate_page "$PAGE" --url "$1" >/dev/null; echo "goto: $1"; }

login_as() { # $1 = username, $2 = expect: inventory|blocked
  # Retries fill+click (CLI input can flake) and verifies BOTH the session
  # cookie AND where we landed: cookie alone is not enough (locked_out sets
  # a cookie while staying on the login page with an error).
  # Glitch users can be slow to process login; never re-navigate while an
  # outcome may still be in flight — poll for it instead.
  local s u p b who ok err lens wantlens i j k okfill
  wantlens="${#1}:${#PASS}"
  for i in 1 2 3; do
    goto "https://www.saucedemo.com/" >/dev/null
    # Force a real document reload (same-URL goto may leave a stale/dead DOM)
    # and let the SPA boot/hydrate before touching the form.
    $CDT navigate_page "$PAGE" --type reload >/dev/null
    sleep 3
    s="$(snap)"
    u="$(uid_of 'textbox "Username"' "$s")"
    p="$(uid_of 'textbox "Password"' "$s")"
    b="$(uid_of 'button "Login"' "$s")"
    # Fill, then READ BACK: pre-hydration fills get wiped by React.
    okfill=0
    for k in 1 2 3; do
      $CDT fill "$PAGE" "$u" "$1" >/dev/null
      $CDT fill "$PAGE" "$p" "$PASS" >/dev/null
      lens="$(js "() => document.querySelectorAll('input')[0].value.length + ':' + document.querySelectorAll('input')[1].value.length" | grep -oE '[0-9]+:[0-9]+' || true)"
      echo "fill check: wantlens=$wantlens have=[$lens]"
      case ":${lens:-}:" in *"$wantlens"*) okfill=1; break;; *) sleep 2; s="$(snap)"; u="$(uid_of 'textbox "Username"' "$s" || true)"; p="$(uid_of 'textbox "Password"' "$s" || true)"; b="$(uid_of 'button "Login"' "$s" || true)";; esac
    done
    if [ "$okfill" != 1 ]; then echo "login_as[$i]: fills would not stick, retrying"; continue; fi
    $CDT click "$PAGE" "$b" >/dev/null
    for j in $(seq 1 10); do
      who="$(js "() => document.cookie" | grep -oE 'session-username=[^"\\;]+' || true)"
      ok="$(js "() => location.pathname" | grep -oE 'inventory\.html' || true)"
      err="$(snap | grep -oE 'Epic sadface[^"]{0,80}' || true)"
      if [ "$2" = blocked ]; then
        case "${who:-}::${err:-}" in *"$1"*Sorry*) echo "login_as[$i]: want=$1 blocked ok (cookie+error)"; return 0;; esac
      else
        case "${who:-}::${ok:-}" in *"$1"*inventory.html*) echo "login_as[$i]: want=$1 logged in ok"; return 0;; esac
      fi
      sleep 1
    done
    echo "login_as[$i]: want=$1 inconclusive have=[$who] inv=[$ok] err=[$err]"
  done
  # UI path failed (tool flake, not app behavior): authenticate directly via
  # the session cookie and verify. Equivalent to typing creds; the login
  # FORM itself is covered elsewhere. Never for expect=blocked.
  if [ "$2" = inventory ]; then
    echo "login_as: UI path failed, cookie fallback for $1"
    js "() => { document.cookie = 'session-username=$1; path=/'; return document.cookie; }" >/dev/null
    goto "https://www.saucedemo.com/inventory.html" >/dev/null
    who="$(js "() => document.cookie" | grep -oE 'session-username=[^"\\;]+' || true)"
    ok="$(js "() => location.pathname" | grep -oE 'inventory\.html' || true)"
    case "${who:-}::${ok:-}" in *"$1"*inventory.html*) echo "login_as: want=$1 logged in ok (cookie fallback)"; return 0;; esac
  fi
  echo "LOGIN-FAILED: $1 ($2)"; return 1
}

logout() { # $1 = username, $2 = phase tag (B/C/D) for evidence files
  # NOTE (tool quirk, verified 2026-11-17): the CLI `click` on the 20x20px
  # "Open Menu" burger is unreliable (silent no-op most tries; DOM .click()
  # opens the drawer every time), while `click` on Login/Logout works fine.
  # So the burger is opened via evaluate (same user gesture, no app-data
  # mutation); the Logout button itself is still clicked via CLI to exercise
  # the real path. Falls back to clearing our own session only.
  local s lo
  js "() => { const b = document.getElementById('react-burger-menu-btn'); if (b) b.click(); return !!b; }" >/dev/null
  s="$(snap)"
  echo "$s" > "recon/$2-$1-menu-snapshot.txt"
  lo="$(uid_of 'button "Logout"' "$s" || true)"
  if [ -n "${lo:-}" ]; then
    echo "$s" | grep -E 'button "(Logout|Reset App State)"|link "About"' | sed 's/^ *//' || true
    $CDT click "$PAGE" "$lo" >/dev/null
    echo "menu logout clicked: $1"
  else
    echo "drawer did not open for $1; skipping menu click"
  fi
  # Menu Logout navigates to / and clears the session-username cookie (verified 3/3).
  # Force-clear as well so the next run always starts clean.
  js "() => { document.cookie = 'session-username=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/'; return document.cookie; }" >/dev/null
  # Verify the session is really gone (auth = session-username cookie).
  local now
  now="$(js "() => document.cookie" | grep -oE 'session-username=[^"\\;]+' || true)"
  if [ -n "${now:-}" ]; then echo "LOGOUT-FAILED: still [$now]"; return 1; fi
  goto "https://www.saucedemo.com/"
  echo "logged out: $1"
}

# --- Phase A: logged out ----------------------------------------------------
echo "== Phase A: login page, empty submit, locked_out_user =="
goto "https://www.saucedemo.com/"
snap > recon/A-login-snapshot.txt
shot screenshots/cli-login.png
js "() => ({path: location.pathname, title: document.title})" > recon/A-login-route.json

s="$(snap)"
b="$(uid_of 'button "Login"' "$s")"
$CDT click "$PAGE" "$b" >/dev/null   # submit empty form (no session created)
snap > recon/A-empty-submit-snapshot.txt
grep -o 'Epic sadface[^"]*' recon/A-empty-submit-snapshot.txt || true
shot screenshots/cli-login-empty-error.png

login_as "locked_out_user" "blocked"
snap > recon/A-locked-out-snapshot.txt
grep -o 'Epic sadface[^"]*' recon/A-locked-out-snapshot.txt || true
shot screenshots/cli-login-locked-out.png

# logged-out auth guards (still no session)
goto "https://www.saucedemo.com/checkout-step-two.html"
snap > recon/A-guard-step-two-snapshot.txt
js "() => ({path: location.pathname, title: document.title})" > recon/A-guard-step-two-route.json
grep -o 'Epic sadface[^"]*' recon/A-guard-step-two-snapshot.txt || true

# --- Phase B: each demo user -----------------------------------------------
USERS="${USERS:-standard_user problem_user performance_glitch_user error_user visual_user}"
WITH_CDE="${WITH_CDE:-1}"
for user in $USERS; do
  echo "== Phase B: $user =="
  login_as "$user" "inventory"

  goto "https://www.saucedemo.com/inventory.html"
  snap > "recon/B-$user-inventory-snapshot.txt"
  shot "screenshots/cli-$user-inventory.png"
  js "() => [...document.querySelectorAll('.inventory_item')].map(e => { const img = e.querySelector('img'); return {name: e.querySelector('.inventory_item_name').textContent, price: e.querySelector('.inventory_item_price').textContent, src: img.getAttribute('src'), currentSrc: (img.currentSrc || '').split('/').pop(), w: img.naturalWidth}; })" > "recon/B-$user-inventory.json"
  js "() => [...document.querySelectorAll('select.product_sort_container option')].map(o => o.textContent)" > "recon/B-$user-sort-options.json"
  js "() => { const n = performance.getEntriesByType('navigation')[0]; return n ? {domContentLoadedMs: Math.round(n.domContentLoadedEventEnd), loadMs: Math.round(n.loadEventEnd)} : null; }" > "recon/B-$user-nav-timing.json"
  js "() => document.querySelector('.shopping_cart_badge') ? document.querySelector('.shopping_cart_badge').textContent : '(no badge)'" > "recon/B-$user-cart-badge.json"

  for id in 0 1 2 3 4 5; do
    goto "https://www.saucedemo.com/inventory-item.html?id=$id"
    js "() => ({name: document.querySelector('.inventory_details_name')?.textContent ?? null, desc: (document.querySelector('.inventory_details_desc')?.textContent ?? '').slice(0,80), price: document.querySelector('.inventory_details_price')?.textContent ?? null, img: document.querySelector('.inventory_details_img')?.getAttribute('src') ?? null})" > "recon/B-$user-item-$id.json"
  done
  goto "https://www.saucedemo.com/inventory-item.html?id=0"
  shot "screenshots/cli-$user-item-0.png"

  goto "https://www.saucedemo.com/cart.html"
  snap > "recon/B-$user-cart-snapshot.txt"
  shot "screenshots/cli-$user-cart.png"

  goto "https://www.saucedemo.com/checkout-step-one.html"
  snap > "recon/B-$user-checkout-one-snapshot.txt"
  shot "screenshots/cli-$user-checkout-one.png"

  goto "https://www.saucedemo.com/checkout-step-two.html"
  js "() => ({path: location.pathname, title: document.title, h: document.querySelector('.title')?.textContent ?? null, err: document.querySelector('[data-test=error]')?.textContent ?? null})" > "recon/B-$user-step-two.json"

  goto "https://www.saucedemo.com/checkout-complete.html"
  js "() => ({path: location.pathname, title: document.title, h: document.querySelector('.title')?.textContent ?? null, complete: document.querySelector('.complete-header')?.textContent ?? null})" > "recon/B-$user-complete.json"

  logout "$user" "B"
done

if [ "$WITH_CDE" = 1 ]; then
# --- Phase C: targeted bug checks (client-side only, nothing submitted) ----
echo "== Phase C: error_user sort + lastname =="
login_as "error_user" "inventory"
goto "https://www.saucedemo.com/inventory.html"
s="$(snap)"
combo="$(uid_of 'combobox "Sort products"' "$s")"
$CDT fill "$PAGE" "$combo" "Name (Z to A)" >/dev/null
$CDT handle_dialog "$PAGE" dismiss > recon/C-error-user-dialog.txt 2>&1 || true
# Read back: distinguish "sort silently broken" (app bug) from "fill flaked".
# Retry a few times; a fill that will not stick after retries = app bug.
k=0; sortval=""
while [ $k -lt 3 ]; do
  sortval="$(js "() => 'v=' + document.querySelector('select.product_sort_container').value" | grep -oE 'v=[a-z]+' || true)"
  case "$sortval" in *za*) break;; *) sleep 2; s="$(snap)"; combo="$(uid_of 'combobox "Sort products"' "$s" || true)"; [ -n "${combo:-}" ] && $CDT fill "$PAGE" "$combo" "Name (Z to A)" >/dev/null; k=$((k+1));; esac
done
echo "sort value after fill attempts: $sortval (want za)"
js "() => document.querySelector('select.product_sort_container').value" > recon/C-error-user-sort-value.json
snap > recon/C-error-user-sort-za-snapshot.txt
grep -oiE '(Epic sadface[^"]*|sorting[^"]{0,60})' recon/C-error-user-sort-za-snapshot.txt | head -5 || true
shot screenshots/cli-error-user-sort-error.png

goto "https://www.saucedemo.com/checkout-step-one.html"
s="$(snap)"
js "() => [...document.querySelectorAll('input')].map(i => i.outerHTML.slice(0,140))" > recon/C-error-user-checkout-inputs.json
last="$(echo "$s" | grep -i 'textbox' | grep -i 'last' | sed -n '1p' | sed 's/.*uid=\([0-9_]*\).*/\1/')"
echo "lastname uid: $last"
# Fill, then read back with retries: only a value that refuses to stick
# after retries counts as the error_user Last Name bug (not a fill flake).
k=0; lastval=""
while [ $k -lt 3 ]; do
  $CDT fill "$PAGE" "$last" "User" >/dev/null || echo "FILL-LASTNAME-FAILED"
  lastval="$(js "() => [...document.querySelectorAll('input')].slice(0,3).map(i => i.value.length).join(':')" | grep -oE '[0-9]+:[0-9]+:[0-9]+' || true)"
  case "$lastval" in ?:4:*) break;; *) sleep 2; s="$(snap)"; last="$(echo "$s" | grep -i 'textbox' | grep -i 'last' | sed -n '1p' | sed 's/.*uid=\([0-9_]*\).*/\1/' || true)"; k=$((k+1));; esac
done
echo "lastname values after fill attempts: $lastval"
js "() => [...document.querySelectorAll('input')].map(i => i.value)" > recon/C-error-user-lastname-values.json
shot screenshots/cli-error-user-checkout-one.png
logout "error_user" "C"

# --- Phase D: console + network on inventory (standard_user) ---------------
echo "== Phase D: console + network =="
login_as "standard_user" "inventory"
goto "https://www.saucedemo.com/inventory.html"
$CDT list_console_messages "$PAGE" > recon/D-console.txt || true
$CDT list_network_requests "$PAGE" > recon/D-network.txt || true
logout "standard_user" "D"

# --- Phase E: session-cookie handling --------------------------------------
# Records raw auth behavior on a fresh daemon with deterministic
# (native-setter) fills: rejected login sets a cookie anyway (E-1); menu
# Logout clears it (E-3); a later login sets its own cookie (E-4).
# NOTE: Logout *clicks* sometimes no-op (tool flake) - an immediate
# post-click cookie read can mislead; E-3 passed here. See route-map.
echo "== Phase E: session cookie handling =="
# Fresh daemon: prior runs showed input flakes accumulate on long-lived tabs.
$CDT stop >/dev/null 2>&1 || true
$CDT start --headless --isolated >/dev/null
# E-0: locked_out attempt. Fills are set deterministically via native setter
# (bypasses the CLI-fill flake); submit goes through the real Login button.
goto "https://www.saucedemo.com/" >/dev/null
sleep 3
js "() => { const set = (sel, v) => { const el = document.querySelector(sel); Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set.call(el, v); el.dispatchEvent(new Event('input', {bubbles: true})); return el.value; }; return [set('[data-test=username]', 'locked_out_user'), set('[data-test=password]', 'secret_sauce')]; }" > recon/E-0-lockedout-fill.json
s="$(snap)"; b="$(uid_of 'button "Login"' "$s")"
$CDT click "$PAGE" "$b" >/dev/null
sleep 2
js "() => ({cookie: document.cookie, err: document.querySelector('[data-test=error]')?.textContent ?? null, path: location.pathname})" > recon/E-1-locked-out-cookie.json
# E-2: standard UI login (same deterministic fill), expect inventory + cookie.
goto "https://www.saucedemo.com/" >/dev/null
sleep 3
js "() => { const set = (sel, v) => { const el = document.querySelector(sel); Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set.call(el, v); el.dispatchEvent(new Event('input', {bubbles: true})); return el.value; }; return [set('[data-test=username]', 'standard_user'), set('[data-test=password]', 'secret_sauce')]; }" > recon/E-2-standard-fill.json
s="$(snap)"; b="$(uid_of 'button "Login"' "$s")"
$CDT click "$PAGE" "$b" >/dev/null
sleep 2
js "() => ({cookie: document.cookie, path: location.pathname})" > recon/E-2-standard-cookie.json
# E-3: raw menu logout (NO cookie clearing) -> record cookie.
js "() => { document.getElementById('react-burger-menu-btn').click(); return 'drawer opened'; }" >/dev/null
s="$(snap)"; lo="$(uid_of 'button "Logout"' "$s")"
$CDT click "$PAGE" "$lo" >/dev/null
sleep 2
js "() => ({cookie: document.cookie, path: location.pathname})" > recon/E-3-after-logout-cookie.json
# E-4: problem_user submit with GUARANTEED-set fields while standard cookie
# exists. Cookie unchanged => silent no-op (bug); changed => overwrite ok.
goto "https://www.saucedemo.com/" >/dev/null
sleep 3
js "() => { const set = (sel, v) => { const el = document.querySelector(sel); Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set.call(el, v); el.dispatchEvent(new Event('input', {bubbles: true})); return el.value; }; return [set('[data-test=username]', 'problem_user'), set('[data-test=password]', 'secret_sauce')]; }" > recon/E-4-problem-fill.json
s="$(snap)"; b="$(uid_of 'button "Login"' "$s")"
$CDT click "$PAGE" "$b" >/dev/null
sleep 3
js "() => ({cookie: document.cookie, path: location.pathname})" > recon/E-4-after-relogin-cookie.json
js "() => { document.cookie = 'session-username=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/'; return 'cleared:' + document.cookie; }" >/dev/null

fi # WITH_CDE

echo "== recon complete =="
ls screenshots/cli-*.png | head -30
