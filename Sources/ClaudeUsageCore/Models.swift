import Foundation
import SwiftUI

// MARK: - Claude Models

public struct UsageResponse: Codable {
    public let fiveHour: WindowUsage?
    public let sevenDay: WindowUsage?
    public let sevenDayBreakdown: BreakdownInfo?
    public let limits: [UsageLimit]?
    public let spend: SpendInfo?
    
    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayBreakdown = "seven_day_breakdown"
        case limits
        case spend
    }
}

public struct WindowUsage: Codable {
    public let utilization: Double
    public let resetsAt: String?
    public let limitDollars: Double?
    public let usedDollars: Double?
    public let remainingDollars: Double?
    public let lockedReason: String?
    
    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
        case limitDollars = "limit_dollars"
        case usedDollars = "used_dollars"
        case remainingDollars = "remaining_dollars"
        case lockedReason = "locked_reason"
    }
    
    public var resetDate: Date? {
        guard let resetsAt = resetsAt else { return nil }
        return DateParsing.parse(resetsAt)
    }
}

public struct BreakdownInfo: Codable {
    public let asOf: String?
    public let windowStartedAt: String?
    public let rows: [BreakdownRow]?
    
    enum CodingKeys: String, CodingKey {
        case asOf = "as_of"
        case windowStartedAt = "window_started_at"
        case rows
    }
}

public struct BreakdownRow: Codable, Identifiable {
    public var id: String { key }
    public let key: String
    public let displayName: String
    public let percent: Double
    
    enum CodingKeys: String, CodingKey {
        case key
        case displayName = "display_name"
        case percent
    }
}

public struct UsageLimit: Codable, Identifiable {
    public var id: String { "\(kind)-\(resetsAt ?? "")" }
    public let kind: String
    public let group: String
    public let percent: Double
    public let severity: String?
    public let resetsAt: String?
    public let isActive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case kind
        case group
        case percent
        case severity
        case resetsAt = "resets_at"
        case isActive = "is_active"
    }
}

public struct SpendInfo: Codable {
    public let used: SpendAmount?
    public let limit: Double?
    public let percent: Double?
    public let enabled: Bool?
}

public struct SpendAmount: Codable {
    public let amountMinor: Double?
    public let currency: String?
    public let exponent: Int?
    
    enum CodingKeys: String, CodingKey {
        case amountMinor = "amount_minor"
        case currency
        case exponent
    }
    
    public var formatted: String {
        guard let minor = amountMinor, let exp = exponent else { return "$0.00" }
        let value = minor / pow(10.0, Double(exp))
        return String(format: "$%.2f", value)
    }
}

// MARK: - Account Info Models

public struct ClaudeConfigFile: Codable {
    public let oauthAccount: OAuthAccount?
    public let cachedUsageUtilization: CachedUsage?
}

public struct OAuthAccount: Codable {
    public let accountUuid: String?
    public let emailAddress: String?
    public let billingType: String?
    public let seatTier: String?
    public let displayName: String?
    public let fullName: String?
    public let organizationName: String?
}

public struct CachedUsage: Codable {
    public let fetchedAtMs: Double?
    public let utilization: UsageResponse?
}

// MARK: - Antigravity Quota Models

public struct AntigravityQuotaCache: Codable {
    public let command: AgyCommand?
    
    public struct AgyCommand: Codable {
        public let name: String?
        public let data: AgyData?
    }
    
    public struct AgyData: Codable {
        public let description: String?
        public let groups: [AgyGroup]?
    }
    
    public struct AgyGroup: Codable, Identifiable {
        public var id: String { name ?? UUID().uuidString }
        public let name: String?
        public let description: String?
        public let buckets: [AgyBucket]?
    }
    
    public struct AgyBucket: Codable, Identifiable {
        public let id: String
        public let name: String?
        public let description: String?
        public let window: String?
        public let remainingFraction: Double?
        public let resetTime: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case description
            case window
            case remainingFraction = "remaining_fraction"
            case resetTime = "reset_time"
        }
        
        public var usedPercent: Double {
            guard let frac = remainingFraction else { return 0 }
            let val = max(0, min(100, (1.0 - frac) * 100.0))
            return (val * 100).rounded() / 100
        }
        
        public var remainingPercent: Double {
            guard let frac = remainingFraction else { return 100 }
            let val = max(0, min(100, frac * 100.0))
            return (val * 100).rounded() / 100
        }
        
        public var resetDate: Date? {
            guard let resetTime = resetTime else { return nil }
            return DateParsing.parse(resetTime)
        }
    }
}

// MARK: - ChatGPT / Codex Models

public struct ChatGPTUsageResponse: Codable {
    public let email: String?
    public let planType: String?
    public let rateLimit: ChatGPTRateLimit?
    public let resetCredits: ChatGPTResetCredits?
    
    enum CodingKeys: String, CodingKey {
        case email
        case planType = "plan_type"
        case rateLimit = "rate_limit"
        case resetCredits = "rate_limit_reset_credits"
    }
}

public struct ChatGPTRateLimit: Codable {
    public let allowed: Bool?
    public let limitReached: Bool?
    public let primaryWindow: ChatGPTRateLimitWindow?
    public let secondaryWindow: ChatGPTRateLimitWindow?
    
    enum CodingKeys: String, CodingKey {
        case allowed
        case limitReached = "limit_reached"
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

public struct ChatGPTRateLimitWindow: Codable {
    public let usedPercent: Double
    public let limitWindowSeconds: Int?
    public let resetAfterSeconds: Int?
    public let resetAt: Double?
    
    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case limitWindowSeconds = "limit_window_seconds"
        case resetAfterSeconds = "reset_after_seconds"
        case resetAt = "reset_at"
    }
    
    public var resetDate: Date? {
        if let resetAt = resetAt, resetAt > 0 {
            return Date(timeIntervalSince1970: resetAt)
        }
        if let after = resetAfterSeconds, after > 0 {
            return Date().addingTimeInterval(TimeInterval(after))
        }
        return nil
    }
}

public struct ChatGPTResetCredits: Codable {
    public let availableCount: Int?
    public let applicableAvailableCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case availableCount = "available_count"
        case applicableAvailableCount = "applicable_available_count"
    }
}

// MARK: - Date Parsing Helper

public enum DateParsing {
    private static let isoFormatterWithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    
    private static let isoFormatterWithoutFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    
    public static func parse(_ str: String) -> Date? {
        if let d = isoFormatterWithFraction.date(from: str) {
            return d
        }
        return isoFormatterWithoutFraction.date(from: str)
    }
    
    public static func countdownString(from date: Date?, now: Date = Date()) -> String {
        guard let date = date else { return "" }
        let interval = date.timeIntervalSince(now)
        if interval <= 0 {
            return "Resets soon"
        }
        let totalSeconds = Int(interval)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    public static func formattedResetTime(from date: Date?) -> String {
        guard let date = date else { return "" }
        let df = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            df.dateFormat = "h:mm a"
            return "Today at " + df.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            df.dateFormat = "h:mm a"
            return "Tomorrow at " + df.string(from: date)
        } else {
            df.dateFormat = "E, MMM d 'at' h:mm a"
            return df.string(from: date)
        }
    }
}
