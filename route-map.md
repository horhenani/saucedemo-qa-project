# saucedemo.com — route map + bug map (chrome-devtools CLI recon, read-only)

Manual ground truth: [manual-human-check.md](manual-human-check.md).
Repro: [agent/recon-commands.sh](agent/recon-commands.sh) — headless isolated
browser; interactions limited to login/logout, client-side sort change, and
typing into (never submitting) the checkout form. No cart writes, no order
submits, no reset. Raw captures: `recon/` (snapshots, DOM dumps, route
probes), `screenshots/cli-*.png`.

Status legend: CLI-verified = seen in this recon on a session-verified
cookie · human-confirmed = manual-human-check.md.

## Routes (all verified via CLI navigate + snapshot)

| Route | Screen | Auth | Notes |
|---|---|---|---|
| `/` | Login (Swag Labs) | public | 6 demo usernames + `secret_sauce` hint; empty submit → `Username is required`; always renders login form even with an active session |
| `/inventory.html` | Products (6 items, sort A–Z default) | login required | sort options: az / za / lohi / hilo (recon/B-*-sort-options.json) |
| `/inventory-item.html?id=0..5` | Product detail (image, name, desc, price, back) | login required | ids: 0 Bike Light 9.99 · 1 Bolt T-Shirt 15.99 · 2 Onesie 7.99 · 3 Red T-Shirt 15.99 · 4 Backpack 29.99 · 5 Fleece Jacket 49.99 (recon/B-standard_user-item-*.json) |
| `/cart.html` | Your Cart (empty: Continue Shopping, Checkout) | login required | mapped empty; recon adds nothing |
| `/checkout-step-one.html` | Checkout: Your Information (First/Last/Zip, Cancel/Continue) | login required | fields have no id/name attrs (console warning, recon/D-console.txt) |
| `/checkout-step-two.html` | Checkout: Overview | login required, guarded | logged-out GET: `You can only access '/checkout-step-two.html' when you are logged in.` (recon/A-guard-*); logged-in renders even with empty cart |
| `/checkout-complete.html` | `Thank you for your order!` + Back Home | login required (only) | renders on direct GET with empty cart — no order required (recon/B-standard_user-complete.json) |
| menu → About | external `https://saucelabs.com/` | n/a | footer: X / Facebook / LinkedIn (saucelabs); all links present in snapshots |
| menu → Logout | returns to `/` login | — | CLI-verified 3/3 to clear `session-username` (/tmp/repro4.sh); auth cookie, see §4 |
| menu → Reset App State | clears cart/badge | — | NOT exercised (forbidden in recon); human notes Remove buttons don't revert (manual #15, needs re-check) |

## Users (password: `secret_sauce`)

| User | Login | Inventory render (CLI-verified) | Result |
|---|---|---|---|
| standard_user | OK → `/inventory.html` | 6 distinct correct images, standard prices | baseline; cart badge `(no badge)`; nav timing ~90ms |
| locked_out_user | blocked, stays on `/` | n/a (never leaves login) | `Epic sadface: Sorry, this user has been locked out.` — rejected login still sets `session-username=locked_out_user` cookie (observation, harmless: guards still redirect) |
| problem_user | OK | **all 6 images = sl-404 placeholder** (src + currentSrc, w=600) | FAIL — same image everywhere (human #13) |
| performance_glitch_user | OK | 6 distinct correct images, standard prices | render normal; bug is speed (human LCP 5.09s, manual #14a); inventory nav itself ~90ms in headless |
| error_user | OK | 6 distinct correct images, standard prices | FAIL on interaction (see §3) |
| visual_user | OK (via cookie-established session, see §5) | item 1 image = sl-404 placeholder (w=600), items 2–6 correct; **randomized prices** ($81.3/$94.54/… this run vs $23.22/… human run); cart icon overlapping sort dropdown | FAIL — wrong item-1 image, wrong prices, misplaced buttons (human #14c) |

`sl-404-Cq1a9k9X.jpg` is the site's own 404 placeholder (a pug photo): wherever
the app deliberately breaks an image URL, the placeholder renders instead.

## Bugs (CLI evidence + human cross-check)

1. **problem_user: all product images broken** — every `.inventory_item img`
   has `src` = `currentSrc` = sl-404 placeholder (recon/B-problem_user-inventory.json,
   screenshots/cli-problem_user-inventory.png). CLI-verified · human-confirmed (#13).
2. **visual_user: item-1 image broken + randomized prices + misplaced buttons** —
   item 1 currentSrc sl-404, prices differ run to run ($81.3 vs human's $23.22),
   cart icon overlaps the sort control (recon/B-visual_user-inventory.json,
   screenshots/cli-visual_user-inventory.png vs manual-14c). CLI-verified · human-confirmed (#14c).
3. **error_user: sort change silently ignored** — fill reports success (and a
   transient dialog opens), but select value stays `az` after retries
   (`sort value after fill attempts: v=az`, recon/C-error-user-sort-value.json).
   CLI-verified · human-confirmed (#14b, error popup).
4. **error_user: Last Name untypeable** — CLI fill AND native-setter input both
   read back empty (`lastname values after fill attempts: 0:0:0`, /tmp/repro5.sh
   `"after-native:"` empty); first/last/zip all empty. CLI-verified · human-confirmed
   (#14b; human also notes typing Last wipes First).
5. **No checkout-step-two guard bypass** — logged-out GET yields the
   `You can only access…` error (recon/A-guard-*). Expected behavior, verified.
6. **No session-handling bug found** — menu Logout navigates to `/` AND clears
   `session-username` 3/3 (repro4); every per-user dataset was captured on a
   cookie-verified session. Earlier contrary readings were tool flakes
   (no-op clicks, unwiped fills), documented in §5.

## Open / human-only (not covered by read-only CLI recon)

- #9: empty-checkout-continue expected error text — recon never submits forms.
- #10 first-try guard redirect mid-checkout — guard itself verified (§5), full flow not run.
- error_user remove-from-card/detail/checkout-finish errors — human #14b (requires cart writes).
- #15 Reset App State leaving Remove buttons stuck — reset not exercised.
- performance_glitch LCP 5.09s — human #14a (CLI measured DOMContentLoaded only).

## Tool quirks hit during recon (chrome-devtools-cli 1.13.0, all documented)

- **CLI `fill` intermittently doesn't stick** (most ops in long-lived tabs):
  reports success, values read back empty. Mitigation in script: numeric
  length read-back + retry; session-cookie fallback for login with explicit
  labeling (`cookie fallback` in run logs). Never trust a fill without read-back.
- **CLI `click` on the 20×20px burger is usually a silent no-op** (DOM
  `.click()` opens the drawer every time); `click` on Login/Logout works.
  Script opens the drawer via evaluate, clicks Logout via CLI.
- **Quote-bearing greps fail on `--output-format=json`** (inner quotes are
  backslash-escaped, breaking `"[^"]*"` patterns). Script uses quote-free
  patterns only (lengths, `v=`, plain tokens).
- **Same-URL `navigate_page` may not reload** — script forces `--type reload`
  before login fills to avoid stale/dead DOM.
- **Snapshots can lag one step** (uid prefixes, drawer state) — always
  re-snapshot after an action; assert identity via `document.cookie` +
  `location.pathname`, never via snapshot text alone.
