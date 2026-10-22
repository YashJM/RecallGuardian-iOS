import SwiftUI

/// Information-led feed row: a soft category tile, a small severity dot (not a
/// loud rail), the plain-language title, and the who's-at-risk line when we can
/// derive one. Mirrors the web app's calmer feed.
struct RecallRow: View {
    let recall: Recall

    private var risk: String? { RecallInsights.whoAtRisk(recall) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.category(recall.group).opacity(0.13))
                Image(systemName: Theme.symbol(recall.group))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Theme.category(recall.group))
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Circle().fill(Theme.severity(recall.tier)).frame(width: 7, height: 7)
                        Text(recall.tier.label.uppercased())
                            .font(.display(10, .bold)).tracking(0.4)
                            .foregroundStyle(Theme.muted)
                    }
                    Text(recall.category)
                        .font(.display(12, .semibold)).foregroundStyle(Theme.muted)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    if let date = recall.lastUpdated {
                        Text(Self.relative(date))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.muted)
                    }
                }

                Text(recall.title)
                    .font(.display(15, .bold)).foregroundStyle(Theme.ink)
                    .lineLimit(3).fixedSize(horizontal: false, vertical: true)

                if let risk {
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10)).foregroundStyle(Theme.riskFg)
                        Text("Most at risk: \(risk)")
                            .font(.system(size: 12)).foregroundStyle(Theme.ink)
                            .lineLimit(2)
                    }
                } else {
                    let sub = recall.issue.isEmpty ? recall.product : recall.issue
                    if !sub.isEmpty {
                        Text(sub).font(.system(size: 12)).foregroundStyle(Theme.muted).lineLimit(1)
                    }
                }
            }
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }

    static func relative(_ d: Date) -> String {
        let days = Int(Date().timeIntervalSince(d) / 86_400)
        if days <= 0 { return "today" }
        if days == 1 { return "yesterday" }
        if days < 7 { return "\(days) days ago" }
        if days < 30 { return "\(days / 7) wk ago" }
        if days < 365 { return "\(days / 30) mo ago" }
        return "\(days / 365) yr ago"
    }
}
