import ClaudeUsageCore
import AppKit

@main
struct MainApp {
    static func main() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.lucky.ClaudeUsage"
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if running.contains(where: { $0.processIdentifier != currentPID }) {
            exit(0)
        }
        
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
