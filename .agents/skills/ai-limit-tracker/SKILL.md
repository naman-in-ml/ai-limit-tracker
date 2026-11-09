---
name: ai-limit-tracker
description: >-
  Build, install, run, or query the multi-provider macOS Menu Bar app and Desktop Widget
  for real-time usage and rate-limit tracking across Claude (Anthropic), Antigravity (Gemini),
  and ChatGPT (OpenAI Codex). Use this skill when asked to monitor or display AI limits,
  build/install the menu bar widget, troubleshoot credential extraction, or inspect quota buckets.
---

# AI Limit Tracker Skill

This skill provides the complete tooling and runbook to monitor, build, manage, and query real-time rate limits and token usage across **Claude (Pro/Team)**, **Antigravity (Gemini & 3P)**, and **ChatGPT / GPT (Codex Plus/Pro)**.

---

## Quick Reference Commands

Action | Command
:--- | :---
**Check live limits in CLI** | `python3 scripts/check_limits.py`
**One-command build & install** | `bash scripts/setup.sh`
**Manage widget service** | `bash scripts/manage.sh {status|start|stop|restart}`
**Run full unit test suite** | `make test`

---

## 1. Checking Live Limits via Terminal

To inspect current rate limits across all three providers without opening the GUI app, run:
```bash
python3 scripts/check_limits.py
```
This queries:
- **Claude**: Reads OAuth token from macOS Keychain (`Claude Code-credentials`) and hits Anthropic's OAuth usage API.
- **Antigravity**: Reads `/tmp/agy_quota_cache.json` or runs `agy -p "/quota"`.
- **ChatGPT**: Reads `~/.codex/auth.json` and hits the Codex backend usage route.

---

## 2. Building & Installing the macOS Menu Bar App

To build the native Swift app and register the persistent background LaunchAgent:
```bash
bash scripts/setup.sh
```

This performs:
1. Runs `swift run ClaudeUsageTests` to verify all 24 unit test assertions.
2. Compiles the optimized release binary with `swift build -c release`.
3. Packages the `.app` bundle into `/Applications/ClaudeUsage.app`.
4. Registers an always-on `LaunchAgent` at `~/Library/LaunchAgents/com.lucky.ClaudeUsage.plist` so the widget starts automatically at login and auto-revives if unexpectedly closed.

---

## 3. Managing the Background Service

Use `scripts/manage.sh` to control the menu bar process:
- **Check status**: `bash scripts/manage.sh status`
- **Restart**: `bash scripts/manage.sh restart`
- **Stop**: `bash scripts/manage.sh stop`
- **Start**: `bash scripts/manage.sh start`

---

## 4. Technical Architecture & References

For detailed protocol specifications, internal routes, and common issue resolutions, consult the reference guides:
- [Provider APIs & Authentication](./references/PROVIDERS.md): Detailed endpoint URLs, required headers, and response JSON schemas.
- [Troubleshooting Guide](./references/TROUBLESHOOTING.md): Fixes for Keychain access, expired tokens, display notch clipping, and launchd controls.
