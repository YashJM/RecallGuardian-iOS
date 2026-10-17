import Foundation
import Observation

/// Fetches the Government of Canada feed, normalizes + ranks it, and exposes
/// state to the UI. Everything the UI shows flows through here.
@Observable
@MainActor
final class RecallStore {

    static let feedURL = URL(
        string: "https://recalls-rappels.canada.ca/sites/default/files/opendata-donneesouvertes/HCRSAMOpenData.json"
    )!

    enum LoadState: Equatable {
        case idle, loading, loaded, failed(String)
    }

    private(set) var recalls: [Recall] = []
    private(set) var state: LoadState = .idle

    /// The feed does not provide explicit archive timestamps we need, so we
    /// surface a capped, non-archived, ranked slice on the main feed.
    var feed: [Recall] {
        recalls.filter { !$0.archived }
    }

    func counts(in list: [Recall]) -> [Group: Int] {
        Dictionary(grouping: list, by: \.group).mapValues(\.count)
    }

    func load(force: Bool = false) async {
        if state == .loaded && !force { return }
        state = .loading
        do {
            let (data, response) = try await URLSession.shared.data(from: Self.feedURL)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            let raw = try JSONDecoder().decode([RawRecall].self, from: data)
            let parsed = raw.map(Self.normalize)
                .sorted {
                    if $0.score != $1.score { return $0.score > $1.score }
                    return ($0.lastUpdated ?? .distantPast) > ($1.lastUpdated ?? .distantPast)
                }
            recalls = parsed
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: Normalization

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let agencyNames: [String: String] = [
        "CFIA": "Canadian Food Inspection Agency",
        "TC": "Transport Canada",
        "HC": "Health Canada",
        "Consumer product safety": "Health Canada — Consumer product safety",
        "Medical devices": "Health Canada — Medical devices",
        "Drugs and health products": "Health Canada — Drugs and health products",
        "Marketed health products": "Health Canada — Marketed health products",
        "Controlled substances and cannabis": "Health Canada — Controlled substances",
        "Communications and Public Affairs Branch": "Health Canada",
    ]

    static func normalize(_ r: RawRecall) -> Recall {
        let title = {
            let t = RecallClassifier.clean(r.title)
            if !t.isEmpty { return t }
            let p = RecallClassifier.clean(r.product)
            return p.isEmpty ? "Safety recall" : p
        }()
        let category = r.category.isEmpty ? "Other" : r.category
        let org = r.organization
        let group = RecallClassifier.group(category: category, org: org)
        let tier = RecallClassifier.tier(category: category, org: org, group: group)
        let date = (r.lastUpdated?.isEmpty == false)
            ? dateFormatter.date(from: r.lastUpdated!) : nil

        return Recall(
            nid: r.nid,
            title: title,
            product: RecallClassifier.clean(r.product),
            issue: RecallClassifier.clean(r.issue),
            whatToDo: RecallClassifier.clean(r.whatYouShouldDo),
            category: category,
            agency: agencyNames[org] ?? (org.isEmpty ? "Government of Canada" : org),
            recallClass: (r.recallClass ?? "").trimmingCharacters(in: .whitespaces),
            lastUpdated: date,
            archived: r.archived == "1",
            sourceURL: URL(string: r.url),
            group: group,
            tier: tier,
            score: RecallClassifier.score(tier: tier, recallClass: r.recallClass ?? "", date: date)
        )
    }
}
