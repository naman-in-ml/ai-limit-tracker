import Foundation
import Combine
import SwiftUI

public final class UsageService: ObservableObject {
    public static let shared = UsageService()
    
    @Published public var usage: UsageResponse?
    @Published public var accountInfo: OAuthAccount?
    @Published public var lastUpdated: Date?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // Live countdown strings updated every 15s
    @Published public var fiveHourCountdown: String = ""
    @Published public var sevenDayCountdown: String = ""
    @Published public var fiveHourFormattedReset: String = ""
    @Published public var sevenDayFormattedReset: String = ""
    
    private var pollTimer: Timer?
    private var tickerTimer: Timer?
    
    public init() {
        loadAccountInfoFromConfig()
        loadCachedUsageFromConfig()
        
        // Start timers
        startTimers()
        
        // Initial fetch
        Task { [weak self] in
            await self?.fetchUsage()
        }
    }
    
    deinit {
        pollTimer?.invalidate()
        tickerTimer?.invalidate()
    }
    
    private func startTimers() {
        // Poll every 5 minutes
        pollTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.fetchUsage()
            }
        }
        
        // Update countdown text every 15 seconds
        tickerTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.updateCountdowns()
        }
    }
    
    // MARK: - Key Properties for UI
    
    public var fiveHourPercent: Double {
        usage?.fiveHour?.utilization ?? 0
    }
    
    public var sevenDayPercent: Double {
        usage?.sevenDay?.utilization ?? 0
    }
    
    public var statusColor: Color {
        let p = fiveHourPercent
        if p >= 85 {
            return .red
        } else if p >= 60 {
            return .orange
        } else {
            return .green
        }
    }
    
    public var menuBarDisplayString: String {
        let pct = Int(fiveHourPercent)
        if !fiveHourCountdown.isEmpty && fiveHourCountdown != "Resets soon" {
            return "\(pct)% ↻\(fiveHourCountdown)"
        }
        return "\(pct)%"
    }
    
    // MARK: - Fetch Logic
    
    public func fetchUsage() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // Always refresh account info from ~/.claude.json
        loadAccountInfoFromConfig()
        
        guard let token = retrieveOAuthToken() else {
            await MainActor.run {
                self.isLoading = false
                if self.usage == nil {
                    self.errorMessage = "Claude Code token not found in Keychain"
                }
            }
            return
        }
        
        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else {
            await MainActor.run { self.isLoading = false }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("claude-code/0.2.29", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(UsageResponse.self, from: data)
                await MainActor.run {
                    self.usage = decoded
                    self.lastUpdated = Date()
                    self.isLoading = false
                    self.errorMessage = nil
                    self.updateCountdowns()
                }
            } else if httpResponse.statusCode == 429 {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Rate limited. Showing cached data."
                }
            } else {
                let body = String(data: data, encoding: .utf8) ?? "Status \(httpResponse.statusCode)"
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Error \(httpResponse.statusCode): \(body)"
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                if self.usage == nil {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    public func updateCountdowns() {
        guard let usage = usage else { return }
        let now = Date()
        
        if let resetDate = usage.fiveHour?.resetDate {
            fiveHourCountdown = DateParsing.countdownString(from: resetDate, now: now)
            fiveHourFormattedReset = DateParsing.formattedResetTime(from: resetDate)
        } else {
            fiveHourCountdown = ""
            fiveHourFormattedReset = ""
        }
        
        if let resetDate = usage.sevenDay?.resetDate {
            sevenDayCountdown = DateParsing.countdownString(from: resetDate, now: now)
            sevenDayFormattedReset = DateParsing.formattedResetTime(from: resetDate)
        } else {
            sevenDayCountdown = ""
            sevenDayFormattedReset = ""
        }
    }
    
    // MARK: - Credentials & Config
    
    private func retrieveOAuthToken() -> String? {
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
            
            struct CredentialWrapper: Decodable {
                struct ClaudeAiOAuth: Decodable {
                    let accessToken: String?
                }
                let claudeAiOauth: ClaudeAiOAuth?
            }
            
            let cred = try JSONDecoder().decode(CredentialWrapper.self, from: data)
            return cred.claudeAiOauth?.accessToken
        } catch {
            return nil
        }
    }
    
    private func loadAccountInfoFromConfig() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let configURL = home.appendingPathComponent(".claude.json")
        guard let data = try? Data(contentsOf: configURL) else { return }
        
        if let file = try? JSONDecoder().decode(ClaudeConfigFile.self, from: data) {
            self.accountInfo = file.oauthAccount
        }
    }
    
    private func loadCachedUsageFromConfig() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let configURL = home.appendingPathComponent(".claude.json")
        guard let data = try? Data(contentsOf: configURL) else { return }
        
        if let file = try? JSONDecoder().decode(ClaudeConfigFile.self, from: data),
           let cached = file.cachedUsageUtilization?.utilization {
            self.usage = cached
            self.updateCountdowns()
        }
    }
}
