# ClaudeUsage (Claude Pulse)

A lightweight, native macOS Menu Bar app and Desktop Widget for tracking **Claude Pro / Team** subscription message limits, 5-hour rolling sessions, 7-day limits, countdown resets, and activity breakdown in real time.

---

## Features

- **Menu Bar Fuel Gauge**:
  - Displays live session utilization percentage and countdown timer (e.g. `Claude 44% ↻3h 38m`).
  - Color-coded indicator: 🟢 Green (< 60%), 🟡 Orange (60%–84%), 🔴 Red (≥ 85%).
- **Interactive Dropdown Panel**:
  - **5-Hour Session Window**: Real-time progress bar, percentage, and exact reset time.
  - **7-Day Weekly Limit**: Progress bar, percentage, and rollover countdown.
  - **Weekly Breakdown**: Usage across Claude Code, web chats, and Cowork.
  - **Account & Tier**: Displays logged-in email and subscription tier (e.g., `Pro`).
  - **One-click Refresh**: Manual refresh button with live spinning status.
- **Floating Desktop HUD Widget**:
  - Glassmorphic translucent widget that can be placed anywhere on the desktop.
  - Dual circular gauges for 5-hour and 7-day limits.
  - **Pin to Desktop**: Toggle between floating above all windows or pinned directly to wallpaper level behind application windows.
- **Zero Manual Configuration**:
  - Reads OAuth credentials securely from macOS Keychain (`Claude Code-credentials`).
  - Gracefully falls back to `~/.claude.json` local cache if offline.
  - Auto-refreshes every 5 minutes in background with local countdown ticking every 15 seconds.

---

## Installation & Commands

The project includes a `Makefile` for building, testing, and managing the application:

```bash
cd /Users/lucky/Projects/claude-usage-widget

# Build release bundle
make build

# Run test suite
make test

# Install to /Applications and launch
make run

# Check if currently running
make status

# Stop / quit
make stop
```

---

## Launch at macOS Login (Optional)

To have ClaudeUsage open automatically when you log into your Mac:
1. Open **System Settings > General > Login Items & Extensions**.
2. Under **Open at Login**, click the `+` button.
3. Select `ClaudeUsage.app` from `/Applications`.
