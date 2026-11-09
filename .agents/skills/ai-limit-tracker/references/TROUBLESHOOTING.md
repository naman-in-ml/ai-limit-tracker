# AI Limit Tracker: Troubleshooting Guide

### 1. Keychain Prompt or "Item Not Found" (Claude)
- **Cause:** Claude Code has not been initialized on the machine, or the keychain service name differs.
- **Fix:**
  Run:
  ```bash
  claude login
  ```
  Once logged in, verify the token exists:
  ```bash
  security find-generic-password -s "Claude Code-credentials" -w
  ```
  If Claude Code is running in headless mode, ensure `~/.claude.json` is present.

---

### 2. Antigravity Quota Cache Stale or Empty
- **Cause:** `agy` CLI hasn't refreshed `/tmp/agy_quota_cache.json`.
- **Fix:**
  Run the quota check command directly to refresh the cache:
  ```bash
  agy -p "/quota" --output-format json > /tmp/agy_quota_cache.json
  ```

---

### 3. ChatGPT Token Expired or Codex Auth Missing
- **Cause:** Codex CLI session has expired or `~/.codex/auth.json` was cleared.
- **Fix:**
  Run:
  ```bash
  codex login
  ```
  Check the new token status:
  ```bash
  cat ~/.codex/auth.json | grep access_token
  ```

---

### 4. Menu Bar Icon Hidden Under MacBook Display Notch
- **Cause:** On MacBooks with a camera notch, macOS automatically hides menu bar items if too many status items are loaded on the right side.
- **Fix:**
  1. Click the widget's menu bar icon.
  2. Under **Menu Bar Title**, change the mode from `All Providers` to `Highest Usage` or `Claude`.
  3. This shortens the title to fit easily to the right of the notch.

---

### 5. Managing the LaunchAgent Service
- Check if launchd is actively managing the process:
  ```bash
  launchctl list | grep com.lucky.ClaudeUsage
  ```
- Unload the service:
  ```bash
  launchctl unload ~/Library/LaunchAgents/com.lucky.ClaudeUsage.plist
  ```
- Reload the service:
  ```bash
  launchctl load -w ~/Library/LaunchAgents/com.lucky.ClaudeUsage.plist
  ```
