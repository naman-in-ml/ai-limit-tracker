import Foundation
import SwiftUI

// MARK: - Usage Models

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
