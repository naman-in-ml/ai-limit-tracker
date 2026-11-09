import SwiftUI
import ClaudeUsageCore

public struct DesktopWidgetView: View {
    @ObservedObject var service: UsageService
    var onClose: () -> Void
    var onTogglePin: () -> Void
    var isPinnedToDesktop: Bool
    
    public init(
        service: UsageService = .shared,
        isPinnedToDesktop: Bool = true,
        onClose: @escaping () -> Void = {},
        onTogglePin: @escaping () -> Void = {}
    ) {
        self.service = service
        self.isPinnedToDesktop = isPinnedToDesktop
        self.onClose = onClose
        self.onTogglePin = onTogglePin
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(nsColor: .controlAccentColor))
                
                Text("AI Usage Limits")
                    .font(.system(size: 12, weight: .bold))
                
                Circle()
                    .fill(service.overallStatusColor)
                    .frame(width: 7, height: 7)
                
                Spacer()
                
                // Pin button
                Button(action: onTogglePin) {
                    Image(systemName: isPinnedToDesktop ? "pin.fill" : "pin.slash")
                        .font(.system(size: 10))
                        .foregroundColor(isPinnedToDesktop ? Color(nsColor: .controlAccentColor) : .secondary)
                        .padding(3)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(isPinnedToDesktop ? "Pinned to Desktop wallpaper (behind apps)" : "Floating above apps")
                
                // Close button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(3)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Close Widget")
            }
            
            // Triple Circular Gauges: Claude, Antigravity, GPT
            HStack(spacing: 14) {
                // Claude
                CircularGauge(
                    percent: service.fiveHourPercent,
                    title: "Claude",
                    tag: "5h",
                    countdown: service.fiveHourCountdown.isEmpty ? "Ready" : "↻\(service.fiveHourCountdown)",
                    color: service.claudeStatusColor
                )
                
                // Antigravity (Gemini)
                CircularGauge(
                    percent: service.agyGemini5hUsed,
                    title: "Antigravity",
                    tag: "5h",
                    countdown: service.agyGemini5hCountdown.isEmpty ? "Ready" : "↻\(service.agyGemini5hCountdown)",
                    color: service.agyStatusColor
                )
                
                // ChatGPT / GPT
                CircularGauge(
                    percent: service.chatGPT5hUsed,
                    title: "GPT",
                    tag: "5h",
                    countdown: service.chatGPT5hCountdown.isEmpty ? "Ready" : "↻\(service.chatGPT5hCountdown)",
                    color: service.chatGPTStatusColor
                )
            }
            .padding(.vertical, 2)
            
            // Footer Weekly Summary
            HStack(spacing: 6) {
                Text("Weekly:")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text("C: \(Int(service.sevenDayPercent))%")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary.opacity(0.5))
                
                Text("AGY: \(Int(service.agyGeminiWeeklyUsed))%")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary.opacity(0.5))
                
                Text("GPT: \(Int(service.chatGPTWeeklyUsed))%")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(14)
        .frame(width: 320, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.75))
                .background(
                    VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 8)
        )
    }
}

// Circular Gauge Component
struct CircularGauge: View {
    var percent: Double
    var title: String
    var tag: String
    var countdown: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color(nsColor: .separatorColor).opacity(0.25), lineWidth: 5)
                    .frame(width: 52, height: 52)
                
                // Progress Arc
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(percent / 100.0, 0.01), 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: percent)
                
                // Center Percentage
                Text("\(Int(percent))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(countdown)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
