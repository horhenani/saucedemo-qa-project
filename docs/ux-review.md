# UX review — saucedemo.com as a real shopper (standard_user)

Basis: manual run (#1–#12, #15) + CLI screenshots. Only issues a normal
shopper would hit; demo-user glitches are bugs, not UX (see `docs/bugs.md`).

## UX-1 — Error messages speak developer, not shopper
Login failures say `Epic sadface: Username is required` /
`Epic sadface: Sorry, this user has been locked out`; the logged-out guard
says `You can only access '/checkout-step-two.html' when you are logged in.`
A shopper learns nothing actionable (no "try…", no link back, route paths
leaked). Fix: plain-language errors tied to the field or next step, e.g.
"Enter your username to continue" / "Continue shopping", and never expose
internal route names.
Screenshot: `screenshots/manual-2.png`, `screenshots/manual-3.png`

## UX-2 — Order confirmation has no order reference or summary
Finish lands on `Thank you for your order` + Back Home, with no order
number, no item recap, no total, no email note. A shopper can't prove,
track, or dispute the purchase. Fix: show an order number + item/total
summary + "a confirmation was sent to …" on the complete page.
Screenshot: `screenshots/manual-11.png`

## UX-3 — Checkout gives no inline, per-field guidance
Empty Continue just redisplays the form; password rules, zip format, and
which field failed are never stated inline (manual #9 left the exact error
text unconfirmed). Shoppers guess-and-resubmit. Fix: inline messages under
each field on submit + format hints next to Zip.
Screenshot: `screenshots/manual-9.png`, `screenshots/manual-10a.png`

## UX-4 — Cart badge vanishes at zero instead of showing 0
With an empty cart the header shows no badge at all; it appears only once
an item is added (compare manual-8 vs any empty-cart shot). The cart icon
looks broken/absent rather than empty. Fix: always render the badge
(`0` when empty) so the control is stable.
Screenshot: `screenshots/manual-8.png` (badge `1`) vs
`screenshots/cli-standard_user-cart.png` (no badge when empty)

## UX-5 — About + social links silently navigate away mid-shop
The hamburger About link and the X/Facebook/LinkedIn footer icons leave
the shop for external sites with no new-tab or "you are leaving" cue —
a shopper mid-checkout loses context (cart survives, but the flow breaks).
Fix: open externals in a new tab with an icon/aria hint.
Screenshot: `screenshots/cli-standard_user-inventory.png` (footer icons)
