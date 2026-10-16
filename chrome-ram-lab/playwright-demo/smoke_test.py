"""Minimal Playwright smoke test. Uses one headless Chromium instance."""
from playwright.sync_api import sync_playwright


def main() -> int:
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        try:
            page = browser.new_page()

            # Keep the smoke test deterministic and independent of external websites.
            page.set_content(
                "<!doctype html><html><head><title>RAM Lab Smoke Test</title></head>"
                "<body><main><h1>Playwright is ready</h1></main></body></html>"
            )

            title = page.title()
            heading = page.locator("h1").inner_text()
            print(f"Page title: {title}")
            print(f"Main heading: {heading}")

            assert title == "RAM Lab Smoke Test", f"Unexpected page title: {title!r}"
            assert heading == "Playwright is ready", f"Unexpected page heading: {heading!r}"
        finally:
            browser.close()

    print("PASS: Chromium launched and the local page assertions passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
