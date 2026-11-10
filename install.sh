#!/usr/bin/env bash
set -e

# AI Limit Tracker - One-Click Installer for macOS
# Repository: https://github.com/naman-in-ml/ai-limit-tracker

APP_NAME="ClaudeUsage"
DEST_APP="/Applications/${APP_NAME}.app"
LAUNCHAGENT_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="${LAUNCHAGENT_DIR}/com.lucky.${APP_NAME}.plist"

echo "====================================================="
echo "   AI Limit Tracker Installer for macOS"
echo "   Tracking: Claude • Antigravity • ChatGPT / GPT"
echo "====================================================="

# Ensure running on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Error: AI Limit Tracker is designed exclusively for macOS."
    exit 1
fi

# Ensure Swift / Xcode CLI tools are present
if ! command -v swift &>/dev/null; then
    echo "Xcode Command Line Tools are required. Prompting installation..."
    xcode-select --install || true
    echo "Please finish the Xcode command-line tools installation and rerun this script."
    exit 1
fi

TEMP_DIR=""
if [ -f "Package.swift" ] && [ -d "Sources" ]; then
    PROJECT_DIR="$(pwd)"
else
    echo "Downloading latest source from GitHub..."
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/naman-in-ml/ai-limit-tracker.git "$TEMP_DIR"
    PROJECT_DIR="$TEMP_DIR"
fi

cd "$PROJECT_DIR"

echo "1/4. Running test suite..."
swift run ClaudeUsageTests

echo "2/4. Compiling release binary..."
swift build -c release --product "$APP_NAME"

echo "3/4. Bundling application to ${DEST_APP}..."
mkdir -p "build/${APP_NAME}.app/Contents/MacOS"
mkdir -p "build/${APP_NAME}.app/Contents/Resources"
cp ".build/release/${APP_NAME}" "build/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"
cp Info.plist "build/${APP_NAME}.app/Contents/Info.plist"

if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "build/${APP_NAME}.app/Contents/Resources/AppIcon.icns"
fi

mkdir -p /Applications
rm -rf "$DEST_APP"
cp -R "build/${APP_NAME}.app" "$DEST_APP"

echo "4/4. Setting up auto-start in Menu Bar..."
mkdir -p "$LAUNCHAGENT_DIR"
cat << EOF > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.lucky.${APP_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${DEST_APP}/Contents/MacOS/${APP_NAME}</string>
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

launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load -w "$PLIST_FILE" 2>/dev/null || true

# Cleanup temp clone if used
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

echo "====================================================="
echo " Installation Complete!"
echo " AI Limit Tracker is now active in your macOS Menu Bar."
echo "====================================================="
