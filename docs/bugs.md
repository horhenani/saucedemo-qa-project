# Bugs — saucedemo.com (human-observed only)

Source: `manual-human-check.md` (#13, #14b, #14c) + CLI cross-checks in
`route-map.md`. Scope rule for this file: only bugs the human tester saw.
Tool-only observations stay in `route-map.md`.

## BUG-1 — problem_user: all products show the same image
- Steps: log in as `problem_user` / `secret_sauce` → open Products.
- Expected: each of the 6 items shows its own photo.
- Actual: every item shows the same dog-with-ball photo (the site's
  `sl-404` placeholder served as `src` + `currentSrc` for all 6).
- Severity: Medium — buying still works, but products are unidentifiable.
- Screenshot: `screenshots/manual-13a.png`, `screenshots/cli-problem_user-inventory.png`
- Evidence: `recon/B-problem_user-inventory.json` (1 distinct `currentSrc`).

## BUG-2 — problem_user: typing Last Name wipes First Name
- Steps: problem_user → add item → Checkout → type First Name, then type Last Name.
- Expected: both fields keep their values.
- Actual: typing Last Name clears First Name, leaving a single letter.
- Severity: High — checkout form cannot be completed normally.
- Screenshot/video: `screenshots/manual-13a.png`, `screenshots/manual-13.gif`

## BUG-3 — error_user: sorting fails with an error
- Steps: log in as `error_user` → change sort to Name (Z to A).
- Expected: list reorders Z→A.
- Actual: error popup; sort stays on Name (A to Z). CLI: fill reports
  success + transient dialog, value reads back `az` after retries.
- Severity: Medium — list unusable in any other order.
- Screenshot: `screenshots/manual-14b-sorting-error.png`,
  `screenshots/cli-error-user-sort-error.png`
- Evidence: `recon/C-error-user-sort-value.json` (`"az"`), `recon/C-error-user-dialog.txt`.

## BUG-4 — error_user: remove fails, product detail has no description
- Steps: error_user → remove from card → remove in product detail → open a
  product detail page.
- Expected: item removed; detail shows name, description, price.
- Actual: remove fails on card and in detail (works in cart); detail page
  shows no description.
- Severity: Medium — cart can only be fixed from the cart page; details incomplete.
- Screenshots: `screenshots/manual-14b-remove-error.png`,
  `screenshots/manual-14b-product-view-error.png`

## BUG-5 — error_user: cannot type in Last Name
- Steps: error_user → Checkout → try to type in Last Name.
- Expected: field accepts text.
- Actual: nothing sticks — field reads back empty via typing AND via
  programmatic set (CLI native-setter returns `""`, `0:0:0` after retries).
- Severity: High — checkout blocked for this user.
- Screenshot: `screenshots/cli-error-user-checkout-one.png`;
  Evidence: `recon/C-error-user-lastname-values.json`

## BUG-6 — error_user: Finish checkout shows an error
- Steps: error_user → fill form → Continue (reaches Overview) → Finish.
- Expected: thank-you order confirmation.
- Actual: error instead of the completed order.
- Severity: High — this user can never complete a purchase.
- Screenshot: `screenshots/manual-14b-finish-checkout-error.png`

## BUG-7 — visual_user: wrong item-1 image, wrong prices, misplaced buttons
- Steps: log in as `visual_user` → Products, cart, product view.
- Expected: item 1 shows the backpack photo with $29.99; buttons aligned.
- Actual: item 1 shows the placeholder photo; prices are randomized
  ($81.3/$94.54/… this run vs $23.22/… in the manual run); cart button
  overlaps the sort control; cart/detail buttons misplaced.
- Severity: Medium — prices shown are wrong, which is purchase-relevant.
- Screenshot: `screenshots/manual-14c-wrong-item1-image.png`,
  `screenshots/cli-visual_user-inventory.png`
- Evidence: `recon/B-visual_user-inventory.json` (item 1 `currentSrc` sl-404).

## Seen but NOT filed as bugs (needs re-check)
- #9: empty-checkout Continue — stays on form; exact error text unconfirmed.
- #10 first-try: guard redirect (`You can only access…`) mid-checkout on first
  attempt, passed on retry — needs one more check.
- #15: Reset App State clears cart/badge but Remove buttons don't flip back
  to Add to cart — needs re-check.
