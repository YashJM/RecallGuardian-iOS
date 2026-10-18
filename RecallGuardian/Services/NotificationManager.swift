import Foundation
import UserNotifications

/// Local notifications for watchlist matches. No server, no APNs — iOS delivers
/// these from the background refresh. (APNs can be layered on later for
/// lower-latency delivery; the App ID has Push enabled for that.)
enum NotificationManager {

    @discardableResult
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Fire a local notification for a matched recall.
    static func notify(recall: Recall, matched item: WatchItem) {
        let content = UNMutableNotificationContent()
        content.title = recall.tier == .critical ? "Critical recall — \(item.label)" : "Recall — \(item.label)"
        content.body = recall.title
        content.sound = .default
        content.threadIdentifier = "recall-matches"
        content.userInfo = ["nid": recall.nid]
        if #available(iOS 15.0, *) {
            content.interruptionLevel = recall.tier == .critical ? .timeSensitive : .active
        }

        let request = UNNotificationRequest(
            identifier: "match-\(recall.nid)",
            content: content,
            trigger: nil // deliver now
        )
        UNUserNotificationCenter.current().add(request)
    }
}
