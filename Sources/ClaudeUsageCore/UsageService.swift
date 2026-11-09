import Foundation
import Combine
import SwiftUI

public enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case all = "All Providers"
    case claude = "Claude"
    case antigravity = "Antigravity"
    case chatgpt = "ChatGPT / GPT"
    case highest = "Highest Usage"
    
    public var id: String { rawValue }
}

public final class UsageService: ObservableObject {
    public static let shared = UsageService()
    
    // MARK: - Published State
    
    // Claude
    @Published public var usage: UsageResponse?
    @Published public var accountInfo: OAuthAccount?
    @Published public var fiveHourCountdown: String = ""
    @Published public var sevenDayCountdown: String = ""
    @Published public var fiveHourFormattedReset: String = ""
    @Published public var sevenDayFormattedReset: String = ""
    
    // Antigravity (Gemini & 3P)
    @Published public var antigravityQuota: AntigravityQuotaCache?
    @Published public var agyGemini5hCountdown: String = ""
    @Published public var agyGeminiWeeklyCountdown: String = ""
    @Published public var agy3p5hCountdown: String = ""
    @Published public var agy3pWeeklyCountdown: String = ""
    
    // ChatGPT / GPT (Codex)
    @Published public var chatGPTUsage: ChatGPTUsageResponse?
    @Published public var chatGPT5hCountdown: String = ""
    @Published public var chatGPTWeeklyCountdown: String = ""
    
    // UI State
    @Published public var selectedTab: String = "All"
    @Published public var isLaunchAtLoginEnabled: Bool = LaunchAtLoginManager.shared.isEnabled
    
    public func toggleLaunchAtLogin() {
        let newState = !isLaunchAtLoginEnabled
        LaunchAtLoginManager.shared.setEnabled(newState)
        isLaunchAtLoginEnabled = newState
    }
    
    // Common
    @Published public var lastUpdated: Date?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var menuBarMode: MenuBarDisplayMode = .all {
        didSet {
            UserDefaults.standard.set(menuBarMode.rawValue, forKey: "ClaudeUsageMenuBarMode")
        }
    }
    
    private var pollTimer: Timer?
    private var tickerTimer: Timer?
    
    public init() {
        if let savedMode = UserDefaults.standard.string(forKey: "ClaudeUsageMenuBarMode"),
           let mode = MenuBarDisplayMode(rawValue: savedMode) {
            self.menuBarMode = mode
        }
        
        loadClaudeConfig()
        loadAntigravityCache()
        
        startTimers()
        
        Task { [weak self] in
            await self?.fetchAll()
        }
    }
    
    deinit {
        pollTimer?.invalidate()
        tickerTimer?.invalidate()
    }
    
