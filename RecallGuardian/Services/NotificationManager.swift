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
        content.threadIdentifier = Self.threadId
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

    /// One coalesced "N new recalls" notification, so a batch of matches never
    /// floods the user with a pile of individual alerts.
    static func notifySummary(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "\(count) new recalls"
        content.body = "Several things you watch were just recalled. Tap to review."
        content.sound = .default
        content.threadIdentifier = Self.threadId
        content.userInfo = ["digest": true]
        let request = UNNotificationRequest(
            identifier: "digest-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // All recall alerts share one thread so they stack in Notification Center.
    private static let threadId = "recall-alerts"
}
