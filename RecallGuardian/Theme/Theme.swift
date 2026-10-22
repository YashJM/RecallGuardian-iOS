import SwiftUI

/// Design tokens, mirroring the web app's civic light theme (`globals.css`).
/// Light-only on purpose, like the website.
enum Theme {
    static let paper = hex(0xF3F6F8)      // page background
    static let surface = hex(0xFFFFFF)     // cards
    static let surface2 = hex(0xE9EEF2)
    static let ink = hex(0x182838)         // navy ink
    static let muted = hex(0x58697A)
    static let line = hex(0xD8E0E7)
    static let navy = hex(0x14273B)
    static let brand = hex(0xC01C2E)       // maple red

    static let riskFg = hex(0x9A5B08)
    static let riskBg = hex(0xFBEFE0)

    /// Category colour (the medallion / tile accent).
    static func category(_ g: RecallGroup) -> Color {
        switch g {
        case .food: hex(0xC24A2C)
        case .medicine: hex(0x2E8B57)
        case .kids: hex(0xC07D10)
        case .vehicles: hex(0x6E4B9E)
        case .household: hex(0x2D6CB5)
        case .other: hex(0x647586)
        }
    }

    /// SF Symbol for a category.
    static func symbol(_ g: RecallGroup) -> String {
        switch g {
        case .food: "fork.knife"
        case .medicine: "pills.fill"
        case .kids: "figure.and.child.holdinghands"
        case .vehicles: "car.fill"
        case .household: "house.fill"
        case .other: "shippingbox.fill"
        }
    }

    static func severity(_ tier: Tier) -> Color {
        switch tier {
        case .critical: hex(0xC01C2E)
        case .high: hex(0xB0730A)
        case .standard: hex(0x3E6B63)
        }
    }

    /// Soft severity tint (pills).
    static func severityBackground(_ tier: Tier) -> Color {
        switch tier {
        case .critical: hex(0xFBE9EB)
        case .high: hex(0xFAF2E1)
        case .standard: hex(0xE9F1EF)
        }
    }

    static func hex(_ hex: Int) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension Font {
    /// Display/UI face. System for now; can be swapped for Public Sans later.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
