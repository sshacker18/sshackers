# Master Context Protocol

This repository uses a persistent, verified project context. Read this file first, then read `PROJECT_STATE.md`, `DECISIONS.md`, `KNOWN_ISSUES.md`, and `NEXT_ACTION.md` before substantive work.

## Source of truth
- Code and configuration in this repository are authoritative for implementation.
- Git history, open PRs, CI logs, test results, and runtime/device output are authoritative for execution status.
- Context documents summarize evidence; they never override code or fresh verification.
- Mark unknown facts as **Unknown / needs verification**. Never invent successful builds, tests, deployments, or device actions.

## Required workflow
1. Recover context from these files and inspect the current branch, working tree, recent commits, relevant code, and CI state.
2. State the immediate goal and constraints before changing anything substantial.
3. Make the smallest focused change; preserve existing user work and avoid unrelated refactors.
4. Run relevant checks where available. Separate **verified**, **attempted**, and **not run**.
5. Update all context files at the end of each meaningful task, including outcomes, failures, and the exact next action.
6. Commit context with implementation changes when practical; never claim a change was pushed unless GitHub confirms it.

## Safety and quality
- Do not delete user data, secrets, credentials, personal documents, production data, or project assets as a cleanup shortcut.
- Never commit tokens, private keys, passwords, personal identification documents, or sensitive logs.
- Prefer least privilege, dry runs, explicit scope, and reversible changes for destructive operations.
- Preserve branch and release policies already documented in this repository.
- Keep instructions beginner-friendly and concise when providing commands to the user; prefer one entrypoint command over many manual steps.

## Context update contract
Every task must leave: current verified state, changed files/commit, checks and results, unresolved issues, decisions with rationale, and one specific next action. Include dates only when known. If the repository is cloned on a device, pull before acting and push updates after verification; do not overwrite uncommitted user changes.
