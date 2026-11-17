# Session log — prompts I used

Agent: OpenCode CLI with Meta Muse Spark 1.3 model.
Manual testing: done by me, by hand in Chrome.

## 1. Setup env
Prompt:
Set up the test env in this repo and prove it works: Python venv + pytest + Playwright using system Chrome, one smoke test opening saucedemo.com, plus verify chrome-devtools CLI can open the site and save a screenshot. Document versions and Fedora issues.

Summary:
Venv works with Python 3.14.10. 1 smoke test passed. CLI opens site and saves shot. Fedora needs uv, no playwright download.

## 2. Recon with CLI
Prompt:
Explore saucedemo.com with chrome-devtools CLI (read-only). Try all demo users. Map screens and bugs. Save route-map.md + agent/recon-commands.sh.

Summary:
All 6 users checked. Map saved. Found problem images, error blocks, visual breaks, guard works.

## 3. AGENTS.md
Prompt:
Write AGENTS.md at repo root from route-map.md. Short guide: purpose, site map, scope, run commands, log prompts and AI mistakes. No secrets.

Summary:
AGENTS.md done. No private notes. Has run commands and auth notes.

## 4. Test plan
Prompt:
Make docs/test-plan.md from route-map.md + manual-human-check.md. Scope in/out, risks, 15-20 cases. Mark which to automate.

Summary:
20 cases TC-01 to TC-20 written. 18 auto, 2 manual.

## 5. Automation
Prompt:
Automate test-plan cases with pytest + Playwright, system Chrome. Parametrize users, shot on fail, mark known bugs as xfail. Update AGENTS.md.

Summary:
34 tests: 29 passed, 5 xfailed. Fresh browser each test. Fail shots in artifacts/.

## 6. Bugs and UX
Prompt:
Make docs/bugs.md and docs/ux-review.md from manual + test runs. Bugs need steps, expected, actual, severity, shot. Only bugs I saw. UX needs 3-5 shop issues with fix. Copy photos to screenshots/.

Summary:
7 bugs filed. 5 UX issues with fixes. All shots in screenshots/.

## 7. AI accuracy log
Prompt:
Make docs/ai-accuracy-log.md from recon + runs. Table: claim, check, verdict, impact. Include CLI flakes and wrong calls.

Summary:
18 rows. 7 correct, 8 wrong, rest partly. Wrong menu and session claims fixed.

## 8. Report and README
Prompt:
Make report.md one page: bugs, UX, why this way, AI help/wrong. Finalize README: quick start, runs, coverage, bugs, time, limits. Clean-clone check in /tmp.

Summary:
Report done. README done. Clean clone: 29 passed, 5 xfailed. Fixed guard timing with retry.

## 9. Pre-submit check
Prompt:
Grep repo for masterplan, Instance A, secrets. Check AGENTS.md clean. Check shots match docs.

Summary:
No secrets. No private notes. Links match.
