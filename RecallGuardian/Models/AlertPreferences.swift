import Foundation
import Observation

/// How severe a recall must be before it's allowed to notify.
enum SeverityThreshold: String, CaseIterable, Identifiable, Codable, Sendable {
    case critical, high, all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .critical: "Critical only"
        case .high: "High & critical"
        case .all: "Everything"
        }
    }

    /// Minimum tier weight a recall must have to pass this threshold.
    var minWeight: Double {
        switch self {
        case .critical: 3
        case .high: 2
        case .all: 1
        }
    }

    func allows(_ tier: Tier) -> Bool { tier.weight >= minWeight }
}

/// User-controlled alert settings. The watchlist decides *what* is watched;
/// these decide *whether* and *how loud*. Stored on-device.
@Observable
@MainActor
final class AlertPreferences {
    static let enabledKey = "alerts.enabled"
    static let thresholdKey = "alerts.threshold"

    var enabled: Bool {
        didSet { UserDefaults.standard.set(enabled, forKey: Self.enabledKey) }
    }
    var threshold: SeverityThreshold {
        didSet { UserDefaults.standard.set(threshold.rawValue, forKey: Self.thresholdKey) }
    }

    init() {
        enabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        let raw = UserDefaults.standard.string(forKey: Self.thresholdKey) ?? SeverityThreshold.high.rawValue
        threshold = SeverityThreshold(rawValue: raw) ?? .high
    }

    /// Non-isolated snapshot for the background task.
    nonisolated static func current() -> (enabled: Bool, threshold: SeverityThreshold) {
        let enabled = UserDefaults.standard.bool(forKey: enabledKey)
        let raw = UserDefaults.standard.string(forKey: thresholdKey) ?? SeverityThreshold.high.rawValue
        return (enabled, SeverityThreshold(rawValue: raw) ?? .high)
    }
}
