import Foundation

/// Grouping, severity, and ranking. This is the shared contract with the web
/// app (`src/lib/recalls.ts`) — keep the two in sync so both surfaces rank
/// recalls identically.
enum RecallClassifier {

    // MARK: Keyword sets

    private static let kidWords = [
        "child car seat", "booster seat", "infant", "toy", "stroller",
    ]
    private static let foodWords = [
        "food", "fresh", "frozen", "processed", "dairy", "meat", "poultry",
        "fish", "seafood", "fruit", "vegetable", "nuts", "grain", "candy",
        "confection", "snack", "condiment", "herb", "spice", "egg", "bread",
        "canned", "alcoholic", "beverage",
    ]
    // Consumer health products — things in a household medicine cabinet.
    private static let medWords = [
        "drug", "natural health", "biologic", "vaccine",
        "veterinary", "homeopathic", "health product",
    ]

    // Professional / clinical medical devices — mostly hospital equipment, not
    // household items. De-prioritized so they don't flood a consumer feed.
    private static let deviceWords = [
        "medical device", "cardiovascular", "anaesthesiology", "orthopaedic",
        "neurology", "haematology", "radiology", "chemistry", "microbiology",
        "pathology", "immunology", "dental", "ophthalmology", "surgery",
        "hospital", "gastroenterology", "obstetrics", "gynaecology",
        "radiopharm", "general hospital", "personal use",
    ]

    private static func isDevice(category: String, org: String) -> Bool {
        org.lowercased().contains("medical devices") || has(category.lowercased(), deviceWords)
    }
    private static let vehicleWords = [
        "car", "suv", "truck", "van", "motorcycle", "rv ", "rv trailer",
        "trailer", "motorhome", "bus", "a.t.v", "atv", "snowmobile", "minivan",
        "vehicle", "tire", "chassis", "moped", "scooter", "tricycle",
    ]
    private static let householdWords = [
        "household", "appliance", "chemical", "tool", "furniture", "kitchenware",
        "tableware", "electronic", "clothing", "footwear", "jewellery", "sports",
        "fitness", "beauty", "personal care", "outdoor", "hobby", "craft",
        "cannabis", "specialized products",
    ]
    private static let criticalWords: [String] = foodWords + [
        "drug", "natural health", "medical device", "biologic", "vaccine",
        "child car seat", "booster seat", "infant", "toy",
    ]
    private static let highWords: [String] = vehicleWords + [
        "household", "appliance", "chemical", "cannabis", "beauty",
        "personal care", "outdoor",
    ]

    private static func has(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    // MARK: Group

    static func group(category: String, org: String) -> Group {
        let c = category.lowercased()
        let o = org.lowercased()
        if has(c, kidWords) { return .kids } // child car seat is a TC recall but belongs here
        if o == "cfia" || has(c, foodWords) { return .food }
        // Professional medical devices are not household items — bucket as "other".
        if isDevice(category: category, org: org) { return .other }
        if has(c, medWords)
            || o.contains("drugs and health")
            || o.contains("marketed health") { return .medicine }
        if o == "tc" || has(c, vehicleWords) { return .vehicles }
        if o.contains("consumer product") || has(c, householdWords) { return .household }
        return .other
    }

    // MARK: Tier

    static func tier(category: String, org: String, group: Group) -> Tier {
        // Professional medical devices: real, but low day-to-day household relevance.
        if isDevice(category: category, org: org) { return .standard }
        if group == .food || group == .medicine || group == .kids { return .critical }
        let c = category.lowercased()
        let o = org.lowercased()
        if o == "cfia" || has(c, criticalWords) { return .critical }
        if o == "tc" || has(c, highWords) { return .high }
        return .standard
    }

    // MARK: Ranking

    static func classMultiplier(_ recallClass: String) -> Double {
        let c = recallClass.lowercased()
        if c.contains("type i") && !c.contains("type ii") { return 1.5 }
        if c.contains("type ii") && !c.contains("type iii") { return 1.2 }
        if c.contains("type iii") { return 1.0 }
        return 1.1
    }

    static func recencyBoost(_ date: Date?) -> Double {
        guard let date else { return 0.7 }
        let days = Date().timeIntervalSince(date) / 86_400
        if days <= 30 { return 1.4 }
        if days <= 90 { return 1.2 }
        if days <= 365 { return 1.0 }
        return 0.7
    }

    static func score(tier: Tier, recallClass: String, date: Date?) -> Double {
        let raw = tier.weight * classMultiplier(recallClass) * recencyBoost(date)
        return (raw * 1000).rounded() / 1000
    }

    // MARK: Text cleanup (the feed concatenates sentences and embeds entities)

    static func clean(_ s: String?) -> String {
        guard var out = s else { return "" }
        out = out.replacingOccurrences(of: "\u{200b}", with: "")
        out = out.replacingOccurrences(of: "&nbsp;", with: " ")
        out = out.replacingOccurrences(of: "&amp;", with: "&")
        out = out.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        out = out.replacingOccurrences(of: "\\.(?=[A-Z])", with: ". ", options: .regularExpression)
        out = out.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
