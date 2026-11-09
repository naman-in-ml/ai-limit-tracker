#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "🚀 Setting up AI Limit Tracker (ClaudeUsage)..."

cd "$REPO_DIR"

# 1. Run tests
echo "🧪 Running test suite..."
swift run ClaudeUsageTests

# 2. Build and install release app
echo "🔨 Building release binary..."
swift build -c release --product ClaudeUsage

mkdir -p build/ClaudeUsage.app/Contents/MacOS
mkdir -p build/ClaudeUsage.app/Contents/Resources
cp .build/release/ClaudeUsage build/ClaudeUsage.app/Contents/MacOS/ClaudeUsage
cp Info.plist build/ClaudeUsage.app/Contents/Info.plist
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns build/ClaudeUsage.app/Contents/Resources/AppIcon.icns
fi

echo "📦 Installing to /Applications/ClaudeUsage.app..."
mkdir -p /Applications
rm -rf /Applications/ClaudeUsage.app
cp -R build/ClaudeUsage.app /Applications/ClaudeUsage.app

# 3. Register persistent LaunchAgent
echo "⚙️ Registering persistent always-on LaunchAgent..."
mkdir -p "$HOME/Library/LaunchAgents"
PLIST_PATH="$HOME/Library/LaunchAgents/com.lucky.ClaudeUsage.plist"

cat << 'EOF' > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.lucky.ClaudeUsage</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/ClaudeUsage.app/Contents/MacOS/ClaudeUsage</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF

launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load -w "$PLIST_PATH" 2>/dev/null || true

echo "✅ AI Limit Tracker successfully installed and running in the Menu Bar!"
