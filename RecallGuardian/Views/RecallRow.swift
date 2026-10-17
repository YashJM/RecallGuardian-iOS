import SwiftUI

/// The signature object: a recall card with a severity stripe down its left edge.
struct RecallRow: View {
    let recall: Recall

    private static let dateStyle: Date.FormatStyle =
        .dateTime.year().month(.abbreviated).day()

    var body: some View {
        HStack(spacing: 0) {
            Theme.severity(recall.tier)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    TierPill(tier: recall.tier)
                    Text(recall.category)
                        .font(.display(12, .semibold))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if let date = recall.lastUpdated {
                        Text(date, format: Self.dateStyle)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.muted)
                    }
                }

                Text(recall.title)
                    .font(.display(16, .bold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                let subtitle = recall.issue.isEmpty ? recall.product : recall.issue
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.ink.opacity(0.85))
                        .lineLimit(2)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.line, lineWidth: 1)
        )
    }
}

struct TierPill: View {
    let tier: Tier
    var body: some View {
        Text(tier.label.uppercased())
            .font(.display(11, .bold))
            .tracking(0.6)
            .foregroundStyle(Theme.severity(tier))
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(Theme.severityBackground(tier), in: Capsule())
    }
}
