import SwiftUI

/// Shown once on first launch. Explains the app in three lines and gets out of
/// the way.
struct OnboardingView: View {
    var onDone: () -> Void

    private let points: [(icon: String, title: String, body: String)] = [
        ("list.bullet.rectangle.fill", "Every Canadian recall, ranked",
         "Food and medicine first — one plain-language feed from the CFIA, Health Canada and Transport Canada."),
        ("magnifyingglass", "Check in seconds",
         "Search any product, brand or ingredient to see if it's recalled right now."),
        ("bell.badge.fill", "Get alerted for your household",
         "Add what you own and pick how loud. We check in the background and notify you only on a match — all on your device."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.brand)
                Image(systemName: "checkmark")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 96, height: 96)
            .shadow(color: Theme.brand.opacity(0.3), radius: 16, y: 8)

            Text("RecallGuardian")
                .font(.display(28, .heavy)).foregroundStyle(Theme.ink)
                .padding(.top, 16)
            Text("Canada's safety recalls, made useful")
                .font(.system(size: 15)).foregroundStyle(Theme.muted)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 22) {
                ForEach(points, id: \.title) { p in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: p.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.brand)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(p.title).font(.display(16, .bold)).foregroundStyle(Theme.ink)
                            Text(p.body).font(.system(size: 14)).foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.top, 34)
            .padding(.horizontal, 6)

            Spacer(minLength: 20)

            Button(action: onDone) {
                Text("Get started")
                    .font(.display(17, .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(Theme.brand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            Text("Official notices are always one tap away. We re-rank and reword; we're not the government.")
                .font(.system(size: 11)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
    }
}
