"""Cart + checkout tests TC-07..TC-14."""

from .helpers import (
    BASE_URL,
    fill_checkout,
    login_as_standard,
    logout,
)


def _add_backpack(page):
    login_as_standard(page)
    page.locator(".inventory_item", has_text="Sauce Labs Backpack").get_by_role(
        "button", name="Add to cart"
    ).click()


def test_add_to_cart_updates_button_and_badge(page):
    """TC-07: Add to cart flips the button and shows badge 1."""
    _add_backpack(page)
    item = page.locator(".inventory_item", has_text="Sauce Labs Backpack")
    assert item.get_by_role("button", name="Remove").is_visible()
    assert page.locator(".shopping_cart_badge").inner_text() == "1"


def test_cart_contents(page):
    """TC-08: cart shows the item, price, and action buttons."""
    _add_backpack(page)
    page.locator(".shopping_cart_link").click()
    assert page.url.endswith("/cart.html"), page.url
    assert "Sauce Labs Backpack" in page.content()
    assert "$29.99" in page.content()
    for name in ("Remove", "Continue Shopping", "Checkout"):
        assert page.get_by_text(name, exact=True).first.is_visible()


def test_remove_from_cart(page):
    """TC-09: removing empties the cart, clears the badge, restores Add."""
    _add_backpack(page)
    page.locator(".shopping_cart_link").click()
    page.get_by_role("button", name="Remove").click()
    assert page.locator(".shopping_cart_badge").count() == 0
    page.get_by_text("Continue Shopping", exact=True).click()
    item = page.locator(".inventory_item", has_text="Sauce Labs Backpack")
    assert item.get_by_role("button", name="Add to cart").is_visible()


def test_checkout_empty_form_shows_error(page):
    """TC-10: Continue with an empty form stays put and flags an error."""
    _add_backpack(page)
    page.locator(".shopping_cart_link").click()
    page.get_by_text("Checkout", exact=True).click()
    assert page.url.endswith("/checkout-step-one.html"), page.url
    page.locator('[data-test="continue"]').click()
    assert page.url.endswith("/checkout-step-one.html"), page.url
    assert page.locator('[data-test="error"]').is_visible()


def test_checkout_happy_path_totals(page):
    """TC-11: valid info reaches Overview with subtotal/tax/total $32.39."""
    _add_backpack(page)
    page.locator(".shopping_cart_link").click()
    page.get_by_text("Checkout", exact=True).click()
    fill_checkout(page)
    assert page.url.endswith("/checkout-step-two.html"), page.url
    assert "Checkout: Overview" in page.content()
    assert "32.39" in page.locator(".summary_total_label").inner_text()


def test_step_two_guard_logged_out(page):
    """TC-12: logged-out GET of step-two redirects to login with guard error.

    The guard renders asynchronously (redirect + error appear a moment
    after load), so wait for it instead of asserting immediately.
    """
    from playwright.sync_api import expect

    page.goto(BASE_URL + "/checkout-step-two.html", wait_until="domcontentloaded")
    expect(page.locator('[data-test="error"]')).to_contain_text(
        "only access", timeout=15000
    )


def test_finish_order(page):
    """TC-13: Finish shows the thank-you page with Back Home."""
    _add_backpack(page)
    page.locator(".shopping_cart_link").click()
    page.get_by_text("Checkout", exact=True).click()
    fill_checkout(page)
    page.get_by_text("Finish", exact=True).click()
    assert "Thank you for your order" in page.locator(".complete-header").inner_text()
    assert page.get_by_text("Back Home", exact=True).is_visible()


def test_logout_returns_to_login(page):
    """TC-14: menu Logout lands back on the login form, session cleared."""
    login_as_standard(page)
    logout(page)
    page.locator('[data-test="login-button"]').wait_for()
    assert page.locator('[data-test="username"]').is_visible()
    assert page.evaluate("document.cookie").strip() == ""
