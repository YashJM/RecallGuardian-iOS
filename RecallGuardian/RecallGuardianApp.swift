import SwiftUI

@main
struct RecallGuardianApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = RecallStore()
    @State private var watchlist = Watchlist()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(watchlist)
        }
    }
}

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("Recalls", systemImage: "list.bullet.rectangle") }

            GuardianView()
                .tabItem { Label("Guardian", systemImage: "shield") }
        }
        .tint(Theme.brand)
        .onChange(of: scenePhase) { _, phase in
            // Line up the next background check whenever we leave the foreground.
            if phase == .background { BackgroundRefresh.schedule() }
        }
    }
}
