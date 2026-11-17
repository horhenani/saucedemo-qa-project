# Test environment setup (Fedora 45)

## Verified versions (2026-11-17)

| Component | Version | Source |
|---|---|---|
| Fedora | 45 (kernel 7.3.3-300.fc45.x86_64) | `/etc/fedora-release`, `uname -r` |
| Python | 3.14.10 (uv-managed CPython, pinned via `.python-version`; system python is 3.15.2) | `.venv/bin/python --version` |
| Env manager | uv 0.13.7 | `uv --version` |
| pytest | 9.2.0 | `uv pip show pytest` |
| Playwright (Python) | 1.65.2 | `uv pip show playwright` |
| Google Chrome | 157.0.8103.78 (`/usr/sbin/google-chrome`) | `google-chrome --version` |
| Node.js / npm | v22.23.1 / 10.9.8 | `node/npm --version` |
| chrome-devtools-mcp / `chrome-devtools` CLI | 1.13.0 | `npm view chrome-devtools-mcp version` |
| Editor | Zed 1.28.1 | `zed --version` |

## Layout

```
.venv/                  # Python venv (created by `uv venv`, git-ignored)
tests/test_smoke.py     # smoke test: opens saucedemo.com via system Chrome
conftest.py             # Playwright fixture (channel="chrome", headless)
artifacts/              # screenshots written by tests/scripts (git-ignored)
scripts/verify_chrome_headless.sh    # Chrome --headless --screenshot check
scripts/verify_chrome_devtools.sh    # chrome-devtools CLI navigate+screenshot check
```

## Setup from scratch

```bash
uv venv .venv   # picks Python 3.14 via .python-version (downloads CPython if needed)
VIRTUAL_ENV=$PWD/.venv uv pip install -r requirements.txt
.venv/bin/python -m pytest
./scripts/verify_chrome_headless.sh
./scripts/verify_chrome_devtools.sh
```

No `playwright install` (browser download) is needed: tests use
`channel="chrome"` so Playwright drives the already-installed system Chrome.

## chrome-devtools CLI verification

```bash
npx -y -p chrome-devtools-mcp@latest chrome-devtools start --headless --isolated
npx -y -p chrome-devtools-mcp@latest chrome-devtools navigate_page 1 --url "https://www.saucedemo.com"
npx -y -p chrome-devtools-mcp@latest chrome-devtools take_screenshot 1 --filePath artifacts/chrome-devtools-cli-saucedemo.png
npx -y -p chrome-devtools-mcp@latest chrome-devtools stop
```

(`scripts/verify_chrome_devtools.sh` does exactly this, with daemon cleanup
via trap.) A global install (`npm i -g chrome-devtools-mcp@latest`) also works
but is unnecessary; the `npx -p` form needs no root.

## Fedora-specific issues found

1. **No system pip.** Fedora 45 ships `python3` without pip
   (`python3 -m pip` → `No module named pip`). Used `uv` (`uv venv`,
   `uv pip install`) instead of `dnf install python3-pip`. Works without root.
   Fedora 45 also ships only Python 3.15 system-wide (no `python3.14` package);
   `uv venv` downloaded CPython 3.14.10 automatically per `.python-version`.
2. **No Playwright browser download needed.** Playwright's bundled-Chromium
   path (`playwright install --with-deps`) would require `sudo dnf` for OS
   deps; avoided entirely with `channel="chrome"` (system Chrome 157 already
   satisfies Playwright 1.65.2's requirements — launch verified working).
3. **`google-chrome --screenshot` needs `--virtual-time-budget`.**
   Without it the shot fires before the saucedemo SPA renders (5 KB, missing
   text). `--virtual-time-budget=8000` yields a fully rendered 1280x720 shot.
4. **Harmless D-Bus errors in headless Chrome** (`org.freedesktop.portal.*`
   `InvalidArgs`): cosmetic on headless/server environments, screenshot still
   written. Ignore.
5. **`chrome-devtools start` rejects `--viewport`.** The CLI forwards only a
   subset of MCP server flags (see `chrome-devtools start --help`); viewport
   sizing is not among them. Omitted it; default capture works.
6. **Page IDs: `new_page` opens page 2, page 1 stays `about:blank`.**
   Screenshotting page 1 after `new_page` gives a blank white PNG. The script
   uses `navigate_page 1 --url ...` instead, so page 1 *is* the site.
   (Caught during verification: first CLI screenshot was blank white.)
7. **Daemon hygiene.** The CLI keeps a background daemon
   (`/run/user/1000/chrome-devtools-mcp/server.sock`). Always `stop` it when
   done (the script's `trap` handles this); a stale daemon makes reruns
   confusing. `opencode.json` keeps the MCP server `enabled: false`; CLI use
   is independent of that setting.
