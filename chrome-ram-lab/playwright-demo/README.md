# Optional Playwright Python demo

This optional demo does not affect the CMD-only RAM diagnostics. It creates a local Python virtual environment and installs the pinned Playwright package plus Chromium.

## Prerequisites

- Git for Windows
- Python 3.13 (the Windows Python launcher \`py.exe\` must be available)
- Internet access for pip and browser downloads

Current Playwright Python system-requirements documentation lists Windows 11+ and Windows Server 2019+. This laptop runs Windows 10, so this configuration is outside the documented desktop support range.

## Install and run

From CMD in this folder:

\`\`\`cmd
install-playwright.cmd
run-smoke-test.cmd
\`\`\`

The scripts use the local \`.venv\` folder so dependencies do not install globally. Browser installation downloads Chromium only, not Firefox or WebKit.

The sample test opens \`https://example.com\` in headless Chromium, checks the response, title, and main heading, then exits. It does not change Chrome settings or terminate any processes.

If setup is not needed later, delete the \`.venv\` folder to remove the project-specific Python environment. To reclaim browser-cache disk space, use the Playwright uninstall command from the same environment:

\`\`\`cmd
.venv\Scripts\python.exe -m playwright uninstall chromium
\`\`\`

Deleting \`.venv\` alone does not necessarily delete the shared Playwright browser cache.
