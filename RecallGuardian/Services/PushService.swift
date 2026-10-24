import UIKit
import Foundation

/// Registers this device with the RecallGuardian push backend so it receives
/// APNs alerts for new recalls in the categories the user watches. Anonymous:
/// the APNs token is the identity, and preferences are category + severity.
///
/// This complements the on-device background refresh (which still handles brand
/// matches locally) by delivering fast, server-pushed category alerts.
@MainActor
final class PushService {
    static let shared = PushService()

    private let registerURL = URL(string: "https://recallguardian.ca/api/register-device")!
    private let tokenKey = "push.deviceToken"
    private let snapshotKey = "push.lastSnapshot"

    private var deviceToken: String? {
        didSet { UserDefaults.standard.set(deviceToken, forKey: tokenKey) }
    }

    private init() {
        deviceToken = UserDefaults.standard.string(forKey: tokenKey)
    }

    private struct Snapshot: Codable, Equatable {
        var categories: [String]
        var threshold: String
        var enabled: Bool
    }

    /// Ask iOS for an APNs token (safe to call repeatedly; the token can change).
    /// Authorization is requested separately via NotificationManager.
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Called from AppDelegate when APNs returns the device token.
    func setToken(_ token: String) {
        deviceToken = token
        Task { await sync() }
    }

    /// Record the latest preferences and push them to the backend.
    func updatePreferences(categories: [String], threshold: String, enabled: Bool) {
        let snap = Snapshot(categories: categories.sorted(), threshold: threshold, enabled: enabled)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: snapshotKey)
        }
        Task { await sync() }
    }

    private func lastSnapshot() -> Snapshot {
        if let data = UserDefaults.standard.data(forKey: snapshotKey),
           let snap = try? JSONDecoder().decode(Snapshot.self, from: data) {
            return snap
        }
        return Snapshot(categories: [], threshold: "all", enabled: false)
    }

    private func sync() async {
        guard let token = deviceToken else { return }
        let snap = lastSnapshot()
        var req = URLRequest(url: registerURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "token": token,
            "platform": "ios",
            "categories": snap.categories,
            "threshold": snap.threshold,
            "enabled": snap.enabled,
        ])
        _ = try? await URLSession.shared.data(for: req)
    }
}
