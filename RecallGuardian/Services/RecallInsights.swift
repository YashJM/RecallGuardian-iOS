import Foundation

/// Plain-language value-adds over the official notice — the same logic as the
/// web app's `recalls.ts`. Pure and local.
enum RecallInsights {

    private static let allergens = [
        "peanut", "tree nut", "almond", "cashew", "walnut", "hazelnut", "pecan",
        "milk", "egg", "wheat", "gluten", "soy", "mustard", "sesame", "sulphite",
        "sulfite", "fish", "shellfish", "crustacean",
    ]

    /// Named groups most at risk, by hazard. nil when nothing specific applies.
    static func whoAtRisk(_ r: Recall) -> String? {
        let t = "\(r.issue) \(r.title)".lowercased()
        if t.contains("listeria") {
            return "Pregnant people, newborns, adults 65+, and people with weakened immune systems"
        }
        if t.contains("salmonella") || t.contains("e. coli") || t.contains("e.coli") || t.contains("botulism") {
            return "Young children, older adults, pregnant people, and people with weakened immune systems"
        }
        if t.contains("undeclared") || t.contains("allergen") || t.contains("allergy") {
            if let found = allergens.first(where: { t.contains($0) }) {
                let name = found == "sulfite" ? "sulphite" : found
                return "People with a \(name) allergy or sensitivity"
            }
            return "People with the relevant food allergy or sensitivity"
        }
        if t.contains("choking") { return "Babies and young children" }
        if r.group == .kids || t.contains("car seat") || t.contains("infant") {
            return "Babies and young children"
        }
        return nil
    }

    /// The official "what you should do" text, broken into ordered steps.
    static func steps(_ r: Recall) -> [String] {
        let text = r.whatToDo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }
        let parts = text.components(separatedBy: ". ")
        let steps = parts.enumerated().compactMap { index, raw -> String? in
            var s = raw.trimmingCharacters(in: .whitespaces)
            guard s.count > 3 else { return nil }
            if index < parts.count - 1, !s.hasSuffix(".") { s += "." }
            return s
        }
        return Array(steps.prefix(5))
    }
}
