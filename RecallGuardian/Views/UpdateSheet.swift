import SwiftUI

/// "A new version is ready." Shown once per new version, never blocking:
/// people can update now or carry on with the version they have.
struct UpdateSheet: View {
    let update: UpdateChecker.Update
    var onUpdate: () -> Void
    var onLater: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.severityBackground(.standard))
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Theme.severity(.standard))
                }
                .frame(width: 54, height: 54)
                VStack(alignment: .leading, spacing: 3) {
                    Text("A new version is ready")
                        .font(.display(20, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Version \(update.version) · you have \(UpdateChecker.installedVersion)")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.muted)
                        .monospacedDigit()
                }
            }

            if let notes = update.notes {
                VStack(alignment: .leading, spacing: 6) {
                    Text("WHAT'S NEW")
                        .font(.display(11, .semibold))
                        .tracking(1.1)
                        .foregroundStyle(Theme.muted)
                    // Short notes fit as they are; long ones scroll inside the box.
                    ViewThatFits(in: .vertical) {
                        notesText(notes)
                        ScrollView { notesText(notes) }
                    }
                    .frame(maxHeight: 140)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line, lineWidth: 1))
            } else {
                Text("Updating keeps your recall checks and alerts working their best.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.muted)
            }

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Button(action: onUpdate) {
                    Text("Update on the App Store")
                        .font(.display(16, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(Theme.brand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Button(action: onLater) {
                    Text("Not now")
                        .font(.display(16, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .padding(.bottom, 12)
        .background(Theme.paper)
    }

    private func notesText(_ notes: String) -> some View {
        Text(notes)
            .font(.system(size: 15))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The quiet reminder left in the Guardian tab after "Not now".
struct UpdateAvailableRow: View {
    let update: UpdateChecker.Update
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(update.storeURL)
        } label: {
            HStack(spacing: 11) {
                Image(systemName: "arrow.down.app")
                    .font(.system(size: 19))
                    .foregroundStyle(Theme.severity(.standard))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Update available").font(.display(15, .bold)).foregroundStyle(Theme.ink)
                    Text("Version \(update.version) is on the App Store")
                        .font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
                Spacer()
                Text("Update")
                    .font(.display(14, .semibold))
                    .foregroundStyle(Theme.brand)
            }
            .padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the App Store")
    }
}

#Preview {
    UpdateSheet(update: .init(version: "1.1", notes: "• Product photos on every recall\n• Bug fixes", storeURL: URL(string: "https://apps.apple.com")!), onUpdate: {}, onLater: {})
}
