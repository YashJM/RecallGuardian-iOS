import SwiftUI

/// Design tokens, mirroring the web app's `globals.css`. Each colour adapts to
/// light / dark the same way the website does.
enum Theme {
    static let paper = dynamic(light: 0xF6F4EF, dark: 0x131619)
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x1B1F24)
    static let surface2 = dynamic(light: 0xFBFAF6, dark: 0x171B1F)
    static let ink = dynamic(light: 0x1A1D21, dark: 0xECEAE3)
    static let muted = dynamic(light: 0x6B6E73, dark: 0x9BA0A2)
    static let line = dynamic(light: 0xE4E0D7, dark: 0x2C3238)
    static let brand = dynamic(light: 0xB01B2E, dark: 0xE2495B)

    static func severity(_ tier: Tier) -> Color {
        switch tier {
        case .critical: dynamic(light: 0xC01C2E, dark: 0xE85A69)
        case .high: dynamic(light: 0xB0730A, dark: 0xE0A23C)
        case .standard: dynamic(light: 0x3E6B63, dark: 0x6FB3A6)
        }
    }

    static func severityBackground(_ tier: Tier) -> Color {
        switch tier {
        case .critical: dynamic(light: 0xFBEAEC, dark: 0x2A1619)
        case .high: dynamic(light: 0xFAF1E0, dark: 0x241D11)
        case .standard: dynamic(light: 0xE9F0EE, dark: 0x15211F)
        }
    }

    private static func dynamic(light: Int, dark: Int) -> Color {
        Color(uiColor: UIColor { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: Int) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Font {
    // Swap these for Archivo / Newsreader once the fonts are added to the target.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
