# AI accuracy log — recon + test runs

AI was fast at mapping, but often wrong on clicks. Manual runs are truth.
7 claims were correct and became bugs. 8 were wrong and were fixed before final docs.
Main lesson: always check cookie and read values back, never trust one tool output.

| # | Claim | How checked | Verdict | Impact |
|---|---|---|---|---|
| 1 | problem_user: all 6 images are the sl-404 placeholder | DOM `src`+`currentSrc` per item, cookie-verified session; human #13 | correct | none — stands as BUG-1 |
| 2 | visual_user: item-1 image sl-404 + randomized prices | DOM dump + screenshot; prices differ across runs ($81.3 vs $23.22); human #14c | correct | none — stands as BUG-7 |
| 3 | error_user: sort change silently ignored | fill + readback `v=az` after retries + transient dialog; human #14b | correct | none — stands as BUG-3 |
| 4 | error_user: Last Name accepts no input | CLI fill readback `0:0:0` + native-setter also wiped; human #14b | correct | none — stands as BUG-5 (native-setter test ruled out tool flake) |
| 5 | locked_out login is rejected but still sets the cookie | E-1: cookie + error text recorded together | correct | low — observation only, harmless quirk |
| 6 | Logged-out step-two GET yields the guard error | Direct GET on clean session, error text captured | correct | none — TC-12 automated on it |
| 7 | Checkout-complete renders on direct GET with empty cart | `complete-header` text read on logged-in empty-cart session | correct | low — documented as login-guarded-only route |
| 8 | problem_user hamburger menu is broken (drawer never opens) | Re-tested with DOM `.click()` — drawer opens fine | wrong | medium — false bug entered a route-map draft + script fallback; corrected before final docs |
| 9 | Menu Logout does not clear `session-username` | repro4: 3/3 logout-click → navigate `/` + empty cookie | wrong | medium — spawned the false "silent no-op login" theory (#10) and extra script complexity |
| 10 | Login with an existing session is a silent no-op | Disproven: run#2 problem render after standard session; overwrite works; earlier reads were unwiped-fill artifacts | wrong | high — mislabeled two full recon runs' worth of per-user data (run#2 error/visual/performance, all of C2) |
| 11 | `sessionStorage.clear()` logs a user out | Cookie reads before/after: unchanged; auth lives in the cookie | wrong | high — root cause of #10's mislabeled data; fixed by cookie asserts + forced clear in script |
| 12 | All glitch users render the same-dog inventory | Sessions were cross-contaminated (see #10/#11); re-ran with verified sessions — each user renders distinctly | wrong | high — bad evidence deleted (C2 artifacts), runs repeated |
| 13 | CLI `fill`/`click` "success" means the app received it | Numeric read-backs showed `[0:0]` after reported success, repeatedly | partly | high — drove the whole verify-after-every-action discipline; exact wipe mechanism (pre-hydration vs dead DOM) never isolated |
| 14 | Same-URL `navigate_page` may leave a stale DOM; snapshots can lag | Frozen uid prefixes + same-dog screenshots across users observed; forced `--type reload` + re-snapshot fixed symptoms | partly | medium — mechanism inferred, not proven; mitigations work in practice |
| 15 | Quoted-value greps (`"[^"]*"`) are safe on `--output-format=json` | They silently never match escaped output; numeric/`v=` patterns match reliably | wrong (practice) | medium — one failed run + misleading `[0:0]`-style logs before the switch |
| 16 | Test suite: 29 pass, 5 strict-xfail, fail-screenshots on failure | Full run green; forced-failure probe produced `fail-*.png`; `-rX` lists all 5 reasons | correct | none — suite is the trusted artifact |
| 17 | Item ids are 0=Backpack… (classic layout memory) | Measured per-id dumps: 0=Bike Light…4=Backpack…5=Fleece | wrong | low — caught by data before any test used it |
| 18 | `sl-404-*.jpg` is a file to store | It is the site's own asset URL, evidence-only text in dumps | wrong (assumption) | low — one clarification, no action needed |

## Patterns that caught the errors
- Cookie + landing-page asserts after every login/logout (killed #10/#11 silently corrupting data).
- Numeric read-backs after every fill (killed #13 masking as app bugs).
- Never claim from a single tool output; re-probe with a different mechanism
  (DOM click vs CLI click settled #8; native setter settled #4).
- Strict xfail: if a site fix lands, XPASS fails loudly instead of rotting.
