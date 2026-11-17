# AGENTS.md — saucedemo test project

## Purpose
Smoke-test, pytest suite (TC-01–TC-18) + read-only recon harness for
https://www.saucedemo.com
(demo shop, password `secret_sauce` is public by design — no secrets here).
Details: `route-map.md`. Test plan: `docs/test-plan.md`.
Manual ground truth: `manual-human-check.md`.

## Site map (condensed)
- `/` login (always renders the form, even logged in) · `locked_out_user`
  is rejected with `Epic sadface: Sorry, this user has been locked out.`
- `/inventory.html` — 6 products, sort az/za/lohi/hilo
- `/inventory-item.html?id=0..5` — 0 Bike Light · 1 Bolt T-Shirt · 2 Onesie ·
  3 Red T-Shirt · 4 Backpack · 5 Fleece Jacket
- `/cart.html`, `/checkout-step-one.html` (First/Last/Zip),
  `/checkout-step-two.html` (guarded: logged-out GET yields the
  `You can only access…` error), `/checkout-complete.html` (login-guarded only)
- Menu: About (external), Logout (`/` + clears `session-username` cookie),
  Reset App State (do NOT use — out of scope).

## Scope: in / out (read-only recon)
IN: navigate, snapshot, evaluate (DOM reads), screenshots, login/logout,
client-side sort change, typing into (never submitting) the checkout form.
OUT: cart writes, checkout submits, reset app state, order completion.

## How to run
```bash
uv venv .venv   # Python 3.14 pinned in .python-version
VIRTUAL_ENV=$PWD/.venv uv pip install -r requirements.txt
.venv/bin/python -m pytest            # full suite (34 tests): smoke + login +
                                  # inventory/cart/checkout + glitch-user xfails
.venv/bin/python -m pytest tests/test_login.py tests/test_inventory.py -q
.venv/bin/python -m pytest tests/test_glitch_users.py -v -rX   # known bugs
./scripts/verify_chrome_headless.sh   # google-chrome --headless --screenshot (+ --virtual-time-budget)
./scripts/verify_chrome_devtools.sh   # chrome-devtools CLI navigate + screenshot
./agent/recon-commands.sh                                  # full recon (A–E)
USERS="error_user visual_user" WITH_CDE=0 ./agent/recon-commands.sh   # subset
```
No `playwright install` needed: `conftest.py` uses `channel="chrome"`.
Test layout: `tests/test_login.py` (TC-01–04, users parametrized),
`tests/test_inventory.py` (TC-05/06/15), `tests/test_cart_checkout.py`
(TC-07–14), `tests/test_glitch_users.py` (TC-16–18, assert-correct-behavior
tests marked `xfail(strict=True)` with route-map bug reasons — an XPASS
means the site bug got fixed). Failures save `artifacts/fail-*.png`
(autouse fixture in `conftest.py`); each test gets a fresh browser context,
so sessions never leak between tests.
Chrome-devtools CLI via `npx -y -p chrome-devtools-mcp@latest chrome-devtools …`
(headless, isolated); always `stop` the daemon when done (scripts trap this).

## Auth model (load-bearing)
Auth = `session-username` cookie (NOT sessionStorage). `/` never redirects —
submit with an existing cookie can silently keep the old session. The script
asserts `document.cookie` after every login/logout and aborts on mismatch.

## Log prompts (record as you go)
- Keep run logs: redirect recon runs to `recon/run-*.log`; each `login_as`
  line must show `want=…` + cookie + landing page.
- Label every session: UI login vs `cookie fallback` (the log says which).
- Save raw captures (`recon/*.json|txt`, `screenshots/cli-*.png`); never
  claim a bug without a file + line to point at.

## AI mistakes to avoid (all happened here)
- Trusting CLI `fill`/`click` "success" without read-back: fills get wiped
  by React hydration, tiny buttons no-op. Always read back numerically
  (lengths, `v=`-prefixed values) — never grep quoted JSON (`"[^"]*"`
  breaks on escaped quotes).
- Re-snapshot after every action; stale snapshots/uids fail silently.
  Same-URL `navigate_page` may not reload — force `--type reload`.
- Don't claim a "broken menu" from a no-op burger click (DOM `.click()`
  works); don't claim a session bug from a racy immediate cookie read.
- Verify the user id mapping from data (0=Bike Light…), not from memory
  of the classic site. `sl-404-*.jpg` is the site's own 404 placeholder
  (renders as the stand-in dog image), not a file we store.
