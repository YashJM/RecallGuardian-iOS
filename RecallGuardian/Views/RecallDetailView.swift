import SwiftUI

struct RecallDetailView: View {
    let recall: Recall

    private static let dateStyle: Date.FormatStyle =
        .dateTime.year().month(.wide).day()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Theme.severity(recall.tier).frame(height: 6)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        TierPill(tier: recall.tier)
                        Text(recall.category)
                            .font(.display(13, .semibold))
                            .foregroundStyle(Theme.muted)
                        Spacer(minLength: 4)
                        if let date = recall.lastUpdated {
                            Text("Updated \(date.formatted(Self.dateStyle))")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Theme.muted)
                        }
                    }
                    .padding(.bottom, 14)

                    Text(recall.title)
                        .font(.display(26, .heavy))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    section("Affected product", recall.product)
                    section("The issue", recall.issue)
                    section("What you should do", recall.whatToDo)
                    section("Issued by", recall.agency)

                    if let url = recall.sourceURL {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.right")
                                Text("Read the official Government of Canada notice")
                            }
                            .font(.display(14, .semibold))
                            .foregroundStyle(Theme.brand)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .overlay(Capsule().stroke(Theme.brand.opacity(0.5), lineWidth: 1))
                        }
                        .padding(.top, 24)

                        Text("RecallGuardian re-ranks and rewrites recalls in plain language. The official notice is authoritative — confirm model numbers, dates and remedies there.")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.muted)
                            .padding(.top, 12)
                    }
                }
                .padding(20)
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.line, lineWidth: 1)
            )
            .padding(16)
        }
        .background(Theme.paper)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func section(_ label: String, _ value: String) -> some View {
        if !value.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(label.uppercased())
                    .font(.display(12, .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.muted)
                Text(value)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 24)
        }
    }
}
