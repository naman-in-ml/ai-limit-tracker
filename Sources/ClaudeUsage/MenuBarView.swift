import ClaudeUsageCore
import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var service: UsageService
    var onToggleDesktopWidget: () -> Void
    var isDesktopWidgetVisible: Bool
    var onQuit: () -> Void
    
    public init(
        service: UsageService = .shared,
        isDesktopWidgetVisible: Bool = false,
        onToggleDesktopWidget: @escaping () -> Void = {},
        onQuit: @escaping () -> Void = {}
    ) {
        self.service = service
        self.isDesktopWidgetVisible = isDesktopWidgetVisible
        self.onToggleDesktopWidget = onToggleDesktopWidget
        self.onQuit = onQuit
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            // Header
            headerSection
            
            Divider()
                .opacity(0.4)
            
            // Error banner if any
            if let err = service.errorMessage {
                errorBanner(err)
            }
            
            // 5-Hour Session Card
            sessionCard
            
            // 7-Day Weekly Card
            weeklyCard
            
            // Breakdown Card (if available)
            if let rows = service.usage?.sevenDayBreakdown?.rows, !rows.isEmpty {
                breakdownSection(rows: rows)
            }
            
            Divider()
                .opacity(0.4)
            
            // Desktop Widget & Controls
            controlsSection
        }
        .padding(16)
        .frame(width: 320)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(nsColor: .controlAccentColor).opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(nsColor: .controlAccentColor))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Claude Usage")
                    .font(.system(size: 14, weight: .bold))
                
                if let email = service.accountInfo?.emailAddress {
                    let tier = (service.accountInfo?.seatTier ?? "pro").capitalized
                    Text("\(email) • \(tier)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Claude Pro / Team")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Refresh Button
            Button(action: {
                Task {
                    await service.fetchUsage()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .rotationEffect(.degrees(service.isLoading ? 360 : 0))
                    .animation(service.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: service.isLoading)
            }
            .buttonStyle(.plain)
            .disabled(service.isLoading)
            .help("Refresh usage data")
        }
    }
    
    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 12))
            Text(msg)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(2)
            Spacer()
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("5-Hour Session Window")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("\(Int(service.fiveHourPercent))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(colorForPercent(service.fiveHourPercent))
            }
            
            // Progress Bar
            CustomProgressBar(percent: service.fiveHourPercent, color: colorForPercent(service.fiveHourPercent))
                .frame(height: 7)
            
            HStack {
                if !service.fiveHourCountdown.isEmpty {
                    Label("Resets in \(service.fiveHourCountdown)", systemImage: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if !service.fiveHourFormattedReset.isEmpty {
                    Text(service.fiveHourFormattedReset)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
    
    private var weeklyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Weekly Limit (7-Day)")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("\(Int(service.sevenDayPercent))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(colorForPercent(service.sevenDayPercent))
            }
            
            // Progress Bar
            CustomProgressBar(percent: service.sevenDayPercent, color: colorForPercent(service.sevenDayPercent))
                .frame(height: 7)
            
            HStack {
                if !service.sevenDayCountdown.isEmpty {
                    Label("Resets in \(service.sevenDayCountdown)", systemImage: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if !service.sevenDayFormattedReset.isEmpty {
                    Text(service.sevenDayFormattedReset)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
    
    private func breakdownSection(rows: [BreakdownRow]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Weekly Usage Breakdown")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(rows) { row in
                    if row.percent > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colorForBreakdownKey(row.key))
                                .frame(width: 6, height: 6)
                            Text("\(row.displayName): \(Int(row.percent))%")
                                .font(.system(size: 11))
                                .foregroundColor(.primary)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var controlsSection: some View {
        VStack(spacing: 8) {
            // Desktop Widget toggle
            HStack {
                Label("Desktop Widget", systemImage: "macwindow.on.rectangle")
                    .font(.system(size: 12))
                Spacer()
                Button(action: onToggleDesktopWidget) {
                    Text(isDesktopWidgetVisible ? "Hide" : "Show")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isDesktopWidgetVisible ? Color(nsColor: .controlAccentColor) : Color(nsColor: .controlBackgroundColor))
                        .foregroundColor(isDesktopWidgetVisible ? .white : .primary)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                if let updated = service.lastUpdated {
                    Text("Updated " + timeAgo(from: updated))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                } else {
                    Text("Ready")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onQuit) {
                    Text("Quit")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func colorForPercent(_ pct: Double) -> Color {
        if pct >= 85 {
            return .red
        } else if pct >= 60 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func colorForBreakdownKey(_ key: String) -> Color {
        switch key {
        case "claude_code": return .purple
        case "chat": return .blue
        case "cowork": return .teal
        default: return .gray
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 5 { return "just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        let mins = seconds / 60
        if mins < 60 { return "\(mins)m ago" }
        let hours = mins / 60
        return "\(hours)h ago"
    }
}

// Custom Progress Bar with smooth rounded styling
struct CustomProgressBar: View {
    var percent: Double
    var color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(nsColor: .separatorColor).opacity(0.3))
                    .frame(height: geo.size.height)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: max(4, min(geo.size.width * CGFloat(percent / 100.0), geo.size.width)), height: geo.size.height)
                    .animation(.easeInOut(duration: 0.3), value: percent)
            }
        }
    }
}

// Visual Effect view for native blur
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