    private func startTimers() {
        // Poll every 180 seconds (3 minutes)
        pollTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.fetchAll()
            }
        }
        
        // Update countdown text every 15 seconds
        tickerTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.updateCountdowns()
        }
    }
    
    // MARK: - Computed Properties for Claude
    
    public var fiveHourPercent: Double {
        usage?.fiveHour?.utilization ?? 0
    }
    
    public var sevenDayPercent: Double {
        usage?.sevenDay?.utilization ?? 0
    }
    
    public var claudeStatusColor: Color {
        colorForPercent(fiveHourPercent)
    }
    
    // MARK: - Computed Properties for Antigravity
    
    private var agyGeminiGroup: AntigravityQuotaCache.AgyGroup? {
        antigravityQuota?.command?.data?.groups?.first(where: { ($0.name ?? "").contains("Gemini") })
    }
    
    private var agy3pGroup: AntigravityQuotaCache.AgyGroup? {
        antigravityQuota?.command?.data?.groups?.first(where: { ($0.name ?? "").contains("Claude") || ($0.name ?? "").contains("GPT") })
    }
    
    public var agyGemini5hBucket: AntigravityQuotaCache.AgyBucket? {
        agyGeminiGroup?.buckets?.first(where: { $0.window == "5h" })
    }
    
    public var agyGeminiWeeklyBucket: AntigravityQuotaCache.AgyBucket? {
        agyGeminiGroup?.buckets?.first(where: { $0.window == "weekly" })
    }
    
    public var agy3p5hBucket: AntigravityQuotaCache.AgyBucket? {
        agy3pGroup?.buckets?.first(where: { $0.window == "5h" })
    }
    
    public var agy3pWeeklyBucket: AntigravityQuotaCache.AgyBucket? {
        agy3pGroup?.buckets?.first(where: { $0.window == "weekly" })
    }
    
    public var agyGemini5hUsed: Double {
        agyGemini5hBucket?.usedPercent ?? 0
    }
    
    public var agyGeminiWeeklyUsed: Double {
        agyGeminiWeeklyBucket?.usedPercent ?? 0
    }
    
    public var agy3p5hUsed: Double {
        agy3p5hBucket?.usedPercent ?? 0
    }
    
    public var agy3pWeeklyUsed: Double {
        agy3pWeeklyBucket?.usedPercent ?? 0
    }
    
    public var agyStatusColor: Color {
        colorForPercent(agyGemini5hUsed)
    }
    
    // MARK: - Computed Properties for ChatGPT
    
    public var chatGPT5hUsed: Double {
        chatGPTUsage?.rateLimit?.primaryWindow?.usedPercent ?? 0
    }
    
    public var chatGPTWeeklyUsed: Double {
        chatGPTUsage?.rateLimit?.secondaryWindow?.usedPercent ?? 0
    }
    
    public var chatGPTPlan: String {
        (chatGPTUsage?.planType ?? "Plus").capitalized
    }
    
    public var chatGPTStatusColor: Color {
        colorForPercent(chatGPT5hUsed)
    }
    
    // MARK: - Overall Status
    
    public var overallStatusColor: Color {
        let maxPct = max(fiveHourPercent, max(agyGemini5hUsed, chatGPT5hUsed))
        return colorForPercent(maxPct)
    }
    
    public var menuBarDisplayString: String {
        switch menuBarMode {
        case .claude:
            let pct = Int(fiveHourPercent)
            if !fiveHourCountdown.isEmpty && fiveHourCountdown != "Resets soon" {
                return "Claude \(pct)% ↻\(fiveHourCountdown)"
            }
            return "Claude \(pct)%"
            
        case .antigravity:
            let pct = Int(agyGemini5hUsed)
            if !agyGemini5hCountdown.isEmpty && agyGemini5hCountdown != "Resets soon" {
                return "⚡AGY \(pct)% ↻\(agyGemini5hCountdown)"
            }
            return "⚡AGY \(pct)%"
            
        case .chatgpt:
            let pct = Int(chatGPT5hUsed)
            if !chatGPT5hCountdown.isEmpty && chatGPT5hCountdown != "Resets soon" {
                return "✳️GPT \(pct)% ↻\(chatGPT5hCountdown)"
            }
            return "✳️GPT \(pct)%"
            
        case .highest:
            let pcts = [
                ("Claude", fiveHourPercent, fiveHourCountdown),
                ("⚡AGY", agyGemini5hUsed, agyGemini5hCountdown),
                ("✳️GPT", chatGPT5hUsed, chatGPT5hCountdown)
            ]
            let top = pcts.max(by: { $0.1 < $1.1 }) ?? ("Claude", 0, "")
            let val = Int(top.1)
            if !top.2.isEmpty && top.2 != "Resets soon" {
                return "\(top.0) \(val)% ↻\(top.2)"
            }
            return "\(top.0) \(val)%"
            
        case .all:
            let c = Int(fiveHourPercent)
            let a = Int(agyGemini5hUsed)
            let g = Int(chatGPT5hUsed)
            return "C:\(c)% ⚡\(a)% ✳️\(g)%"
        }
    }
    
    public func colorForPercent(_ pct: Double) -> Color {
        if pct >= 85 {
            return .red
        } else if pct >= 60 {
            return .orange
        } else {
            return .green
        }
    }
    
    // MARK: - Fetch Logic
    
    public func fetchAll() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        async let fetchClaudeTask: () = fetchClaude()
        async let fetchAgyTask: () = fetchAntigravity()
        async let fetchChatGPTTask: () = fetchChatGPT()
        
        _ = await (fetchClaudeTask, fetchAgyTask, fetchChatGPTTask)
        
        await MainActor.run {
            self.lastUpdated = Date()
            self.isLoading = false
            self.updateCountdowns()
        }
    }
    
    // MARK: - Claude Fetch
    
    public func fetchClaude() async {
        loadClaudeConfig()
        
        guard let token = retrieveClaudeToken() else {
            return
        }
        
        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("claude-code/0.2.29", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 12
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode(UsageResponse.self, from: data)
                await MainActor.run {
                    self.usage = decoded
                }
            }
        } catch {
            // Handled via cached config
        }
    }
    
    // MARK: - Antigravity Fetch
    
    public func fetchAntigravity() async {
        let cachePath = "/tmp/agy_quota_cache.json"
        let fm = FileManager.default
        
        var needsRefresh = true
        if let attrs = try? fm.attributesOfItem(atPath: cachePath),
           let modDate = attrs[.modificationDate] as? Date {
            if Date().timeIntervalSince(modDate) < 90 {
                needsRefresh = false
            }
        }
        
        if needsRefresh {
            // Run background fetch via agy CLI
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", "/Users/lucky/.local/bin/agy -p \"/quota\" --output-format json > /tmp/agy_quota_cache.json.tmp 2>/dev/null && mv /tmp/agy_quota_cache.json.tmp /tmp/agy_quota_cache.json"]
            try? process.run()
            process.waitUntilExit()
        }
        
        await MainActor.run {
            self.loadAntigravityCache()
        }
    }
    
    // MARK: - ChatGPT Fetch
    
    public func fetchChatGPT() async {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let authURL = home.appendingPathComponent(".codex/auth.json")
        guard let data = try? Data(contentsOf: authURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [String: Any],
              let accessToken = tokens["access_token"] as? String else {
            return
        }
        
        guard let url = URL(string: "https://chatgpt.com/backend-api/wham/usage") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("codex-cli/0.167.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 12
        
        do {
            let (resData, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                let decoded = try JSONDecoder().decode(ChatGPTUsageResponse.self, from: resData)
                await MainActor.run {
                    self.chatGPTUsage = decoded
                }
            }
        } catch {
            // Keep existing state
        }
    }
    
    // MARK: - Countdowns
    
    public func updateCountdowns() {
        let now = Date()
        
        // Claude
        if let reset = usage?.fiveHour?.resetDate {
            fiveHourCountdown = DateParsing.countdownString(from: reset, now: now)
            fiveHourFormattedReset = DateParsing.formattedResetTime(from: reset)
        }
        if let reset = usage?.sevenDay?.resetDate {
            sevenDayCountdown = DateParsing.countdownString(from: reset, now: now)
            sevenDayFormattedReset = DateParsing.formattedResetTime(from: reset)
        }
        
        // Antigravity
        if let reset = agyGemini5hBucket?.resetDate {
            agyGemini5hCountdown = DateParsing.countdownString(from: reset, now: now)
        }
        if let reset = agyGeminiWeeklyBucket?.resetDate {
            agyGeminiWeeklyCountdown = DateParsing.countdownString(from: reset, now: now)
        }
        if let reset = agy3p5hBucket?.resetDate {
            agy3p5hCountdown = DateParsing.countdownString(from: reset, now: now)
        }
        if let reset = agy3pWeeklyBucket?.resetDate {
            agy3pWeeklyCountdown = DateParsing.countdownString(from: reset, now: now)
        }
        
        // ChatGPT
        if let reset = chatGPTUsage?.rateLimit?.primaryWindow?.resetDate {
            chatGPT5hCountdown = DateParsing.countdownString(from: reset, now: now)
        }
        if let reset = chatGPTUsage?.rateLimit?.secondaryWindow?.resetDate {
            chatGPTWeeklyCountdown = DateParsing.countdownString(from: reset, now: now)
        }
    }
    
    // MARK: - Local Files & Keychain
    
    private func retrieveClaudeToken() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard !data.isEmpty else { return nil }
            
            struct CredWrapper: Decodable {
                struct ClaudeAiOAuth: Decodable {
                    let accessToken: String?
                }
                let claudeAiOauth: ClaudeAiOAuth?
            }
            let cred = try JSONDecoder().decode(CredWrapper.self, from: data)
            return cred.claudeAiOauth?.accessToken
        } catch {
            return nil
        }
    }
    
    private func loadClaudeConfig() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let configURL = home.appendingPathComponent(".claude.json")
        guard let data = try? Data(contentsOf: configURL) else { return }
        
        if let file = try? JSONDecoder().decode(ClaudeConfigFile.self, from: data) {
            self.accountInfo = file.oauthAccount
            if self.usage == nil, let cached = file.cachedUsageUtilization?.utilization {
                self.usage = cached
            }
        }
    }
    
    private func loadAntigravityCache() {
        let cacheURL = URL(fileURLWithPath: "/tmp/agy_quota_cache.json")
        guard let data = try? Data(contentsOf: cacheURL) else { return }
        if let decoded = try? JSONDecoder().decode(AntigravityQuotaCache.self, from: data) {
            self.antigravityQuota = decoded
            self.updateCountdowns()
        }
    }
}
