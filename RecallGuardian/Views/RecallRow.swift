import SwiftUI

/// Clean recall card: a severity pill, a prominent title, and one useful
/// secondary line. No busy thumbnail — easy to scan.
struct RecallRow: View {
    let recall: Recall

    private var risk: String? { RecallInsights.whoAtRisk(recall) }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                SeverityPill(tier: recall.tier)
                Text(recall.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                Spacer(minLength: 6)
                if let date = recall.lastUpdated {
                    Text(Self.relative(date))
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                }
            }

            Text(recall.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let risk {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11)).foregroundStyle(Theme.riskFg)
                    Text(risk)
                        .font(.system(size: 13)).foregroundStyle(Theme.ink.opacity(0.75))
                        .lineLimit(1)
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 3)
    }

    static func relative(_ d: Date) -> String {
        let days = Int(Date().timeIntervalSince(d) / 86_400)
        if days <= 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days)d ago" }
        if days < 30 { return "\(days / 7)w ago" }
        if days < 365 { return "\(days / 30)mo ago" }
        return "\(days / 365)y ago"
    }
}

/// Small severity chip — a coloured dot + label on a soft tint.
struct SeverityPill: View {
    let tier: Tier
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(Theme.severity(tier)).frame(width: 6, height: 6)
            Text(tier.label.uppercased())
                .font(.system(size: 11, weight: .bold)).tracking(0.3)
        }
        .foregroundStyle(Theme.severity(tier))
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Theme.severityBackground(tier), in: Capsule())
    }
}
