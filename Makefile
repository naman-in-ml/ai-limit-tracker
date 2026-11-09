APP_NAME = ClaudeUsage
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
RELEASE_BIN = .build/release/$(APP_NAME)
PLIST_PATH = $(HOME)/Library/LaunchAgents/com.lucky.ClaudeUsage.plist

.PHONY: all build install autostart autostart-remove run stop status test clean

all: build

build:
	swift build -c release --product $(APP_NAME)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp $(RELEASE_BIN) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@if [ -f Resources/AppIcon.icns ]; then cp Resources/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/AppIcon.icns; fi
	@echo "✓ Successfully built $(APP_BUNDLE)"

test:
	swift run ClaudeUsageTests

install: build
	@mkdir -p /Applications
	@rm -rf /Applications/$(APP_NAME).app
	@cp -R $(APP_BUNDLE) /Applications/$(APP_NAME).app
	@echo "✓ Installed $(APP_NAME).app to /Applications"
	@$(MAKE) autostart

autostart:
	@mkdir -p $(HOME)/Library/LaunchAgents
	@printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' \
	'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
	'<plist version="1.0">' \
	'<dict>' \
	'    <key>Label</key>' \
	'    <string>com.lucky.ClaudeUsage</string>' \
	'    <key>ProgramArguments</key>' \
	'    <array>' \
	'        <string>/Applications/ClaudeUsage.app/Contents/MacOS/ClaudeUsage</string>' \
	'    </array>' \
	'    <key>RunAtLoad</key>' \
	'    <true/>' \
	'    <key>KeepAlive</key>' \
	'    <dict>' \
	'        <key>SuccessfulExit</key>' \
	'        <false/>' \
	'    </dict>' \
	'    <key>ProcessType</key>' \
	'    <string>Interactive</string>' \
	'</dict>' \
	'</plist>' > $(PLIST_PATH)
	@launchctl unload $(PLIST_PATH) 2>/dev/null || true
	@launchctl load -w $(PLIST_PATH) 2>/dev/null || true
	@echo "✓ Always-on Menu Bar service registered in LaunchAgents ($(PLIST_PATH))"

autostart-remove:
	@launchctl unload $(PLIST_PATH) 2>/dev/null || true
	@rm -f $(PLIST_PATH)
	@echo "✓ Removed LaunchAgent"

run: install
	@killall $(APP_NAME) 2>/dev/null || true
	@open /Applications/$(APP_NAME).app
	@echo "✓ Launched $(APP_NAME) in menu bar & desktop!"

stop:
	@launchctl unload $(PLIST_PATH) 2>/dev/null || true
	@killall $(APP_NAME) 2>/dev/null && echo "✓ Stopped $(APP_NAME)" || echo "Not running."

status:
	@pgrep -x $(APP_NAME) >/dev/null && echo "✓ $(APP_NAME) is currently running" || echo "✗ $(APP_NAME) is not running"

clean:
	@rm -rf $(BUILD_DIR) .build
