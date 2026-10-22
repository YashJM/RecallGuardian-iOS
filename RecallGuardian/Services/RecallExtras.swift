import Foundation

/// Product photo + provincial distribution, pulled from the official notice
/// page (same best-effort parsing as the web app). Cached in-memory.
struct RecallExtras: Sendable {
    var imageURL: URL?
    var distribution: String   // "AB, BC, ON", "Canada (national)", or ""
    static let empty = RecallExtras(imageURL: nil, distribution: "")
}

actor RecallExtrasService {
    static let shared = RecallExtrasService()
    private var cache: [String: RecallExtras] = [:]

    private let provinces: [(name: String, code: String)] = [
        ("Alberta", "AB"), ("British Columbia", "BC"), ("Manitoba", "MB"),
        ("New Brunswick", "NB"), ("Newfoundland", "NL"), ("Nova Scotia", "NS"),
        ("Ontario", "ON"), ("Prince Edward Island", "PE"), ("Quebec", "QC"),
        ("Qu\u{00e9}bec", "QC"), ("Saskatchewan", "SK"),
        ("Northwest Territories", "NT"), ("Nunavut", "NU"), ("Yukon", "YT"),
    ]

    func extras(for recall: Recall) async -> RecallExtras {
        if let cached = cache[recall.nid] { return cached }
        guard let url = recall.sourceURL else { return .empty }
        var result = RecallExtras.empty
        do {
            var request = URLRequest(url: url, timeoutInterval: 10)
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                cache[recall.nid] = result
                return result
            }
            if let html = String(data: data, encoding: .utf8) {
                result.imageURL = Self.parseImage(html)
                result.distribution = parseDistribution(html)
            }
        } catch {
            // keep empty on any failure
        }
        cache[recall.nid] = result
        return result
    }

    private static func parseImage(_ html: String) -> URL? {
        let pattern = #"(?:data-src|src)="(/sites/default/files/styles/[^"]+\.(?:png|jpe?g|webp)[^"]*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html)
        else { return nil }
        let path = String(html[range]).replacingOccurrences(of: "&amp;", with: "&")
        return URL(string: "https://recalls-rappels.canada.ca" + path)
    }

    private func parseDistribution(_ html: String) -> String {
        var codes: [String] = []
        for p in provinces where html.range(of: "\\b\(p.name)\\b", options: [.regularExpression, .caseInsensitive]) != nil {
            if !codes.contains(p.code) { codes.append(p.code) }
        }
        if (1...6).contains(codes.count) { return codes.joined(separator: ", ") }
        if html.range(of: "\\bnational", options: [.regularExpression, .caseInsensitive]) != nil {
            return "Canada (national)"
        }
        return ""
    }
}
