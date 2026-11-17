"""Login tests TC-01..TC-04 (users parametrized)."""

import pytest

from .helpers import BASE_URL, login, login_as_standard


def test_valid_login_standard(page):
    """TC-01: standard_user lands on the products page with 6 items."""
    login_as_standard(page)
    assert page.locator(".inventory_item").count() == 6
    assert "Swag Labs" in page.title()


def test_empty_login_shows_error(page):
    """TC-02: empty submit stays on login with 'Username is required'."""
    login(page, "", "")
    assert page.url.rstrip("/") == BASE_URL
    assert "Username is required" in page.locator('[data-test="error"]').inner_text()


def test_locked_out_user_blocked(page):
    """TC-03: locked_out_user stays on login with the locked-out error."""
    login(page, "locked_out_user")
    assert page.url.rstrip("/") == BASE_URL
    err = page.locator('[data-test="error"]').inner_text()
    assert "has been locked out" in err


def test_invalid_user_rejected(page):
    """TC-04: unknown user stays on login with an Epic sadface error."""
    login(page, "no_such_user")
    assert page.url.rstrip("/") == BASE_URL
    err = page.locator('[data-test="error"]').inner_text()
    assert "Epic sadface" in err


@pytest.mark.parametrize(
    "user",
    [
        "standard_user",
        "problem_user",
        "error_user",
        "performance_glitch_user",
        "visual_user",
    ],
)
def test_all_demo_users_reach_inventory_except_locked(page, user):
    """Parametrized login: every usable demo user reaches inventory."""
    login(page, user)
    page.locator(".inventory_item").first.wait_for()
    assert page.url.endswith("/inventory.html"), (user, page.url)
