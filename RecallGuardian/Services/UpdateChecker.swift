import Foundation
import Observation

/// Finds out whether a newer version of the app is on the App Store, using
/// Apple's public lookup service (no server of ours). It never forces
/// anything: a newer version gets one gentle sheet, and after "Not now" only
/// a quiet row in the Guardian tab. Any failure (offline, not in the store
/// yet) is silent.
@MainActor
@Observable
final class UpdateChecker {
    struct Update: Equatable {
        let version: String
        let notes: String?
        let storeURL: URL
    }

    /// A newer version that this device can install, if there is one.
    private(set) var available: Update?
    /// Drives the sheet. True once per new version.
    var isPresenting = false

    private static let bundleID = "ca.recallguardian.app"
    private static let lastCheckKey = "update.lastCheck"
    private static let dismissedKey = "update.dismissedVersion"
    private static let checkInterval: TimeInterval = 12 * 60 * 60

    static var installedVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    /// Call on launch and whenever the app comes back to the foreground.
    func checkIfNeeded() async {
        #if DEBUG
        if Snapshot.fakeUpdate {
            show(Update(version: "1.1",
                        notes: "• Product photos on every recall\n• Faster Guardian checks\n• Bug fixes",
                        storeURL: URL(string: "https://apps.apple.com/ca/app/id0")!))
            return
        }
        #endif
        let defaults = UserDefaults.standard
        if let last = defaults.object(forKey: Self.lastCheckKey) as? Date,
           Date().timeIntervalSince(last) < Self.checkInterval {
            return
        }
        defaults.set(Date(), forKey: Self.lastCheckKey)
        guard let update = await Self.fetchNewerVersion() else { return }
        show(update)
    }

    func dismiss() {
        if let available { UserDefaults.standard.set(available.version, forKey: Self.dismissedKey) }
        isPresenting = false
    }

    private func show(_ update: Update) {
        available = update
        let dismissed = UserDefaults.standard.string(forKey: Self.dismissedKey)
        isPresenting = dismissed != update.version
    }

    private static func fetchNewerVersion() async -> Update? {
        // `country=ca`: the app is on the Canadian store; without it Apple looks in the US store.
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)&country=ca") else { return nil }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let result = try? JSONDecoder().decode(LookupResponse.self, from: data).results.first,
              let storeURL = URL(string: result.trackViewUrl),
              isVersion(result.version, newerThan: installedVersion)
        else { return nil }
        // Don't suggest an update this iPhone can't install.
        if let minimum = result.minimumOsVersion,
           isVersion(minimum, newerThan: deviceOSVersion) {
            return nil
        }
        let notes = result.releaseNotes?.trimmingCharacters(in: .whitespacesAndNewlines)
        return Update(version: result.version, notes: notes?.isEmpty == true ? nil : notes, storeURL: storeURL)
    }

    /// "1.10" is newer than "1.9"; missing parts count as 0.
    nonisolated static func isVersion(_ a: String, newerThan b: String) -> Bool {
        let x = a.split(separator: ".").map { Int($0) ?? 0 }
        let y = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(x.count, y.count) {
            let l = i < x.count ? x[i] : 0, r = i < y.count ? y[i] : 0
            if l != r { return l > r }
        }
        return false
    }

    private struct LookupResponse: Decodable { let results: [Result] }
    private struct Result: Decodable {
        let version: String
        let trackViewUrl: String
        let releaseNotes: String?
        let minimumOsVersion: String?
    }
}

/// This iPhone's iOS version as "17.5.1".
private var deviceOSVersion: String {
    let v = ProcessInfo.processInfo.operatingSystemVersion
    return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
}
