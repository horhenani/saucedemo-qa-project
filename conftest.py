"""Shared pytest fixtures for Playwright + system Chrome."""

import os
import re
from pathlib import Path

import pytest
from playwright.sync_api import sync_playwright

BASE_URL = "https://www.saucedemo.com"
ARTIFACTS = Path(__file__).resolve().parent / "artifacts"

# Use headless by default in CI / servers without a display.
# Override with: HEADLESS=0 pytest
HEADLESS = os.environ.get("HEADLESS", "1") != "0"

# Fedora/Chrome sandbox: running as non-root should NOT need --no-sandbox.
# Only set CHROME_NO_SANDBOX=1 if you hit sandbox/namespace errors.
NO_SANDBOX = os.environ.get("CHROME_NO_SANDBOX", "0") == "1"


@pytest.fixture(scope="session")
def pw_browser():
    """Launch system Chrome once per session (channel="chrome": no browser download)."""
    launch_kwargs: dict = {"channel": "chrome", "headless": HEADLESS}
    if NO_SANDBOX:
        launch_kwargs["args"] = ["--no-sandbox"]
    # Wayland headless stability on Fedora: keep default headless=new.
    with sync_playwright() as p:
        browser = p.chromium.launch(**launch_kwargs)
        yield browser
        browser.close()


@pytest.fixture()
def page(pw_browser):
    """Fresh browser context + page per test: clean session every time."""
    context = pw_browser.new_context(viewport={"width": 1280, "height": 720})
    pg = context.new_page()
    yield pg
    context.close()


def _safe_name(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", name)[:120]


@pytest.hookimpl(wrapper=True)
def pytest_runtest_makereport(item, call):
    rep = yield
    setattr(item, "rep_" + rep.when, rep)
    return rep


@pytest.fixture(autouse=True)
def _shot_on_fail(request, page):
    """Screenshot to artifacts/fail-<test>.png whenever a test fails."""
    yield
    rep = getattr(request.node, "rep_call", None)
    if rep is not None and rep.failed:
        ARTIFACTS.mkdir(parents=True, exist_ok=True)
        out = ARTIFACTS / f"fail-{_safe_name(request.node.name)}.png"
        try:
            page.screenshot(path=str(out))
        except Exception:
            pass
