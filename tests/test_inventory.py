"""Inventory tests TC-05 (sort), TC-06 (detail, parametrized ids), TC-15 (footer)."""

import pytest

from .helpers import (
    BASE_URL,
    ITEM_BY_ID,
    STANDARD_NAMES_AZ,
    inventory_names,
    inventory_prices,
    login_as_standard,
)


@pytest.fixture()
def inventory(page):
    login_as_standard(page)
    return page


def test_sort_default_az(inventory):
    """TC-05: default order is Name (A to Z)."""
    assert inventory_names(inventory) == STANDARD_NAMES_AZ


@pytest.mark.parametrize(
    "option,expected",
    [
        ("az", STANDARD_NAMES_AZ),
        ("za", list(reversed(STANDARD_NAMES_AZ))),
    ],
)
def test_sort_by_name(inventory, option, expected):
    """TC-05: name sorts reorder the list."""
    inventory.locator("select.product_sort_container").select_option(option)
    assert inventory_names(inventory) == expected


def _prices(page):
    return [float(p.strip("$")) for p in inventory_prices(page)]


def test_sort_by_price(inventory):
    """TC-05: price sorts order low->high then high->low (ties in any order)."""
    inventory.locator("select.product_sort_container").select_option("lohi")
    lohi = _prices(inventory)
    assert lohi == sorted(lohi) and (lohi[0], lohi[-1]) == (7.99, 49.99)
    inventory.locator("select.product_sort_container").select_option("hilo")
    hilo = _prices(inventory)
    assert hilo == sorted(hilo, reverse=True) and (hilo[0], hilo[-1]) == (49.99, 7.99)


@pytest.mark.parametrize("item_id", [0, 1, 2, 3, 4, 5])
def test_product_detail(page, item_id):
    """TC-06: every detail page shows name/price/image and links back."""
    name, price = ITEM_BY_ID[item_id]
    login_as_standard(page)
    page.goto(f"{BASE_URL}/inventory-item.html?id={item_id}", wait_until="domcontentloaded")
    assert page.locator(".inventory_details_name").inner_text() == name
    assert price in page.locator(".inventory_details_price").inner_text()
    assert page.locator(".inventory_details_img").get_attribute("src")
    page.get_by_text("Back to products", exact=True).click()
    assert page.url.endswith("/inventory.html"), page.url


def test_footer_links(page):
    """TC-15: footer links point at the saucelabs profiles."""
    login_as_standard(page)
    hrefs = page.locator("footer a").evaluate_all("els => els.map(e => e.href)")
    assert any("x.com/saucelabs" in h for h in hrefs), hrefs
    assert any("facebook.com/saucelabs" in h for h in hrefs), hrefs
    assert any("linkedin.com/company/sauce-labs" in h for h in hrefs), hrefs
