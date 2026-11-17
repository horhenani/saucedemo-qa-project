# saucedemo.com — test report (one page)

34 pytest tests (29 pass, 5 strict-xfail) + read-only CLI recon + manual run.
Suite: `tests/` (pytest + Playwright, system Chrome). Docs: [route-map.md](route-map.md),
[docs/test-plan.md](docs/test-plan.md) (TC-01–TC-20), [docs/bugs.md](docs/bugs.md), [docs/ux-review.md](docs/ux-review.md),
[manual-human-check.md](manual-human-check.md), [docs/ai-accuracy-log.md](docs/ai-accuracy-log.md).

## Bugs (all human-seen, CLI cross-checked — full list: [docs/bugs.md](docs/bugs.md))
| ID | Bug | Severity |
|---|---|---|
| BUG-1 | problem_user: all 6 images render the sl-404 placeholder | Medium |
| BUG-2 | problem_user: typing Last Name wipes First Name (checkout blocked) | High |
| BUG-3 | error_user: sort change silently ignored (stays az) | Medium |
| BUG-4 | error_user: remove fails on card/detail; detail has no description | Medium |
| BUG-5 | error_user: Last Name rejects all input (typing and programmatic) | High |
| BUG-6 | error_user: Finish shows an error, order never completes | High |
| BUG-7 | visual_user: item-1 image sl-404, prices randomized, buttons misplaced | Medium |
Open (not bugs yet): empty-checkout error text, first-try guard redirect, Reset App State revert.

## UX fixes (real-shopper issues, each with screenshot + fix in [docs/ux-review.md](docs/ux-review.md))
1. Jargon errors (`Epic sadface`, route paths) → plain-language, per-field messages.
2. Confirmation page has no order number/summary → add order ref + recap.
3. Checkout gives no inline per-field guidance → inline validation + format hints.
4. Cart badge vanishes at 0 → always render it.
5. About/social links leave the shop silently → new tab + leaving hint.

## Why this approach
Core buy flows run in pytest for repeatability: each test gets a clean browser session and exact asserts.
Read-only CLI recon maps routes and glitch renders without changing shop state.
Manual runs are ground truth for timing, visuals, and submits: every auto result is checked against manual, not the reverse.

## Where AI helped / was wrong (full log: [docs/ai-accuracy-log.md](docs/ai-accuracy-log.md))
Helped: found the `session-username` cookie auth model, the sl-404 placeholder
mechanism, forced numeric read-backs + session asserts that made the harness
self-checking; converted 5 known bugs into strict-xfail tests.
Wrong (all corrected, none in final claims): "broken" problem_user menu and
"persistent session" — both were no-op CLI clicks, disproven by retest;
two runs' per-user data mislabeled via a no-op session clear — discarded,
rerun with verified sessions; quoted-grep patterns that silently never match.
