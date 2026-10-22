import SwiftUI

@main
struct RecallGuardianApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = RecallStore()
    @State private var watchlist = Watchlist()
    @State private var prefs = AlertPreferences()
    @State private var updates = UpdateChecker()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(watchlist)
                .environment(prefs)
                .environment(updates)
        }
    }
}

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(Watchlist.self) private var watchlist
    @Environment(AlertPreferences.self) private var prefs
    @Environment(UpdateChecker.self) private var updates
    @Environment(\.openURL) private var openURL
    @State private var tab = Snapshot.tab

    var body: some View {
        TabView(selection: $tab) {
            FeedView()
                .tag(0)
                .tabItem { Label("Recalls", systemImage: "list.bullet.rectangle") }

            GuardianView()
                .tag(1)
                .tabItem { Label("Guardian", systemImage: "shield") }
        }
        .tint(Theme.brand)
        .preferredColorScheme(.light)
        .onChange(of: scenePhase) { _, phase in
            // Line up the next background check whenever we leave the foreground.
            if phase == .background { BackgroundRefresh.schedule() }
            if phase == .active { Task { await updates.checkIfNeeded() } }
        }
        .sheet(isPresented: Binding(get: { updates.isPresenting }, set: { if !$0 { updates.dismiss() } })) {
            if let update = updates.available {
                UpdateSheet(update: update) {
                    openURL(update.storeURL)
                    updates.dismiss()
                } onLater: {
                    updates.dismiss()
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            await updates.checkIfNeeded()
            // Snapshot/demo seeding — only when launched with the env flags, never in production.
            if Snapshot.seed {
                if watchlist.items.isEmpty {
                    watchlist.addBrand("Teva")
                    watchlist.addBrand("Honda")
                    watchlist.toggleCategory(.kids)
                }
                prefs.enabled = true
            }
        }
    }
}

/// Launch-time flags used only for deterministic screenshots (set via
/// SIMCTL_CHILD_RG_* env vars). Absent in any real launch, so this is inert.
enum Snapshot {
    private static let env = ProcessInfo.processInfo.environment
    static var tab: Int { env["RG_TAB"] == "guardian" ? 1 : 0 }
    static var seed: Bool { env["RG_SEED"] == "1" }
    static var openDetail: Bool { env["RG_DETAIL"] == "1" }
    /// Pretend a newer version is on the App Store (debug builds only).
    static var fakeUpdate: Bool { env["RG_FAKE_UPDATE"] == "1" }
}
