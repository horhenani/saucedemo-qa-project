"""Shared helpers for the saucedemo pytest suite.

Selectors are data-test hooks verified via CLI recon (recon/*.json|txt).
PASSWORD is the site's public demo credential (printed on the login page).
"""

BASE_URL = "https://www.saucedemo.com"
PASSWORD = "secret_sauce"

STANDARD_NAMES_AZ = [
    "Sauce Labs Backpack",
    "Sauce Labs Bike Light",
    "Sauce Labs Bolt T-Shirt",
    "Sauce Labs Fleece Jacket",
    "Sauce Labs Onesie",
    "Test.allTheThings() T-Shirt (Red)",
]
STANDARD_PRICES_AZ = ["$29.99", "$9.99", "$15.99", "$49.99", "$7.99", "$15.99"]
# inventory-item.html ids in the current (redesigned) site layout.
ITEM_BY_ID = {
    0: ("Sauce Labs Bike Light", "$9.99"),
    1: ("Sauce Labs Bolt T-Shirt", "$15.99"),
    2: ("Sauce Labs Onesie", "$7.99"),
    3: ("Test.allTheThings() T-Shirt (Red)", "$15.99"),
    4: ("Sauce Labs Backpack", "$29.99"),
    5: ("Sauce Labs Fleece Jacket", "$49.99"),
}


def login(page, user, password=PASSWORD):
    """Fill the login form and submit. Caller asserts the outcome."""
    page.goto(BASE_URL + "/", wait_until="domcontentloaded")
    page.locator('[data-test="username"]').fill(user)
    page.locator('[data-test="password"]').fill(password)
    page.locator('[data-test="login-button"]').click()


def login_as_standard(page):
    login(page, "standard_user")
    page.locator(".inventory_item").first.wait_for()
    assert page.url.endswith("/inventory.html"), page.url


def logout(page):
    page.locator("#react-burger-menu-btn").click()
    page.get_by_text("Logout", exact=True).click()


def inventory_names(page):
    return page.locator(".inventory_item .inventory_item_name").all_text_contents()


def inventory_prices(page):
    return page.locator(".inventory_item .inventory_item_price").all_text_contents()


def inventory_current_srcs(page):
    return page.eval_on_selector_all(
        ".inventory_item img", "els => els.map(e => e.currentSrc.split('/').pop())"
    )


def add_to_cart(page, name):
    page.locator(".inventory_item", has_text=name).get_by_role(
        "button", name="Add to cart"
    ).click()


def open_cart(page):
    page.locator(".shopping_cart_link").click()
    assert page.url.endswith("/cart.html"), page.url


def fill_checkout(page, first="Test", last="User", zip_code="12345"):
    page.locator('[data-test="firstName"]').fill(first)
    page.locator('[data-test="lastName"]').fill(last)
    page.locator('[data-test="postalCode"]').fill(zip_code)
    page.locator('[data-test="continue"]').click()
