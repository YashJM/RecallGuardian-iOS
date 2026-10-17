import SwiftUI

@main
struct RecallGuardianApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("Recalls", systemImage: "list.bullet.rectangle") }

            GuardianView()
                .tabItem { Label("Guardian", systemImage: "shield") }
        }
        .tint(Theme.brand)
    }
}

/// V2 placeholder — the on-device household watchlist. Kept intentionally simple
/// until accounts + matching land (see the roadmap in the concept canvas).
struct GuardianView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.brand)
                Text("Your Guardian")
                    .font(.display(22, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Soon: tell RecallGuardian what your household owns — your car, baby gear, the brands in your cabinet — and get notified only when a recall matches. It stays on this device.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.paper)
            .navigationTitle("Guardian")
        }
    }
}
