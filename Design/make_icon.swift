// Renders the RecallGuardian app icon (1024×1024) — a maple-red shield with a
// white check on a light civic background. Run: swift make_icon.swift
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation

let S = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
func col(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [CGFloat(r)/255, CGFloat(g)/255, CGFloat(b)/255, a])!
}

let ctx = CGContext(data: nil, width: S, height: S, bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// Flip to top-down coordinates.
ctx.translateBy(x: 0, y: CGFloat(S))
ctx.scaleBy(x: 1, y: -1)

// Background: soft cool gradient.
let bg = CGGradient(colorsSpace: cs, colors: [col(0xF5, 0xF8, 0xFA), col(0xE3, 0xEA, 0xEF)] as CFArray,
                    locations: [0, 1])!
ctx.drawLinearGradient(bg, start: .zero, end: CGPoint(x: 0, y: S), options: [])

// Shield.
let shield = CGMutablePath()
shield.move(to: CGPoint(x: 512, y: 206))
shield.addLine(to: CGPoint(x: 796, y: 298))
shield.addLine(to: CGPoint(x: 796, y: 560))
shield.addQuadCurve(to: CGPoint(x: 512, y: 826), control: CGPoint(x: 796, y: 744))
shield.addQuadCurve(to: CGPoint(x: 228, y: 560), control: CGPoint(x: 228, y: 744))
shield.addLine(to: CGPoint(x: 228, y: 298))
shield.closeSubpath()

// Soft shadow under the shield.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 18), blur: 36, color: col(0x14, 0x27, 0x3B, 0.28))
ctx.addPath(shield)
ctx.setFillColor(col(0xC0, 0x1C, 0x2E))
ctx.fillPath()
ctx.restoreGState()

// Subtle vertical gradient inside the shield for depth.
ctx.saveGState()
ctx.addPath(shield)
ctx.clip()
let red = CGGradient(colorsSpace: cs, colors: [col(0xCE, 0x24, 0x38), col(0xA6, 0x16, 0x28)] as CFArray,
                     locations: [0, 1])!
ctx.drawLinearGradient(red, start: CGPoint(x: 0, y: 206), end: CGPoint(x: 0, y: 826), options: [])
ctx.restoreGState()

// White check.
let check = CGMutablePath()
check.move(to: CGPoint(x: 418, y: 520))
check.addLine(to: CGPoint(x: 486, y: 592))
check.addLine(to: CGPoint(x: 624, y: 438))
ctx.setStrokeColor(col(0xFF, 0xFF, 0xFF))
ctx.setLineWidth(54)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.addPath(check)
ctx.strokePath()

guard let img = ctx.makeImage() else { fatalError("no image") }
let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png")
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out.path)")
