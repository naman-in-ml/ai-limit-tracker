import ClaudeUsageCore
import AppKit
import SwiftUI
import Combine

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent app from quitting when all windows are closed
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        setupPopover()
        observeUsage()
        
        // Restore desktop widget if previously visible
        if UserDefaults.standard.bool(forKey: "ClaudeWidgetVisible") {
            DesktopWidgetController.shared.show()
        }
    }
    
    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Claude Usage")
            button.imagePosition = .imageLeading
            button.title = " Claude"
            button.target = self
            button.action = #selector(statusItemClicked)
        }
        self.statusItem = item
    }
    
    private func setupPopover() {
        let p = NSPopover()
        p.behavior = .transient
        p.contentSize = NSSize(width: 320, height: 380)
        
        let contentView = MenuBarView(
            service: UsageService.shared,
            isDesktopWidgetVisible: DesktopWidgetController.shared.isVisible,
            onToggleDesktopWidget: { [weak self] in
                DesktopWidgetController.shared.toggleVisibility()
                self?.refreshPopoverContent()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        p.contentViewController = NSHostingController(rootView: contentView)
        self.popover = p
    }
    
    private func refreshPopoverContent() {
        guard let popover = popover else { return }
        let contentView = MenuBarView(
            service: UsageService.shared,
            isDesktopWidgetVisible: DesktopWidgetController.shared.isVisible,
            onToggleDesktopWidget: { [weak self] in
                DesktopWidgetController.shared.toggleVisibility()
                self?.refreshPopoverContent()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        popover.contentViewController = NSHostingController(rootView: contentView)
    }
    
    private func observeUsage() {
        let service = UsageService.shared
        
        // Combine updates from usage and countdown
        Publishers.CombineLatest(service.$usage, service.$fiveHourCountdown)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.updateStatusItemTitle()
            }
            .store(in: &cancellables)
    }
    
    private func updateStatusItemTitle() {
        guard let button = statusItem?.button else { return }
        let service = UsageService.shared
        
        let titleText = service.menuBarDisplayString
        let attrString = NSMutableAttributedString(string: " \(titleText)")
        
        // Set font
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        attrString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attrString.length))
        
        button.attributedTitle = attrString
        
        // Color-tinted icon according to status
        let symbolName: String
        let tintColor: NSColor
        let pct = service.fiveHourPercent
        if pct >= 85 {
            symbolName = "exclamationmark.circle.fill"
            tintColor = .systemRed
        } else if pct >= 60 {
            symbolName = "sparkles"
            tintColor = .systemOrange
        } else {
            symbolName = "sparkles"
            tintColor = .controlAccentColor
        }
        
        if let img = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Claude Usage") {
            let config = NSImage.SymbolConfiguration(paletteColors: [tintColor])
            button.image = img.withSymbolConfiguration(config)
        }
    }
    
    @objc private func statusItemClicked() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            refreshPopoverContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
