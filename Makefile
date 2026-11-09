APP_NAME = ClaudeUsage
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
RELEASE_BIN = .build/release/$(APP_NAME)

.PHONY: all build install run stop status test clean

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

run: install
	@killall $(APP_NAME) 2>/dev/null || true
	@open /Applications/$(APP_NAME).app
	@echo "✓ Launched $(APP_NAME) in menu bar & desktop!"

stop:
	@killall $(APP_NAME) 2>/dev/null && echo "✓ Stopped $(APP_NAME)" || echo "Not running."

status:
	@pgrep -x $(APP_NAME) >/dev/null && echo "✓ $(APP_NAME) is currently running" || echo "✗ $(APP_NAME) is not running"

clean:
	@rm -rf $(BUILD_DIR) .build
