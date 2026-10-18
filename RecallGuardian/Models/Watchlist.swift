import Foundation
import Observation

/// One thing the household is watching for: a brand/product name, or a whole
/// category. Stored on-device only — it never leaves the phone.
struct WatchItem: Identifiable, Codable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable { case brand, category }
    var id: UUID = UUID()
    var kind: Kind
    var term: String          // brand text (lowercased match), or a RecallGroup.rawValue
    var label: String         // what we show the user
    var addedAt: Date = Date()
}

/// The on-device watchlist. Persisted as JSON in UserDefaults (swap for the App
/// RecallGroup container once a widget is added).
@Observable
@MainActor
final class Watchlist {
    private(set) var items: [WatchItem] = []
    private let key = "watchlist.v1"

    init() { load() }

    var brands: [WatchItem] { items.filter { $0.kind == .brand } }
    var categories: Set<String> { Set(items.filter { $0.kind == .category }.map(\.term)) }

    func addBrand(_ raw: String) {
        let term = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard term.count >= 2 else { return }
        guard !items.contains(where: { $0.kind == .brand && $0.term.caseInsensitiveCompare(term) == .orderedSame }) else { return }
        items.insert(WatchItem(kind: .brand, term: term, label: term), at: 0)
        save()
    }

    func toggleCategory(_ group: RecallGroup) {
        if let existing = items.firstIndex(where: { $0.kind == .category && $0.term == group.rawValue }) {
            items.remove(at: existing)
        } else {
            items.append(WatchItem(kind: .category, term: group.rawValue, label: group.label))
        }
        save()
    }

    func isWatching(_ group: RecallGroup) -> Bool {
        items.contains { $0.kind == .category && $0.term == group.rawValue }
    }

    func remove(_ item: WatchItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    // MARK: Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WatchItem].self, from: data)
        else { return }
        items = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
