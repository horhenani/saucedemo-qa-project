# Test plan — saucedemo.com

Sources: `route-map.md` (CLI recon) + `manual-human-check.md` (human runs
#1–#15). Password for all users: `secret_sauce` (public demo credential).

## Scope

IN: login/logout, product list + sort, product detail, cart add/remove,
checkout form validation + happy path + guards, order finish, footer links,
per-user glitch behaviors (problem / error / visual / performance_glitch /
locked_out).
OUT: Reset App State behaviors (human #15 open — re-check manually first),
load/stress testing, real payments (none exist), backend/API testing
(static frontend).

## Risks
- External demo site: UI, ids, prices, glitch behavior can change without
  notice (ids already differ from the classic layout — see route-map).
- `visual_user` prices are randomized per session; assertions must be
  relational (e.g. "differs from standard"), not exact.
- Session = `session-username` cookie; `/` never redirects, stale sessions
  silently persist — tests must assert the session (see AGENTS.md).
- Tool flakes in CLI-driven checks (fill/click no-ops); pytest+Playwright
  flows are the stable automation path.

## Cases (20)

| ID | Case (manual ref) | Steps (abridged) | Expect | Auto? |
|---|---|---|---|---|
| TC-01 | Valid login (#4) | standard_user + login | → `/inventory.html`, 6 items, sort A–Z | YES |
| TC-02 | Empty login (#2) | Login with empty fields | stay on `/`, `Username is required` | YES |
| TC-03 | Locked out (#3) | locked_out_user + login | stay on `/`, `…has been locked out` | YES |
| TC-04 | Invalid user (new) | bogus user + login | stay on `/`, `do not match` error | YES |
| TC-05 | Sort all 4 (#5) | standard: set az/za/lohi/hilo | order changes each time, value sticks | YES |
| TC-06 | Product detail (#6) | open ids 0–5 | name/desc/price/image present, Back button works | YES (data-driven) |
| TC-07 | Add to cart (#7) | Backpack Add to cart | button → Remove, badge `1` | YES |
| TC-08 | Cart contents (#8) | open cart | 1 item, $29.99, Remove / Continue / Checkout visible | YES |
| TC-09 | Remove from cart | remove the item | cart empty, badge gone, button back to Add to cart (human #15: re-check Remove→Add revert) | YES |
| TC-10 | Checkout empty (#9) | Checkout → Continue empty | stay on step-one, `First Name is required` | YES |
| TC-11 | Checkout happy path (#10) | Test/User/12345 → Continue | → Overview, totals $32.39 | YES |
| TC-12 | Step-two guard (#10) | logged-out GET step-two | `You can only access…` error, no overview | YES |
| TC-13 | Finish order (#11) | Finish | `Thank you for your order`, Back Home | YES |
| TC-14 | Logout (#12) | menu → Logout | → `/` login, session cookie cleared | YES |
| TC-15 | Footer links (#15) | footer X/Facebook/LinkedIn | hrefs point at saucelabs profiles | YES (href assert) |
| TC-16 | problem_user images (#13) | login, read 6 `currentSrc` | all = sl-404 placeholder | YES |
| TC-17 | error_user blocks (#14b) | sort→Z-A; type Last Name | value stays `az`; lastname reads back empty | YES |
| TC-18 | visual_user render (#14c) | login, read images + prices | item 1 = sl-404, prices ≠ standard set | YES (image+price asserts; pixel layout MANUAL) |
| TC-19 | performance_glitch (#14a) | login, add item, measure | completes; LCP ≈ 5s (tolerance, may vary) | MANUAL (timing flaky in CI) |
| TC-20 | Reset App State (#15) | add item → menu Reset | cart+bench cleared; verify Remove→Add revert (open question) | MANUAL until clarified |

18 automatable (TC-01–TC-18),
2 manual (TC-19 timing judgment, TC-20 open question + TC-18 pixel layout).

## Automation notes
- Stack: pytest + Playwright, `channel="chrome"` (no browser download);
  assert `document.cookie` session after each login (AGENTS.md).
- Visual asserts via `currentSrc`/`naturalWidth`, never `src` alone
  (glitch users get decoy `src`); never assert exact visual_user prices.
- Keep CLI recon (`agent/recon-commands.sh`) for read-only mapping;
  put submitting flows (cart/checkout/finish) in pytest, not in recon.
