#!/usr/bin/env python3
"""
check_limits.py
CLI tool to query and display real-time rate limits and token quotas for:
- Claude (Anthropic Pro / Team)
- Antigravity (Google Gemini & 3P Models)
- ChatGPT / GPT (OpenAI Codex Plus / Pro)
"""

import os
import sys
import json
import time
import urllib.request
import subprocess
from datetime import datetime, timezone

# ANSI Colors
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
CYAN = "\033[36m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

def color_pct(pct):
    if pct >= 85:
        return f"{RED}{pct:3.0f}%{RESET}"
    elif pct >= 60:
        return f"{YELLOW}{pct:3.0f}%{RESET}"
    else:
        return f"{GREEN}{pct:3.0f}%{RESET}"

def format_countdown(iso_or_epoch):
    if not iso_or_epoch:
        return "N/A"
    try:
        if isinstance(iso_or_epoch, (int, float)):
            target = iso_or_epoch
        else:
            clean_str = iso_or_epoch.split("+")[0].replace("Z", "")
            if "." in clean_str:
                dt = datetime.strptime(clean_str, "%Y-%m-%dT%H:%M:%S.%f")
            else:
                dt = datetime.strptime(clean_str, "%Y-%m-%dT%H:%M:%S")
            target = dt.replace(tzinfo=timezone.utc).timestamp()
            
        remaining = int(target - time.time())
        if remaining <= 0:
            return "Resets soon"
        days = remaining // 86400
        hours = (remaining % 86400) // 3600
        mins = (remaining % 3600) // 60
        if days > 0:
            return f"{days}d {hours}h"
        elif hours > 0:
            return f"{hours}h {mins}m"
        else:
            return f"{mins}m"
    except Exception:
        return str(iso_or_epoch)[:16]

def fetch_claude():
    # 1. Try Keychain
    token = None
    try:
        proc = subprocess.run(["security", "find-generic-password", "-s", "Claude Code-credentials", "-w"],
                              capture_output=True, text=True, timeout=3)
        if proc.returncode == 0 and proc.stdout.strip():
            cred = json.loads(proc.stdout.strip())
            token = cred.get("claudeAiOauth", {}).get("accessToken")
    except Exception:
        pass
        
    if token:
        try:
            req = urllib.request.Request("https://api.anthropic.com/api/oauth/usage", headers={
                "Authorization": f"Bearer {token}",
                "anthropic-beta": "oauth-2025-04-20",
                "User-Agent": "claude-code/0.2.29"
            })
            with urllib.request.urlopen(req, timeout=5) as resp:
                return json.loads(resp.read().decode())
        except Exception:
            pass

    # 2. Try ~/.claude.json fallback
    try:
        config_path = os.path.expanduser("~/.claude.json")
        if os.path.exists(config_path):
            with open(config_path) as f:
                data = json.load(f)
                return data.get("cachedUsageUtilization", {}).get("utilization")
    except Exception:
        pass
    return None

def fetch_antigravity():
    cache_path = "/tmp/agy_quota_cache.json"
    if os.path.exists(cache_path):
        try:
            with open(cache_path) as f:
                return json.load(f).get("command", {}).get("data", {})
        except Exception:
            pass
    # Try running agy directly
    try:
        proc = subprocess.run(["agy", "-p", "/quota", "--output-format", "json"],
                              capture_output=True, text=True, timeout=6)
        if proc.returncode == 0 and proc.stdout.strip():
            return json.loads(proc.stdout.strip()).get("command", {}).get("data", {})
    except Exception:
        pass
    return None

def fetch_chatgpt():
    auth_path = os.path.expanduser("~/.codex/auth.json")
    if not os.path.exists(auth_path):
        return None
    try:
        with open(auth_path) as f:
            auth = json.load(f)
        token = auth.get("tokens", {}).get("access_token")
        if not token:
            return None
        req = urllib.request.Request("https://chatgpt.com/backend-api/wham/usage", headers={
            "Authorization": f"Bearer {token}",
            "User-Agent": "codex-cli/0.167.0"
        })
        with urllib.request.urlopen(req, timeout=5) as resp:
            return json.loads(resp.read().decode())
    except Exception:
        return None

