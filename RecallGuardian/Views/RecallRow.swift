import SwiftUI

func relativeRecallDate(_ d: Date) -> String {
    let days = Int(Date().timeIntervalSince(d) / 86_400)
    if days <= 0 { return "Today" }
    if days == 1 { return "Yesterday" }
    if days < 7 { return "\(days)d ago" }
    if days < 30 { return "\(days / 7)w ago" }
    if days < 365 { return "\(days / 30)mo ago" }
    return "\(days / 365)y ago"
}

/// Small severity chip — a coloured dot + label on a soft tint.
struct SeverityPill: View {
    let tier: Tier
    var solid = false
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(Theme.severity(tier)).frame(width: 6, height: 6)
            Text(tier.label.uppercased())
                .font(.system(size: 11, weight: .bold)).tracking(0.3)
        }
        .foregroundStyle(Theme.severity(tier))
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(solid ? AnyShapeStyle(.white.opacity(0.95)) : AnyShapeStyle(Theme.severityBackground(tier)), in: Capsule())
    }
}

/// Thumbnail feed row: product photo + title + who's-at-risk.
struct RecallRow: View {
    let recall: Recall
    private var risk: String? { RecallInsights.whoAtRisk(recall) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RecallPhoto(recall: recall, corner: 12)
                .frame(width: 74, height: 74)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    SeverityPill(tier: recall.tier)
                    Text(recall.category).font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.muted).lineLimit(1)
                    Spacer(minLength: 4)
                    if let date = recall.lastUpdated {
                        Text(relativeRecallDate(date)).font(.system(size: 12)).foregroundStyle(Theme.muted)
                    }
                }
                Text(recall.title).font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                if let risk {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 11)).foregroundStyle(Theme.riskFg)
                        Text(risk).font(.system(size: 13)).foregroundStyle(Theme.ink.opacity(0.75)).lineLimit(1)
                    }
                }
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 9, y: 3)
    }
}

/// Showcase hero card: a big product image for the most urgent recall.
struct RecallHeroCard: View {
    let recall: Recall
    private var risk: String? { RecallInsights.whoAtRisk(recall) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecallPhoto(recall: recall, corner: 0)
                .frame(height: 184)
                .overlay(alignment: .top) {
                    HStack(spacing: 8) {
                        SeverityPill(tier: recall.tier, solid: true)
                        Spacer()
                        Text("\(recall.category) · \(recall.lastUpdated.map(relativeRecallDate) ?? "")")
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.ink)
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(.white.opacity(0.92), in: Capsule())
                            .lineLimit(1)
                    }
                    .padding(11)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(recall.title).font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.ink).lineLimit(3).fixedSize(horizontal: false, vertical: true)
                if let risk {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 12)).foregroundStyle(Theme.riskFg)
                        Text("Most at risk: \(risk)").font(.system(size: 13.5)).foregroundStyle(Theme.ink.opacity(0.8)).lineLimit(2)
                    }
                }
            }
            .padding(15)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 5)
    }
}
