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

print("🧪 Starting Multi-Provider AI Limit Tracker Test Suite...")

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

// 3. Claude UsageResponse Decoding
do {
    let json = """
    {
      "five_hour": {
        "utilization": 44.0,
        "resets_at": "2026-11-09T11:30:00.326547+00:00"
      },
      "seven_day": {
        "utilization": 10.0,
        "resets_at": "2026-11-11T06:00:00.326567+00:00"
      },
      "seven_day_breakdown": {
        "rows": [
          { "key": "claude_code", "display_name": "Claude Code", "percent": 99.0 },
          { "key": "chat", "display_name": "Chats", "percent": 0.0 }
        ]
      }
    }
    """
    
    let data = json.data(using: .utf8)!
    let response = try JSONDecoder().decode(UsageResponse.self, from: data)
    
    assertEqual(response.fiveHour?.utilization, 44.0)
    assertTrue(response.fiveHour?.resetDate != nil, "Reset date should be non-nil")
    assertEqual(response.sevenDay?.utilization, 10.0)
    assertEqual(response.sevenDayBreakdown?.rows?.count, 2)
}

// 4. Antigravity Quota Cache Decoding
do {
    let json = """
    {
      "command": {
        "name": "usage",
        "data": {
          "groups": [
            {
              "name": "Gemini Models",
              "buckets": [
                {
                  "id": "gemini-weekly",
                  "name": "Weekly Limit Remaining",
                  "window": "weekly",
                  "remaining_fraction": 0.92,
                  "reset_time": "2026-11-14T04:12:05Z"
                },
                {
                  "id": "gemini-5h",
                  "name": "Five Hour Limit Remaining",
                  "window": "5h",
                  "remaining_fraction": 0.93,
                  "reset_time": "2026-11-08T14:13:46Z"
                }
              ]
            },
            {
              "name": "Claude and GPT models",
              "buckets": [
                {
                  "id": "3p-5h",
                  "name": "Five Hour Limit Remaining",
                  "window": "5h",
                  "remaining_fraction": 1.0,
                  "reset_time": "2026-11-08T14:16:42Z"
                }
              ]
            }
          ]
        }
      }
    }
    """
    
    let data = json.data(using: .utf8)!
    let quota = try JSONDecoder().decode(AntigravityQuotaCache.self, from: data)
    
    let groups = quota.command?.data?.groups
    assertEqual(groups?.count, 2)
    
    let geminiGroup = groups?.first(where: { $0.name == "Gemini Models" })
    let gemini5h = geminiGroup?.buckets?.first(where: { $0.window == "5h" })
    
    XCTAssertApproximatelyEqual: do {
        assertEqual(gemini5h?.remainingPercent, 93.0)
        assertEqual(gemini5h?.usedPercent, 7.0)
        assertTrue(gemini5h?.resetDate != nil, "Gemini reset date should be parsed")
    }
    
    let threePGroup = groups?.first(where: { $0.name == "Claude and GPT models" })
    let threeP5h = threePGroup?.buckets?.first(where: { $0.window == "5h" })
    assertEqual(threeP5h?.remainingPercent, 100.0)
    assertEqual(threeP5h?.usedPercent, 0.0)
}

// 5. ChatGPT / Codex Usage Decoding
do {
    let json = """
    {
      "email": "naman.in.ml@gmail.com",
      "plan_type": "plus",
      "rate_limit": {
        "allowed": true,
        "limit_reached": false,
        "primary_window": {
          "used_percent": 8.0,
          "limit_window_seconds": 18000,
          "reset_after_seconds": 7200,
          "reset_at": 1794230265
        },
        "secondary_window": {
          "used_percent": 42.0,
          "limit_window_seconds": 604800,
          "reset_after_seconds": 234000,
          "reset_at": 1794457947
        }
      },
      "rate_limit_reset_credits": {
        "available_count": 2,
        "applicable_available_count": 0
      }
    }
    """
    
    let data = json.data(using: .utf8)!
    let usage = try JSONDecoder().decode(ChatGPTUsageResponse.self, from: data)
    
    assertEqual(usage.email, "naman.in.ml@gmail.com")
    assertEqual(usage.planType, "plus")
    assertEqual(usage.rateLimit?.primaryWindow?.usedPercent, 8.0)
    assertEqual(usage.rateLimit?.secondaryWindow?.usedPercent, 42.0)
    assertTrue(usage.rateLimit?.primaryWindow?.resetDate != nil, "ChatGPT reset date should be computed")
    assertEqual(usage.resetCredits?.availableCount, 2)
}

// 6. LaunchAtLoginManager Test
do {
    let manager = LaunchAtLoginManager.shared
    assertTrue(manager != nil, "LaunchAtLoginManager singleton should exist")
}

print("───────────────────────────────────────")
print("✅ Test Results: \(testsPassed) passed, \(testsFailed) failed.")

if testsFailed > 0 {
    exit(1)
} else {
    exit(0)
}
