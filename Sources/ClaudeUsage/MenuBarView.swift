import SwiftUI
import ClaudeUsageCore

public struct MenuBarView: View {
    @ObservedObject var service: UsageService
    var onToggleDesktopWidget: () -> Void
    var isDesktopWidgetVisible: Bool
    var onQuit: () -> Void
    
    public static let availableTabs = ["All", "Claude", "Antigravity", "ChatGPT"]
    
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
        VStack(spacing: 12) {
            // Header
            headerSection
            
            // Tab Selector
            tabSelectorSection
            
            Divider()
                .opacity(0.3)
            
            // Content based on tab
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if service.selectedTab == "All" || service.selectedTab == "Claude" {
                        claudeCard
                    }
                    if service.selectedTab == "All" || service.selectedTab == "Antigravity" {
                        antigravityCard
                    }
                    if service.selectedTab == "All" || service.selectedTab == "ChatGPT" {
                        chatGPTCard
                    }
                }
            }
            .frame(maxHeight: 380)
            
            Divider()
                .opacity(0.3)
            
            // Controls & Settings
            controlsSection
        }
        .padding(14)
        .frame(width: 340)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            ZStack {
                Circle()
                    .fill(Color(nsColor: .controlAccentColor).opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(nsColor: .controlAccentColor))
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text("AI Limit Tracker")
                    .font(.system(size: 13, weight: .bold))
                Text("Claude • Antigravity • ChatGPT")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Refresh Button
            Button(action: {
                Task {
                    await service.fetchAll()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .rotationEffect(.degrees(service.isLoading ? 360 : 0))
                    .animation(service.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: service.isLoading)
            }
            .buttonStyle(.plain)
            .disabled(service.isLoading)
            .help("Refresh all limit data")
        }
    }
    
    private var tabSelectorSection: some View {
        HStack(spacing: 4) {
            ForEach(MenuBarView.availableTabs, id: \.self) { tab in
                Button(action: {
                    service.selectedTab = tab
                }) {
                    Text(tab)
                        .font(.system(size: 11, weight: service.selectedTab == tab ? .semibold : .regular))
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background(service.selectedTab == tab ? Color(nsColor: .controlAccentColor).opacity(0.2) : Color.clear)
                        .foregroundColor(service.selectedTab == tab ? Color(nsColor: .controlAccentColor) : .secondary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .cornerRadius(8)
    }
    
    // MARK: - Claude Card
    
    private var claudeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(Color.purple).frame(width: 7, height: 7)
                Text("Claude")
                    .font(.system(size: 12, weight: .bold))
                
                if let email = service.accountInfo?.emailAddress {
                    Text("(\(email))")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(Int(service.fiveHourPercent))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(service.colorForPercent(service.fiveHourPercent))
            }
            
            // 5h Session Bar
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("5-Hour Session")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    if !service.fiveHourCountdown.isEmpty {
                        Text("↻ \(service.fiveHourCountdown)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                CustomProgressBar(percent: service.fiveHourPercent, color: service.colorForPercent(service.fiveHourPercent))
                    .frame(height: 5)
            }
            
            // 7d Weekly Bar
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("7-Day Limit: \(Int(service.sevenDayPercent))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    if !service.sevenDayCountdown.isEmpty {
                        Text("↻ \(service.sevenDayCountdown)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                CustomProgressBar(percent: service.sevenDayPercent, color: service.colorForPercent(service.sevenDayPercent))
                    .frame(height: 5)
            }
            
            if service.selectedTab == "Claude", let rows = service.usage?.sevenDayBreakdown?.rows, !rows.isEmpty {
                HStack(spacing: 8) {
                    ForEach(rows) { r in
                        if r.percent > 0 {
                            Text("\(r.displayName): \(Int(r.percent))%")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }
    
    // MARK: - Antigravity Card
    
    private var antigravityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(Color.blue).frame(width: 7, height: 7)
                Text("Antigravity")
                    .font(.system(size: 12, weight: .bold))
                Text("(Gemini)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(service.agyGemini5hUsed))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(service.colorForPercent(service.agyGemini5hUsed))
            }
            
            // Gemini 5h Bar
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Gemini 5-Hour Limit")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    if !service.agyGemini5hCountdown.isEmpty {
                        Text("↻ \(service.agyGemini5hCountdown)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                CustomProgressBar(percent: service.agyGemini5hUsed, color: service.colorForPercent(service.agyGemini5hUsed))
                    .frame(height: 5)
            }
            
            // Gemini Weekly Bar
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Gemini Weekly: \(Int(service.agyGeminiWeeklyUsed))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    if !service.agyGeminiWeeklyCountdown.isEmpty {
                        Text("↻ \(service.agyGeminiWeeklyCountdown)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                CustomProgressBar(percent: service.agyGeminiWeeklyUsed, color: service.colorForPercent(service.agyGeminiWeeklyUsed))
                    .frame(height: 5)
            }
            
            // 3P models (Claude & GPT in Antigravity)
            if service.agy3p5hUsed > 0 || service.selectedTab == "Antigravity" {
                HStack {
                    Text("3P Models (Claude/GPT): \(Int(service.agy3p5hUsed))% used")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Spacer()
                    if !service.agy3p5hCountdown.isEmpty {
                        Text("↻ \(service.agy3p5hCountdown)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }
    
    // MARK: - ChatGPT Card
    
    private var chatGPTCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(Color.green).frame(width: 7, height: 7)
                Text("ChatGPT / GPT")
                    .font(.system(size: 12, weight: .bold))
                
                Text("(\(service.chatGPTPlan))")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color(nsColor: .controlAccentColor))
                
                Spacer()
                Text("\(Int(service.chatGPT5hUsed))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(service.colorForPercent(service.chatGPT5hUsed))
            }
            
            // ChatGPT 5h Primary Window
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("5-Hour Primary Window")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    if !service.chatGPT5hCountdown.isEmpty {
                        Text("↻ \(service.chatGPT5hCountdown)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                CustomProgressBar(percent: service.chatGPT5hUsed, color: service.colorForPercent(service.chatGPT5hUsed))
                    .frame(height: 5)
            }
            
            // ChatGPT Weekly Secondary Window
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("Weekly Limit: \(Int(service.chatGPTWeeklyUsed))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    if !service.chatGPTWeeklyCountdown.isEmpty {
                        Text("↻ \(service.chatGPTWeeklyCountdown)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                CustomProgressBar(percent: service.chatGPTWeeklyUsed, color: service.colorForPercent(service.chatGPTWeeklyUsed))
                    .frame(height: 5)
            }
            
            if let count = service.chatGPTUsage?.resetCredits?.availableCount, count > 0 {
                HStack {
                    Image(systemName: "bolt.shield")
                        .font(.system(size: 9))
                        .foregroundColor(.green)
                    Text("\(count) Reset Credit\(count > 1 ? "s" : "") Available")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 8) {
            // Menu Bar Display Mode
            HStack {
                Text("Menu Bar Title:")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Picker("", selection: $service.menuBarMode) {
                    ForEach(MenuBarDisplayMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 130)
            }
            
            // Desktop Widget toggle
            HStack {
                Label("Desktop Widget", systemImage: "macwindow.on.rectangle")
                    .font(.system(size: 11))
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
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(nsColor: .separatorColor).opacity(0.3))
                    .frame(height: geo.size.height)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: max(3, min(geo.size.width * CGFloat(percent / 100.0), geo.size.width)), height: geo.size.height)
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
