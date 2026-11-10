# AI Limit Tracker

A lightweight, native macOS Menu Bar application and Desktop Widget designed to track real-time rate limits, token consumption, and reset countdowns across **Claude**, **Antigravity (Gemini)**, and **ChatGPT / GPT (Codex)**.

---

## Why AI Limit Tracker?

When coding with modern AI assistants, hitting unexpected rolling window caps (like Claude's 5-hour limit or ChatGPT's window lockouts) halts your entire workflow. 

**AI Limit Tracker** acts as a unified "fuel gauge" sitting directly in your macOS Menu Bar:
- **Never get caught off-guard**: Know your exact remaining usage and reset countdown before kicking off large tasks.
- **Unified Multi-Provider View**: Monitor Claude Pro/Team, Google Gemini (via Antigravity), and ChatGPT Plus/Pro in one glance.
- **Zero Configuration**: No API keys to generate or maintain. It automatically detects your existing active CLI sessions on macOS.
- **Native & Ultra-Lightweight**: Built purely with Swift and AppKit/SwiftUI (<15 MB RAM, ~700 KB binary). No Electron or Node.js background overhead.

---

## Supported Providers

| Provider | Tracked Windows | Auth Source |
| :--- | :--- | :--- |
| **Claude** (Anthropic) | 5-Hour Session Window & 7-Day Weekly Limit + Cowork/Chat breakdown | macOS Keychain (`Claude Code-credentials`) / `~/.claude.json` |
| **Antigravity** (Google Gemini) | Gemini 5-Hour & Weekly Quotas, plus 3P Models Quota | Local CLI cache `/tmp/agy_quota_cache.json` (`agy /quota`) |
| **ChatGPT / GPT** (OpenAI Codex) | Primary 5-Hour Rolling Window, Weekly Limit, & Reset Credits | `~/.codex/auth.json` session token |

---

## Security & Privacy Guarantee

Security and transparency are fundamental to this project:

- **100% Local Execution**: All computations, countdown timers, and rendering occur entirely on your Mac.
- **Zero Third-Party Telemetry**: There are no analytics, remote trackers, intermediate proxy servers, or third-party loggers.
- **Direct Official Endpoints Only**: Network requests are dispatched exclusively to official provider hosts (`https://api.anthropic.com`, `https://chatgpt.com`).
- **Read-Only Credentials**: The app accesses authentication tokens purely in read-only mode to poll usage endpoints. Your credentials never leave your machine.
- **Auditable Open Source**: The entire Swift source code is contained in this repository for inspection and self-compilation.

---

## Quick Installation

### Option 1: One-Line Installer (Recommended)

Run the following command in your macOS Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/naman-in-ml/ai-limit-tracker/main/install.sh | bash
```

### Option 2: Build From Source

```bash
git clone https://github.com/naman-in-ml/ai-limit-tracker.git
cd ai-limit-tracker
make install
```

The app will compile, copy to `/Applications/ClaudeUsage.app`, set up an always-on launch agent, and launch immediately in your Menu Bar.

---

## Features

### 1. Menu Bar Fuel Gauge
Display real-time percentages in your system tray:
- **All Providers (Default)**: `C:44% ⚡7% ✳️8%`
- **Individual Assistant**: Focus on `Claude 44% ↻3h`, `⚡AGY 7% ↻2h`, or `✳️GPT 8% ↻2h`
- **Highest Usage**: Automatically switches to display whichever model is closest to reaching its limit.
- **Dynamic Color Indicators**: 🟢 Green (< 60%), 🟡 Orange (60%–84%), 🔴 Red (≥ 85%).

### 2. Interactive Dropdown Panel
Click the status item in your Menu Bar to open the dashboard:
- Tabbed switching between **All**, **Claude**, **Antigravity**, and **ChatGPT**.
- Progress bars showing exact utilization percentages and reset timestamps.
- Usage breakdown by interface (CLI, web chats, cowork).
- Available reset credits count.

### 3. Floating Desktop HUD Widget
- Toggle a glassmorphic floating widget designed to blend with macOS desktop aesthetics.
- **Pin to Desktop**: Click the pin icon to seat the widget at wallpaper level behind open windows, or leave it floating on top.
- Draggable anywhere on your screen.

### 4. Terminal CLI Quick-Check
Inspect your limits directly in your terminal without opening any GUI:
```bash
python3 skills/ai-limit-tracker/scripts/check_limits.py
```

---

## Managing the App

The repository includes standard Makefile targets for everyday management:

```bash
# Check if currently running
make status

# Stop / unload from Menu Bar
make stop

# Launch / reload
make run

# Run full test suite (24 tests)
make test
```

---

## Uninstalling

To completely remove AI Limit Tracker from your system:

```bash
# Unload and remove LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.lucky.ClaudeUsage.plist 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.lucky.ClaudeUsage.plist

# Stop and delete application
killall ClaudeUsage 2>/dev/null || true
rm -rf /Applications/ClaudeUsage.app
```

---

## License

Distributed under the [MIT License](LICENSE).
