// RecallGuardian app icon (1024×1024): a squarer maple-red shield with a white
// alert bell, on a light civic background. Run: swift make_icon.swift [out.png]
import AppKit
import Foundation

let S = 1024, Sf = CGFloat(1024)
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
let cs = CGColorSpaceCreateDeviceRGB()
func cg(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [CGFloat(r)/255, CGFloat(g)/255, CGFloat(b)/255, a])!
}

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: S, pixelsHigh: S, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)!
let ctx = NSGraphicsContext.current!.cgContext
func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * Sf, y: y * Sf) } // AppKit: y up

// Background.
let bg = CGGradient(colorsSpace: cs, colors: [cg(0xF5, 0xF8, 0xFA), cg(0xE3, 0xEA, 0xEF)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: Sf), end: .zero, options: [])

// Squarer shield (bottom-up coords; top = high y).
let shield = CGMutablePath()
shield.move(to: P(0.50, 0.85))
shield.addLine(to: P(0.85, 0.75))
shield.addLine(to: P(0.85, 0.48))
shield.addQuadCurve(to: P(0.50, 0.14), control: P(0.85, 0.26))
shield.addQuadCurve(to: P(0.15, 0.48), control: P(0.15, 0.26))
shield.addLine(to: P(0.15, 0.75))
shield.closeSubpath()

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 38, color: cg(0x14, 0x27, 0x3B, 0.28))
ctx.addPath(shield); ctx.setFillColor(cg(0xC0, 0x1C, 0x2E)); ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(shield); ctx.clip()
let red = CGGradient(colorsSpace: cs, colors: [cg(0xCE, 0x24, 0x38), cg(0xA6, 0x16, 0x28)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(red, start: P(0.5, 0.85), end: P(0.5, 0.14), options: [])
ctx.restoreGState()

// White alert bell (SF Symbol), centered in the shield.
let cfg = NSImage.SymbolConfiguration(pointSize: 440, weight: .semibold)
if let base = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: nil)?.withSymbolConfiguration(cfg) {
    let sz = base.size
    let white = NSImage(size: sz)
    white.lockFocus()
    base.draw(in: NSRect(origin: .zero, size: sz))
    NSColor.white.set()
    NSRect(origin: .zero, size: sz).fill(using: .sourceAtop)
    white.unlockFocus()
    let cx = Sf * 0.5, cy = Sf * 0.52
    white.draw(in: NSRect(x: cx - sz.width/2, y: cy - sz.height/2, width: sz.width, height: sz.height))
}

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
