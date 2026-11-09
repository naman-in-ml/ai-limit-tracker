import AppKit
import SwiftUI
import Combine
import ClaudeUsageCore

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        setupPopover()
        observeUsage()
        
        if UserDefaults.standard.bool(forKey: "ClaudeWidgetVisible") {
            DesktopWidgetController.shared.show()
        }
    }
    
    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "AI Limit Tracker")
            button.imagePosition = .imageLeading
            button.title = " AI Limits"
            button.target = self
            button.action = #selector(statusItemClicked)
        }
        self.statusItem = item
    }
    
    private func setupPopover() {
        let p = NSPopover()
        p.behavior = .transient
        p.contentSize = NSSize(width: 340, height: 440)
        
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
        
        // Listen to updates from any provider or mode change
        Publishers.Merge5(
            service.$usage.map { _ in () },
            service.$antigravityQuota.map { _ in () },
            service.$chatGPTUsage.map { _ in () },
            service.$menuBarMode.map { _ in () },
            service.$fiveHourCountdown.map { _ in () }
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.updateStatusItemTitle()
        }
        .store(in: &cancellables)
    }
    
    private func updateStatusItemTitle() {
        guard let button = statusItem?.button else { return }
        let service = UsageService.shared
        
        let titleText = service.menuBarDisplayString
        let attrString = NSMutableAttributedString(string: " \(titleText)")
        
        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        attrString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attrString.length))
        
        button.attributedTitle = attrString
        
        // Color tint icon according to overall status
        let tintColor: NSColor
        let maxPct = max(service.fiveHourPercent, max(service.agyGemini5hUsed, service.chatGPT5hUsed))
        if maxPct >= 85 {
            tintColor = .systemRed
        } else if maxPct >= 60 {
            tintColor = .systemOrange
        } else {
            tintColor = .controlAccentColor
        }
        
        if let img = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "AI Usage") {
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
