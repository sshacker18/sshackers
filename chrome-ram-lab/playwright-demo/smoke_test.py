"""Minimal Playwright smoke test. Uses one headless Chromium instance."""
from playwright.sync_api import sync_playwright


def main() -> int:
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        page = browser.new_page()
        response = page.goto("https://example.com", wait_until="domcontentloaded", timeout=30000)

        if response is None or not response.ok:
            status = None if response is None else response.status
            browser.close()
            raise RuntimeError(f"Example page did not load successfully. HTTP status: {status}")

        title = page.title()
        heading = page.locator("h1").inner_text()
        print(f"HTTP status: {response.status}")
        print(f"Page title: {title}")
        print(f"Main heading: {heading}")

        assert title == "Example Domain", f"Unexpected page title: {title!r}"
        assert heading == "Example Domain", f"Unexpected page heading: {heading!r}"
        browser.close()

    print("PASS: Chromium launched and the example page assertions passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
