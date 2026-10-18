import Foundation

/// Matches recalls against a household's watchlist. Pure and local — this is the
/// whole privacy model: the public feed is matched on-device, nothing about the
/// household is sent anywhere.
enum WatchMatcher {

    /// The watch item a recall matches, if any (brands take priority over categories).
    static func match(_ recall: Recall, items: [WatchItem]) -> WatchItem? {
        let hay = "\(recall.title) \(recall.product)".lowercased()
        // Brand/product text match first — more specific.
        if let brand = items.first(where: {
            $0.kind == .brand && hay.contains($0.term.lowercased())
        }) {
            return brand
        }
        // Then category watches.
        return items.first(where: {
            $0.kind == .category && $0.term == recall.group.rawValue
        })
    }

    /// All recalls that match, newest first (for the Guardian screen).
    static func matches(in recalls: [Recall], items: [WatchItem]) -> [(Recall, WatchItem)] {
        guard !items.isEmpty else { return [] }
        return recalls.compactMap { r in
            guard !r.archived, let item = match(r, items: items) else { return nil }
            return (r, item)
        }
    }
}
