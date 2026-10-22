import Foundation

/// Turns a scanned barcode into a product name, via Open Food Facts (free, no
/// key). Great for food/grocery; returns nil for unknown (e.g. non-food) codes,
/// which the UI handles by asking the user to type the name.
enum ProductLookup {
    static func name(forBarcode code: String) async -> String? {
        let digits = code.filter(\.isNumber)
        guard digits.count >= 6,
              let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(digits).json?fields=product_name,brands")
        else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("RecallGuardian/1.0 (ca.recallguardian.app)", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let decoded = try? JSONDecoder().decode(Response.self, from: data),
              let product = decoded.product
        else { return nil }

        let name = product.product_name?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name, !name.isEmpty { return name }
        let brand = product.brands?.split(separator: ",").first
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let brand, !brand.isEmpty { return brand }
        return nil
    }

    private struct Response: Decodable {
        let product: Product?
        struct Product: Decodable {
            let product_name: String?
            let brands: String?
        }
    }
}
