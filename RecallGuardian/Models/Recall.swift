import Foundation

/// Severity tier — our editorial ranking, shown as the card's stripe colour.
enum Tier: String, Codable, Sendable {
    case critical, high, standard

    var label: String {
        switch self {
        case .critical: "Critical"
        case .high: "High"
        case .standard: "Standard"
        }
    }
    var weight: Double {
        switch self {
        case .critical: 3
        case .high: 2
        case .standard: 1
        }
    }
    /// 0 = most urgent. The dominant sort key, so a photo can never lift a lower
    /// tier above a higher one.
    var rank: Int {
        switch self {
        case .critical: 0
        case .high: 1
        case .standard: 2
        }
    }
}

/// The seven household groups used for filtering (mirrors the web app).
enum RecallGroup: String, Codable, CaseIterable, Identifiable, Sendable {
    case food, medicine, kids, vehicles, household, other
    var id: String { rawValue }

    var label: String {
        switch self {
        case .food: "Food"
        case .medicine: "Medicine"
        case .kids: "Kids"
        case .vehicles: "Vehicles"
        case .household: "Household"
        case .other: "Other"
        }
    }
}

/// A normalized, ranked recall — the shape the UI consumes.
struct Recall: Identifiable, Hashable, Sendable {
    let nid: String
    let title: String
    let product: String
    let issue: String
    let whatToDo: String
    let category: String
    let agency: String
    let recallClass: String
    let lastUpdated: Date?
    let archived: Bool
    let sourceURL: URL?
    let group: RecallGroup
    let tier: Tier
    let score: Double

    var id: String { nid }
}

/// One record exactly as it arrives in the Government of Canada feed.
/// The field names contain spaces, so we map them explicitly.
struct RawRecall: Decodable {
    let nid: String
    let title: String
    let url: String
    let organization: String
    let product: String?
    let issue: String?
    let whatYouShouldDo: String?
    let category: String
    let recallClass: String?
    let lastUpdated: String?
    let archived: String

    enum CodingKeys: String, CodingKey {
        case nid = "NID"
        case title = "Title"
        case url = "URL"
        case organization = "Organization"
        case product = "Product"
        case issue = "Issue"
        case whatYouShouldDo = "What you should do"
        case category = "Category"
        case recallClass = "Recall class"
        case lastUpdated = "Last updated"
        case archived = "Archived"
    }
}
