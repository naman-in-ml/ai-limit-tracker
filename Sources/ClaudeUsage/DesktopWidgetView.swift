import ClaudeUsageCore
import SwiftUI

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
        VStack(spacing: 12) {
            // Header
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(nsColor: .controlAccentColor))
                
                Text("Claude")
                    .font(.system(size: 13, weight: .bold))
                
                Circle()
                    .fill(service.statusColor)
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
            
            // Dual Circular Progress Gauges
            HStack(spacing: 20) {
                // 5-Hour Session Ring
                CircularGauge(
                    percent: service.fiveHourPercent,
                    title: "5h Session",
                    countdown: service.fiveHourCountdown.isEmpty ? "Ready" : "↻ \(service.fiveHourCountdown)",
                    color: colorForPercent(service.fiveHourPercent)
                )
                
                // 7-Day Weekly Ring
                CircularGauge(
                    percent: service.sevenDayPercent,
                    title: "7d Weekly",
                    countdown: service.sevenDayCountdown.isEmpty ? "Ready" : "↻ \(service.sevenDayCountdown)",
                    color: colorForPercent(service.sevenDayPercent)
                )
            }
            .padding(.vertical, 2)
            
            // Footer breakdown
            if let rows = service.usage?.sevenDayBreakdown?.rows, !rows.isEmpty {
                HStack(spacing: 10) {
                    ForEach(rows) { row in
                        if row.percent > 0 {
                            Text("\(row.displayName): \(Int(row.percent))%")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
            } else if let email = service.accountInfo?.emailAddress {
                HStack {
                    Text(email)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
            }
        }
        .padding(14)
        .frame(width: 280, height: 155)
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
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
        )
    }
    
    private func colorForPercent(_ pct: Double) -> Color {
        if pct >= 85 {
            return .red
        } else if pct >= 60 {
            return .orange
        } else {
            return .green
        }
    }
}

// Circular Gauge Component
struct CircularGauge: View {
    var percent: Double
    var title: String
    var countdown: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color(nsColor: .separatorColor).opacity(0.25), lineWidth: 6)
                    .frame(width: 58, height: 58)
                
                // Progress Arc
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(percent / 100.0, 0.01), 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 58, height: 58)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: percent)
                
                // Center Percentage
                Text("\(Int(percent))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(countdown)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
