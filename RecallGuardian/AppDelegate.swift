import UIKit
import UserNotifications

/// Registers the background refresh task at launch and presents notifications
/// while the app is open. Remote (APNs) hooks are stubbed for when push is added.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BackgroundRefresh.register()
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show matches even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    // Tapping a recall notification opens that exact recall.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let nid = response.notification.request.content.userInfo["nid"] as? String else { return }
        await MainActor.run { AppRouter.shared.openRecall(nid: nid) }
    }

    // MARK: Remote notifications (APNs) — wired for later; no-ops until push is enabled.

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { @MainActor in PushService.shared.setToken(token) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // APNs registration failed (e.g. no network, or the Simulator which
        // can't get a token). The on-device background refresh still delivers
        // local match alerts, so this is non-fatal.
    }
}
