import Foundation
import BackgroundTasks

/// Periodic on-device check: fetch the latest recalls, match them against the
/// watchlist, and fire a local notification for anything new. Scheduled by iOS
/// (Background App Refresh); no server involved.
enum BackgroundRefresh {
    static let taskId = "ca.recallguardian.app.refresh"
    private static let seenKey = "notifiedNIDs.v1"
    private static let watchKey = "watchlist.v1"

    /// Call once at launch (from the app delegate) before the app finishes launching.
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskId, using: nil) { task in
            guard let refresh = task as? BGAppRefreshTask else { return }
            handle(refresh)
        }
    }

    /// Ask iOS to run the check again, no sooner than ~6 hours from now.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGAppRefreshTask) {
        schedule() // always line up the next run
        let work = Task {
            await runCheck()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = { work.cancel() }
    }

    /// Fetch, match, notify. Also callable from the foreground (e.g. pull to refresh).
    static func runCheck() async {
        let prefs = AlertPreferences.current()
        guard prefs.enabled else { return }
        let items = loadWatchItems()
        guard !items.isEmpty else { return }

        let store = await RecallStore()
        await store.load(force: true)
        let recalls = await store.recalls
        guard !recalls.isEmpty else { return }

        var seen = loadSeen()
        for (recall, item) in WatchMatcher.matches(in: recalls, items: items)
        where !seen.contains(recall.nid) && prefs.threshold.allows(recall.tier) {
            NotificationManager.notify(recall: recall, matched: item)
            seen.insert(recall.nid)
        }
        saveSeen(seen)
    }

    /// Mark everything currently matching as already-seen, so the first real
    /// background run only notifies on genuinely new recalls (not the backlog).
    static func primeSeen(with recalls: [Recall], items: [WatchItem]) {
        guard !items.isEmpty else { return }
        var seen = loadSeen()
        for (recall, _) in WatchMatcher.matches(in: recalls, items: items) {
            seen.insert(recall.nid)
        }
        saveSeen(seen)
    }

    // MARK: Storage helpers

    private static func loadWatchItems() -> [WatchItem] {
        guard let data = UserDefaults.standard.data(forKey: watchKey),
              let items = try? JSONDecoder().decode([WatchItem].self, from: data)
        else { return [] }
        return items
    }

    private static func loadSeen() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: seenKey) ?? [])
    }

    private static func saveSeen(_ seen: Set<String>) {
        UserDefaults.standard.set(Array(seen), forKey: seenKey)
    }
}
