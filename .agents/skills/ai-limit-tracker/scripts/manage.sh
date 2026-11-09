#!/usr/bin/env bash

PLIST="$HOME/Library/LaunchAgents/com.lucky.ClaudeUsage.plist"
APP="/Applications/ClaudeUsage.app"

case "$1" in
    status)
        if pgrep -x "ClaudeUsage" >/dev/null; then
            PID=$(pgrep -x "ClaudeUsage" | head -n 1)
            echo "🟢 ClaudeUsage is running (PID: $PID)"
        else
            echo "🔴 ClaudeUsage is stopped"
        fi
        ;;
    start)
        if [ -f "$PLIST" ]; then
            launchctl load -w "$PLIST" 2>/dev/null || true
        fi
        open "$APP" 2>/dev/null || true
        echo "✓ Started ClaudeUsage"
        ;;
    stop)
        if [ -f "$PLIST" ]; then
            launchctl unload "$PLIST" 2>/dev/null || true
        fi
        killall ClaudeUsage 2>/dev/null || true
        echo "✓ Stopped ClaudeUsage"
        ;;
    restart)
        $0 stop
        sleep 1
        $0 start
        ;;
    *)
        echo "Usage: $0 {status|start|stop|restart}"
        exit 1
        ;;
esac
