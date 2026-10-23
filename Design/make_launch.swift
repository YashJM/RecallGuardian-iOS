// Transparent launch logo: squarer maple-red shield + white alert bell.
// Usage: swift make_launch.swift <size> <out.png>
import AppKit
import Foundation

let N = Int(CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "240") ?? 240
let out = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "logo.png"
let Nf = CGFloat(N)
let cs = CGColorSpaceCreateDeviceRGB()
func cg(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [CGFloat(r)/255, CGFloat(g)/255, CGFloat(b)/255, a])!
}

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: N, pixelsHigh: N, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)!
let ctx = NSGraphicsContext.current!.cgContext
func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * Nf, y: y * Nf) }

let shield = CGMutablePath()
shield.move(to: P(0.50, 0.84))
shield.addLine(to: P(0.81, 0.74))
shield.addLine(to: P(0.81, 0.46))
shield.addQuadCurve(to: P(0.50, 0.10), control: P(0.81, 0.28))
shield.addQuadCurve(to: P(0.19, 0.46), control: P(0.19, 0.28))
shield.addLine(to: P(0.19, 0.74))
shield.closeSubpath()
ctx.addPath(shield)
ctx.setFillColor(cg(0xC0, 0x1C, 0x2E))
ctx.fillPath()

let cfg = NSImage.SymbolConfiguration(pointSize: 0.40 * Nf, weight: .semibold)
if let base = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: nil)?.withSymbolConfiguration(cfg) {
    let sz = base.size
    let white = NSImage(size: sz)
    white.lockFocus()
    base.draw(in: NSRect(origin: .zero, size: sz))
    NSColor.white.set()
    NSRect(origin: .zero, size: sz).fill(using: .sourceAtop)
    white.unlockFocus()
    white.draw(in: NSRect(x: Nf*0.5 - sz.width/2, y: Nf*0.53 - sz.height/2, width: sz.width, height: sz.height))
}

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out) (\(N)px)")
