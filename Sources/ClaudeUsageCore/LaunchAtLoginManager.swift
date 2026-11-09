import Foundation

public final class LaunchAtLoginManager {
    public static let shared = LaunchAtLoginManager()
    
    private let plistURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/com.lucky.ClaudeUsage.plist")
    }()
    
    public var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }
    
    public func setEnabled(_ enabled: Bool) {
        if enabled {
            installLaunchAgent()
        } else {
            removeLaunchAgent()
        }
    }
    
    public func installLaunchAgent() {
        let plistContent = """
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
        """
        
        let folder = plistURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? plistContent.write(to: plistURL, atomically: true, encoding: .utf8)
        
        // Load into launchd
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = ["load", "-w", plistURL.path]
        try? p.run()
        p.waitUntilExit()
    }
    
    public func removeLaunchAgent() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = ["unload", plistURL.path]
        try? p.run()
        p.waitUntilExit()
        
        try? FileManager.default.removeItem(at: plistURL)
    }
}
