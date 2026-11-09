# AI Limit Tracker: Provider Technical Reference

This document details how **Claude**, **Antigravity (Gemini)**, and **ChatGPT / GPT (Codex)** usage, token metrics, and rate limit buckets are queried programmatically.

---

## 1. Claude (Anthropic)

### Authentication
* **Source:** Stored in macOS Keychain under service name:
  ```bash
  security find-generic-password -s "Claude Code-credentials" -w
  ```
* **Payload:** Contains JSON with `claudeAiOauth.accessToken` (`sk-ant-oat01-...`).
* **Fallback:** Local cache at `~/.claude.json` under `cachedUsageUtilization.utilization`.

### Usage Endpoint
* **Method:** `GET`
* **URL:** `https://api.anthropic.com/api/oauth/usage`
* **Required Headers:**
  ```http
  Authorization: Bearer <accessToken>
  anthropic-beta: oauth-2025-04-20
  User-Agent: claude-code/0.2.29
  Content-Type: application/json
  ```
  *(Note: Omitting `User-Agent: claude-code/...` or `anthropic-beta` will cause HTTP 429 / 403 errors).*

### Response Contract
```json
{
  "five_hour": {
    "utilization": 44.0,
    "resets_at": "2026-11-09T11:30:00.326547+00:00"
  },
  "seven_day": {
    "utilization": 10.0,
    "resets_at": "2026-11-11T06:00:00.326567+00:00"
  },
  "seven_day_breakdown": {
    "rows": [
      { "key": "claude_code", "display_name": "Claude Code", "percent": 99.0 },
      { "key": "chat", "display_name": "Chats", "percent": 0.0 },
      { "key": "cowork", "display_name": "Cowork", "percent": 1.0 }
    ]
  }
}
```

---

## 2. Antigravity (Google Gemini & 3P Models)

### Authentication & Extraction
* Antigravity CLI exposes quota directly via the internal `/quota` command:
  ```bash
  agy -p "/quota" --output-format json
  ```
* To prevent latency and subprocess overhead, the result is cached locally at `/tmp/agy_quota_cache.json` with a 90-second TTL.

### Payload Structure
```json
{
  "command": {
    "name": "usage",
    "data": {
      "groups": [
        {
          "name": "Gemini Models",
          "buckets": [
            {
              "id": "gemini-5h",
              "name": "Five Hour Limit Remaining",
              "window": "5h",
              "remaining_fraction": 0.93,
              "reset_time": "2026-11-08T14:13:46Z"
            },
            {
              "id": "gemini-weekly",
              "name": "Weekly Limit Remaining",
              "window": "weekly",
              "remaining_fraction": 0.92,
              "reset_time": "2026-11-14T04:12:05Z"
            }
          ]
        },
        {
          "name": "Claude and GPT models",
          "buckets": [
            {
              "id": "3p-5h",
              "name": "Five Hour Limit Remaining",
              "window": "5h",
              "remaining_fraction": 1.0,
              "reset_time": "2026-11-08T14:16:42Z"
            }
          ]
        }
      ]
    }
  }
}
```

---

## 3. ChatGPT / GPT (OpenAI Codex)

### Authentication
* **Source:** Stored in local JSON configuration:
  `~/.codex/auth.json`
* **Field:** `tokens.access_token` (JWT token).

### Usage Endpoint
* **Method:** `GET`
* **URL:** `https://chatgpt.com/backend-api/wham/usage`
* **Required Headers:**
  ```http
  Authorization: Bearer <access_token>
  User-Agent: codex-cli/0.167.0
  ```

### Response Contract
```json
{
  "email": "user@example.com",
  "plan_type": "plus",
  "rate_limit": {
    "allowed": true,
    "limit_reached": false,
    "primary_window": {
      "used_percent": 8.0,
      "limit_window_seconds": 18000,
      "reset_after_seconds": 7295,
      "reset_at": 1794230265
    },
    "secondary_window": {
      "used_percent": 42.0,
      "limit_window_seconds": 604800,
      "reset_after_seconds": 234977,
      "reset_at": 1794457947
    }
  },
  "rate_limit_reset_credits": {
    "available_count": 2,
    "applicable_available_count": 0
  }
}
```
