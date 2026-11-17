# Manual test results — saucedemo.com

Site: https://www.saucedemo.com

Screenshots: ./screenshots/

Password for all users: secret_sauce

I tested with standard_user first, then I compared the other users.

## 1. Open login page — no user
Steps:
- Opened https://www.saucedemo.com
Result: Pass. Login page shows 6 user names, password, Username, Password, Login.
Screenshot: manual-1.png

## 2. Login with empty fields — no user
Steps:
- Clicked Login with empty fields.
Result: Pass. Stay on login. Error: Epic sadface: Username is required.
Screenshot: manual-2.png

## 3. Locked out user — locked_out_user
Steps:
- Typed locked_out_user + secret_sauce, clicked Login.
Result: Pass. Stay on login. Error: Epic sadface: Sorry, this user has been locked out.
Screenshot: manual-3.png

## 4. Normal login — standard_user
Steps:
- Typed standard_user + secret_sauce, clicked Login.
Result: Pass. Go to Products. See 6 items. Sort is A to Z.
Screenshot: manual-4.png

## 5. Sort products — standard_user
Steps:
- Changed sort to each of the 4 options.
Result: Pass. Order changes each time.
Screenshot: manual-5.png

## 6. Open product detail — standard_user
Steps:
- Clicked one product name.
Result: Pass. See big image, price, Add to cart, Back to products.
Screenshot: manual-6.png

## 7. Add to cart — standard_user
Steps:
- Clicked Add to cart on Backpack.
Result: Pass. Button changes to Remove. Cart shows 1.
Screenshot: manual-7.png

## 8. Open cart — standard_user
Steps:
- Clicked the cart icon.
Result: Pass. See 1 item, $29.99. See Remove, Continue Shopping, Checkout.
Screenshot: manual-8.png

## 9. Checkout with empty form — standard_user
Steps:
- Clicked Checkout, then clicked Continue with empty fields.
Result: To confirm. Stay on form. See Checkout: Your Information, First Name, Last Name, Zip, Cancel, Continue. Need to check for First Name is required.
Screenshot: manual-9.png

## 10. Fill checkout form — standard_user
Steps:
- Typed First Name Test, Last Name User, Zip 12345, clicked Continue.
Result: Pass on second try. Go to Overview. See card, shipping, total $32.39. First try went back to login with: You can only access '/checkout-step-two.html' when you are logged in. Needs one more check.
Screenshots: manual-10a.png, manual-10b.png, manual-10c.png

## 11. Finish order — standard_user
Steps:
- Clicked Finish.
Result: Pass. See Thank you for your order. See Back Home and Generate PDF order.
Screenshot: manual-11.png

## 12. Logout — standard_user
Steps:
- Opened Menu, clicked Logout.
Result: Pass. Back to login.
Screenshot: manual-12a.png

## 13. Buy flow with problem user — problem_user
Steps:
- Logged in with problem_user, bought one item with same steps as above.
Result: Fail. All products show the same images. Checkout form is broken. Typed First Name, then typed Last Name and First Name cleared and left only one letter.
Screenshot: manual-13a.png
Video: manual-13.gif

## 14a. Slow user — performance_glitch_user
Steps:
- Logged in with performance_glitch_user, added one item.
Result: Slow as expected for this user. LCP 5.09s.
Screenshot: manual-14a.png

## 14b. Error user — error_user
Steps:
- Logged in with error_user, tried sort, remove, product view, checkout.
Result: Fail. Sort shows error. Remove from card fails. Remove in product detail fails. Product detail has no description. Remove in cart works. Cannot type in Last Name. Continue goes to Overview but Finish shows error.
Screenshots: manual-14b-sorting-error.png, manual-14b-remove-error.png, manual-14b-product-view-error.png, manual-14b-finish-checkout-error.png

## 14c. Visual user — visual_user
Steps:
- Logged in with visual_user, checked products, cart, product view.
Result: Fail. Page looks broken. Item 1 has wrong image. Cart button in wrong place. Cart page buttons in wrong place. Product view cart button in wrong place.
Screenshot: manual-14c-wrong-item1-image.png

## 15. Footer and reset — standard_user
Steps:
- Clicked footer links, tried Reset App State from menu.
Result: Links pass. Reset clears cart and badge, but Remove does not go back to Add to cart. Needs re-check.
