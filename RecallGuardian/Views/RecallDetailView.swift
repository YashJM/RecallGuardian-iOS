import SwiftUI

/// The Brief: who's at risk, numbered what-to-do steps, the real product photo
/// and province (fetched from the official notice), and the source link.
struct RecallDetailView: View {
    let recall: Recall
    @State private var extras: RecallExtras = .empty

    private var risk: String? { RecallInsights.whoAtRisk(recall) }
    private var steps: [String] { RecallInsights.steps(recall) }

    private static let dateStyle: Date.FormatStyle = .dateTime.year().month(.wide).day()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Rectangle().fill(Theme.severity(recall.tier)).frame(height: 6)

                VStack(alignment: .leading, spacing: 0) {
                    lead
                    if let risk { riskBanner(risk) }
                    if !steps.isEmpty { stepsSection }
                    if !recall.issue.isEmpty { section("The issue", recall.issue) }
                    if !recall.product.isEmpty { section("Affected product", recall.product) }
                    if !extras.distribution.isEmpty { distributionSection }
                    section("Issued by", recall.agency)
                    sourceSection
                }
                .padding(20)
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.line, lineWidth: 1))
            .padding(16)
        }
        .background(Theme.paper)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { extras = await RecallExtrasService.shared.extras(for: recall) }
    }

    private var lead: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: Theme.symbol(recall.group))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.category(recall.group))
                    Text(recall.category).font(.display(12, .semibold)).foregroundStyle(Theme.muted)
                    if !recall.recallClass.isEmpty {
                        Text("· \(recall.recallClass)").font(.display(12, .medium)).foregroundStyle(Theme.muted)
                    }
                }
                Text(recall.title)
                    .font(.display(23, .heavy)).foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Circle().fill(Theme.severity(recall.tier)).frame(width: 7, height: 7)
                    Text("\(recall.tier.label) priority").font(.display(12, .bold)).foregroundStyle(Theme.severity(recall.tier))
                    if let d = recall.lastUpdated {
                        Text("· Updated \(d.formatted(Self.dateStyle))")
                            .font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.muted)
                    }
                }
            }
            photo
        }
    }

    private var photo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Theme.category(recall.group).opacity(0.12))
            if let url = extras.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: Image(systemName: Theme.symbol(recall.group))
                        .font(.system(size: 34)).foregroundStyle(Theme.category(recall.group))
                    }
                }
            } else {
                Image(systemName: Theme.symbol(recall.group))
                    .font(.system(size: 34)).foregroundStyle(Theme.category(recall.group))
            }
        }
        .frame(width: 104, height: 104)
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Theme.line, lineWidth: 1))
    }

    private func riskBanner(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18)).foregroundStyle(Theme.riskFg)
            VStack(alignment: .leading, spacing: 3) {
                Text("MOST AT RISK").font(.display(11, .bold)).tracking(0.6).foregroundStyle(Theme.riskFg)
                Text(text).font(.system(size: 15)).foregroundStyle(Theme.ink)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.riskBg, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Theme.riskFg.opacity(0.25), lineWidth: 1))
        .padding(.top, 22)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("What you should do")
            ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i + 1)")
                        .font(.display(13, .bold)).foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Theme.category(.medicine), in: Circle())
                    Text(step).font(.system(size: 16)).foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 24)
    }

    private var distributionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Where it was sold")
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse").foregroundStyle(Theme.brand).font(.system(size: 13))
                Text(extras.distribution).font(.display(14, .semibold)).foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 11).padding(.vertical, 7)
            .background(Theme.surface, in: Capsule()).overlay(Capsule().stroke(Theme.line, lineWidth: 1))
            Text("Reported in the official notice — confirm there.")
                .font(.system(size: 12)).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 24)
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let url = recall.sourceURL {
                Link(destination: url) {
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.up.right")
                        Text("Read the official Government of Canada notice")
                    }
                    .font(.display(15, .semibold)).foregroundStyle(Theme.brand)
                    .padding(.horizontal, 15).padding(.vertical, 11)
                    .overlay(Capsule().stroke(Theme.brand.opacity(0.5), lineWidth: 1))
                }
            }
            Text("RecallGuardian ranks, illustrates and rewrites recalls in plain language. The official notice is authoritative — confirm model numbers, lot codes, dates and remedies there.")
                .font(.system(size: 12)).foregroundStyle(Theme.muted)
        }
        .padding(.top, 24)
    }

    private func section(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            label(title)
            Text(value).font(.system(size: 16)).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 24)
    }

    private func label(_ t: String) -> some View {
        Text(t.uppercased()).font(.display(12, .semibold)).tracking(1.1).foregroundStyle(Theme.muted)
    }
}
