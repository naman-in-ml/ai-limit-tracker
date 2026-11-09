import Foundation
import ClaudeUsageCore

var testsPassed = 0
var testsFailed = 0

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "", line: Int = #line) {
    if a == b {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("❌ FAIL at line \(line): expected '\(b)', got '\(a)'. \(message)")
    }
}

func assertTrue(_ condition: Bool, _ message: String = "", line: Int = #line) {
    if condition {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("❌ FAIL at line \(line): condition was false. \(message)")
    }
}

print("🧪 Starting ClaudeUsage Test Suite...")

// 1. Date Parsing
do {
    let fractional = "2026-11-09T11:30:00.326547+00:00"
    assertTrue(DateParsing.parse(fractional) != nil, "Should parse ISO8601 with fractional seconds")
    
    let standard = "2026-11-09T11:30:00Z"
    assertTrue(DateParsing.parse(standard) != nil, "Should parse standard ISO8601")
    
    let invalid = "not-a-date"
    assertTrue(DateParsing.parse(invalid) == nil, "Invalid date should return nil")
}

// 2. Countdown Calculations
do {
    let now = Date(timeIntervalSince1970: 1700000000)
    
    let future2h15m = Date(timeIntervalSince1970: 1700008100)
    assertEqual(DateParsing.countdownString(from: future2h15m, now: now), "2h 15m")
    
    let future1d4h = Date(timeIntervalSince1970: 1700100800)
    assertEqual(DateParsing.countdownString(from: future1d4h, now: now), "1d 4h")
    
    let future45m = Date(timeIntervalSince1970: 1700002700)
    assertEqual(DateParsing.countdownString(from: future45m, now: now), "45m")
    
    let past = Date(timeIntervalSince1970: 1699990000)
    assertEqual(DateParsing.countdownString(from: past, now: now), "Resets soon")
}

// 3. UsageResponse Decoding
do {
    let json = """
    {
      "five_hour": {
        "utilization": 44.0,
        "resets_at": "2026-11-09T11:30:00.326547+00:00",
        "limit_dollars": null,
        "used_dollars": null,
        "remaining_dollars": null,
        "locked_reason": null
      },
      "seven_day": {
        "utilization": 10.0,
        "resets_at": "2026-11-11T06:00:00.326567+00:00",
        "limit_dollars": null,
        "used_dollars": null,
        "remaining_dollars": null,
        "locked_reason": null
      },
      "seven_day_breakdown": {
        "as_of": "2026-11-09T07:52:43.406271+00:00",
        "window_started_at": "2026-11-04T06:00:00.326567+00:00",
        "rows": [
          { "key": "claude_code", "display_name": "Claude Code", "percent": 99.0 },
          { "key": "chat", "display_name": "Chats", "percent": 0.0 },
          { "key": "cowork", "display_name": "Cowork", "percent": 1.0 }
        ]
      },
      "spend": {
        "used": {
          "amount_minor": 350.0,
          "currency": "USD",
          "exponent": 2
        },
        "limit": 50.0,
        "percent": 7.0,
        "enabled": true
      }
    }
    """
    
    let data = json.data(using: .utf8)!
    let response = try JSONDecoder().decode(UsageResponse.self, from: data)
    
    assertEqual(response.fiveHour?.utilization, 44.0)
    assertTrue(response.fiveHour?.resetDate != nil, "Reset date should be non-nil")
    assertEqual(response.sevenDay?.utilization, 10.0)
    
    assertEqual(response.sevenDayBreakdown?.rows?.count, 3)
    assertEqual(response.sevenDayBreakdown?.rows?.first?.displayName, "Claude Code")
    assertEqual(response.sevenDayBreakdown?.rows?.first?.percent, 99.0)
    
    assertEqual(response.spend?.used?.formatted, "$3.50")
}

// 4. Config File Decoding
do {
    let json = """
    {
      "oauthAccount": {
        "emailAddress": "founder@example.com",
        "seatTier": "pro",
        "organizationName": "Acme Inc"
      },
      "cachedUsageUtilization": {
        "fetchedAtMs": 1794127428483,
        "utilization": {
          "five_hour": {
            "utilization": 25.0,
            "resets_at": "2026-11-09T15:00:00Z"
          }
        }
      }
    }
    """
    
    let data = json.data(using: .utf8)!
    let config = try JSONDecoder().decode(ClaudeConfigFile.self, from: data)
    
    assertEqual(config.oauthAccount?.emailAddress, "founder@example.com")
    assertEqual(config.oauthAccount?.seatTier, "pro")
    assertEqual(config.cachedUsageUtilization?.utilization?.fiveHour?.utilization, 25.0)
}

// 5. Keychain & Live Config Smoke Check
do {
    let home = FileManager.default.homeDirectoryForCurrentUser
    let configURL = home.appendingPathComponent(".claude.json")
    if FileManager.default.fileExists(atPath: configURL.path) {
        let data = try Data(contentsOf: configURL)
        let config = try JSONDecoder().decode(ClaudeConfigFile.self, from: data)
        assertTrue(config.oauthAccount?.emailAddress != nil, "Live ~/.claude.json contains user email")
    }
}

print("───────────────────────────────────────")
print("✅ Test Results: \(testsPassed) passed, \(testsFailed) failed.")

if testsFailed > 0 {
    exit(1)
} else {
    exit(0)
}
