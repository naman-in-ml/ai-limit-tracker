import AppKit
import SwiftUI
import ClaudeUsageCore

public final class DesktopWidgetController: NSObject {
    public static let shared = DesktopWidgetController()
    
    private var window: NSWindow?
    private var isPinnedToDesktop: Bool = false
    
    private let kWidgetPinnedKey = "ClaudeWidgetPinnedToDesktop"
    private let kWidgetVisibleKey = "ClaudeWidgetVisible"
    
    public var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    public override init() {
        super.init()
        self.isPinnedToDesktop = UserDefaults.standard.bool(forKey: kWidgetPinnedKey)
    }
    
    public func toggleVisibility() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    public func show() {
        if window == nil {
            setupWindow()
        }
        
        window?.makeKeyAndOrderFront(nil)
        UserDefaults.standard.set(true, forKey: kWidgetVisibleKey)
    }
    
    public func hide() {
        window?.orderOut(nil)
        UserDefaults.standard.set(false, forKey: kWidgetVisibleKey)
    }
    
    public func togglePin() {
        isPinnedToDesktop.toggle()
        UserDefaults.standard.set(isPinnedToDesktop, forKey: kWidgetPinnedKey)
        applyWindowLevel()
        updateContent()
    }
    
    private func setupWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 320, height: 160),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.setFrameAutosaveName("ClaudeDesktopWidgetPosition")
        
        self.window = panel
        applyWindowLevel()
        updateContent()
        
        // Default position: top-right corner of screen
        if panel.frame.origin.x == 100 && panel.frame.origin.y == 100,
           let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.maxX - 340
            let y = screenRect.maxY - 190
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    private func applyWindowLevel() {
        guard let window = window else { return }
        if isPinnedToDesktop {
            window.level = .init(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        } else {
            window.level = .floating
        }
    }
    
    private func updateContent() {
        guard let window = window else { return }
        let rootView = DesktopWidgetView(
            service: UsageService.shared,
            isPinnedToDesktop: isPinnedToDesktop,
            onClose: { [weak self] in
                self?.hide()
            },
            onTogglePin: { [weak self] in
                self?.togglePin()
            }
        )
        window.contentView = NSHostingView(rootView: rootView)
    }
}
