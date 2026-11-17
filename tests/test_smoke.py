"""Smoke test: open saucedemo.com in system Chrome and verify login page."""

from pathlib import Path


def test_saucedemo_login_page_loads(page):
    page.goto("https://www.saucedemo.com", wait_until="domcontentloaded")

    # Title is "Swag Labs" (assert loosely to survive copy changes).
    assert "Swag Labs" in page.title()

    # Core login UI must be visible.
    for selector in ('[data-test="username"]', '[data-test="password"]', '[data-test="login-button"]'):
        assert page.locator(selector).is_visible(), f"expected visible: {selector}"

    # Save a screenshot as proof (goes to artifacts/, kept out of git).
    out = Path(__file__).resolve().parent.parent / "artifacts" / "smoke-saucedemo.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    page.screenshot(path=str(out))
    assert out.exists() and out.stat().st_size > 0