def main():
    print(f"\n{BOLD}═══ AI Limit Tracker: Multi-Provider Quota Status ═══{RESET}\n")
    
    rows = []
    
    # Claude
    claude = fetch_claude()
    if claude:
        f5 = claude.get("five_hour", {})
        u5 = f5.get("utilization", 0)
        r5 = format_countdown(f5.get("resets_at"))
        
        fw = claude.get("seven_day", {})
        uw = fw.get("utilization", 0)
        rw = format_countdown(fw.get("resets_at"))
        
        rows.append(("Claude (Anthropic)", "5-Hour Session", u5, r5))
        rows.append(("Claude (Anthropic)", "7-Day Weekly", uw, rw))
    else:
        rows.append(("Claude (Anthropic)", "Status", None, "Not authenticated or offline"))

    # Antigravity
    agy = fetch_antigravity()
    if agy:
        groups = agy.get("groups", [])
        gemini = next((g for g in groups if "Gemini" in g.get("name", "")), None)
        if gemini:
            b_5h = next((b for b in gemini.get("buckets", []) if b.get("window") == "5h"), None)
            b_wk = next((b for b in gemini.get("buckets", []) if b.get("window") == "weekly"), None)
            
            if b_5h:
                u5 = (1.0 - b_5h.get("remaining_fraction", 1.0)) * 100.0
                r5 = format_countdown(b_5h.get("reset_time"))
                rows.append(("Antigravity (Gemini)", "5-Hour Window", u5, r5))
            if b_wk:
                uw = (1.0 - b_wk.get("remaining_fraction", 1.0)) * 100.0
                rw = format_countdown(b_wk.get("reset_time"))
                rows.append(("Antigravity (Gemini)", "Weekly Limit", uw, rw))
                
        three_p = next((g for g in groups if "Claude" in g.get("name", "") or "GPT" in g.get("name", "")), None)
        if three_p:
            b_3p = next((b for b in three_p.get("buckets", []) if b.get("window") == "5h"), None)
            if b_3p:
                u = (1.0 - b_3p.get("remaining_fraction", 1.0)) * 100.0
                r = format_countdown(b_3p.get("reset_time"))
                rows.append(("Antigravity (3P Models)", "5-Hour Window", u, r))
    else:
        rows.append(("Antigravity (Gemini)", "Status", None, "No active agy quota cache"))

    # ChatGPT / GPT
    gpt = fetch_chatgpt()
    if gpt:
        rl = gpt.get("rate_limit", {})
        p_win = rl.get("primary_window", {})
        u5 = p_win.get("used_percent", 0)
        r5 = format_countdown(p_win.get("reset_at"))
        
        s_win = rl.get("secondary_window", {})
        uw = s_win.get("used_percent", 0)
        rw = format_countdown(s_win.get("reset_at"))
        
        plan = gpt.get("plan_type", "plus").upper()
        rows.append((f"ChatGPT / GPT ({plan})", "5-Hour Primary", u5, r5))
        rows.append((f"ChatGPT / GPT ({plan})", "Weekly Limit", uw, rw))
    else:
        rows.append(("ChatGPT / GPT (Codex)", "Status", None, "Not logged in via codex-cli"))

    # Print Table
    header = f"{'Provider':<26} {'Window':<18} {'Used':<8} {'Reset In':<12}"
    print(f"{BOLD}{header}{RESET}")
    print(f"{DIM}{'-' * 66}{RESET}")
    for provider, window, used, reset in rows:
        if used is not None:
            pct_str = color_pct(used)
            print(f"{provider:<26} {window:<18} {pct_str:<17} {reset:<12}")
        else:
            print(f"{provider:<26} {window:<18} {DIM}{reset}{RESET}")
    print()

if __name__ == "__main__":
    main()
