# ClaudeUsage (Multi-Provider AI Limit Tracker)

A lightweight, native macOS Menu Bar application and floating Desktop Widget that tracks token and rate limits across **Claude**, **Antigravity (Gemini)**, and **ChatGPT / GPT (Codex)** in real time.

---

## Supported Providers & Zero-Config Sources

1. **Claude (Anthropic)**:
   - **Tracked metrics**: 5-hour rolling session limit, 7-day weekly limit, usage breakdown (Claude Code, Chats, Cowork), spend.
   - **Auth**: Reads OAuth token securely from macOS Keychain (`Claude Code-credentials`) with local fallback to `~/.claude.json`.
   - **Endpoint**: `https://api.anthropic.com/api/oauth/usage`.

2. **Antigravity (Google Gemini & 3P Models)**:
   - **Tracked metrics**: Gemini Models 5-hour & Weekly limit remaining, 3P models (Claude & GPT in Antigravity) 5-hour & Weekly limit remaining.
   - **Auth**: Local cache `/tmp/agy_quota_cache.json` refreshed automatically via `agy -p "/quota" --output-format json`.

3. **ChatGPT / GPT (OpenAI Codex)**:
   - **Tracked metrics**: Primary 5-hour rolling window, Secondary 7-day window, account plan type (`Plus`, `Pro`), available reset credits.
   - **Auth**: Reads session token from `~/.codex/auth.json`.
   - **Endpoint**: `https://chatgpt.com/backend-api/wham/usage`.

---

## Features

- **Menu Bar Fuel Gauge**:
   - Customizable title format:
     - **All Providers**: Compact side-by-side indicator (e.g. `C:44% ⚡7% ✳️8%`)
     - **Claude**: `Claude 44% ↻3h 38m`
     - **Antigravity**: `⚡AGY 7% ↻2h 28m`
     - **ChatGPT**: `✳️GPT 8% ↻2h 01m`
     - **Highest**: Dynamically shows whichever provider is closest to its threshold.
   - Color-coded status indicator: 🟢 Green (< 60%), 🟡 Orange (60%–84%), 🔴 Red (≥ 85%).

- **Interactive Dropdown Panel**:
   - Provider tab switcher (`All`, `Claude`, `Antigravity`, `ChatGPT`).
   - Detailed progress bars, % utilized, and exact rollover countdowns.
   - Desktop Widget toggle.
   - Menu Bar Title mode selector.
   - Manual one-click refresh button.

- **Floating Desktop HUD Widget**:
   - Translucent glassmorphism card (Apple Sonoma widget style).
   - Triple circular progress rings for Claude, Antigravity, and GPT.
   - Draggable anywhere on the desktop.
   - **Pin Button**: Toggle between floating above all application windows or staying pinned behind windows at the desktop wallpaper level.

---

## Makefile Commands

```bash
cd /Users/lucky/Projects/claude-usage-widget

# Build release bundle
make build

# Run unit test suite (23 assertions)
make test

# Install to /Applications and launch
make run

# Check status
make status

# Stop / quit
make stop
```
