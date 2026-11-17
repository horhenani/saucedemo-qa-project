"""Glitch-user tests TC-16..TC-18.

Each test asserts CORRECT behavior and is marked xfail(strict=True) while
the known app bug stands, so a site fix shows up as an XPASS failure.
Evidence: route-map.md bugs 1-4, recon/B-*-inventory.json, manual #13/#14b/#14c.
"""

import pytest

from .helpers import STANDARD_PRICES_AZ, inventory_current_srcs, login


def _standard_srcs():
    return [
        "sauce-backpack-1200x1500-CjRW-Djj.jpg",
        "bike-light-1200x1500-DxcZRFOA.jpg",
        "bolt-shirt-1200x1500-mR0ldpVS.jpg",
        "sauce-pullover-1200x1500-BfbI-PSd.jpg",
        "red-onesie-1200x1500-BrSuq0ic.jpg",
        "red-tatt-1200x1500-E-qp6aYf.jpg",
    ]


@pytest.mark.xfail(
    strict=True,
    reason="known bug: problem_user renders the sl-404 placeholder for all items (route-map bug 1)",
)
def test_problem_user_distinct_images(page):
    """TC-16: problem_user items should each show their own image."""
    login(page, "problem_user")
    page.locator(".inventory_item").first.wait_for()
    assert sorted(inventory_current_srcs(page)) == sorted(_standard_srcs())


@pytest.mark.xfail(
    strict=True,
    reason="known bug: error_user sort control is inert, value stays az (route-map bug 3)",
)
def test_error_user_sort_orders_items(page):
    """TC-05/TC-17: error_user Z-A sort should reverse the list."""
    from .helpers import inventory_names, STANDARD_NAMES_AZ

    login(page, "error_user")
    page.locator(".inventory_item").first.wait_for()
    page.locator("select.product_sort_container").select_option("za")
    assert inventory_names(page) == list(reversed(STANDARD_NAMES_AZ))


@pytest.mark.xfail(
    strict=True,
    reason="known bug: error_user Last Name field rejects all input (route-map bug 4)",
)
def test_error_user_lastname_accepts_input(page):
    """TC-17: typing Last Name should stick."""
    login(page, "error_user")
    page.locator(".inventory_item").first.wait_for()
    page.goto("https://www.saucedemo.com/checkout-step-one.html")
    page.locator('[data-test="lastName"]').fill("User")
    assert page.locator('[data-test="lastName"]').input_value() == "User"


@pytest.mark.xfail(
    strict=True,
    reason="known bug: visual_user item 1 renders the sl-404 placeholder (route-map bug 2)",
)
def test_visual_user_item1_correct_image(page):
    """TC-18: visual_user item 1 should show the backpack image."""
    login(page, "visual_user")
    page.locator(".inventory_item").first.wait_for()
    assert inventory_current_srcs(page)[0] == "sauce-backpack-1200x1500-CjRW-Djj.jpg"


@pytest.mark.xfail(
    strict=True,
    reason="known bug: visual_user prices are randomized per session (route-map bug 2)",
)
def test_visual_user_standard_prices(page):
    """TC-18: visual_user prices should match the standard set."""
    login(page, "visual_user")
    page.locator(".inventory_item").first.wait_for()
    prices = page.locator(".inventory_item .inventory_item_price").all_text_contents()
    assert prices == STANDARD_PRICES_AZ
