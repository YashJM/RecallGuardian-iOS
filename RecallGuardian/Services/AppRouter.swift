import Foundation
import Observation

/// Shared navigation state so a tapped notification can open the exact recall,
/// from anywhere (including a cold launch).
@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()

    var tab: Int = Snapshot.tab
    var feedPath: [Recall] = []
    /// A recall id waiting to be shown once the feed has loaded.
    var pendingNID: String?

    private init() {}

    /// Called when a recall notification is tapped.
    func openRecall(nid: String) {
        tab = 0
        pendingNID = nid
    }

    /// Called when a digest ("N new recalls") notification is tapped.
    func openFeed() {
        tab = 0
    }
}
