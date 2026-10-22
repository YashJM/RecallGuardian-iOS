// Renders the transparent shield logo for the launch screen.
// Usage: swift make_launch.swift <size> <out.png>
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation

let N = Int(CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "240") ?? 240
let out = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "logo.png"
let n = CGFloat(N)
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
func color(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [CGFloat(r)/255, CGFloat(g)/255, CGFloat(b)/255, a])!
}

let ctx = CGContext(data: nil, width: N, height: N, bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.translateBy(x: 0, y: n); ctx.scaleBy(x: 1, y: -1) // top-down
func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * n, y: y * n) }

let shield = CGMutablePath()
shield.move(to: P(0.50, 0.08))
shield.addLine(to: P(0.81, 0.18))
shield.addLine(to: P(0.81, 0.55))
shield.addQuadCurve(to: P(0.50, 0.92), control: P(0.81, 0.80))
shield.addQuadCurve(to: P(0.19, 0.55), control: P(0.19, 0.80))
shield.addLine(to: P(0.19, 0.18))
shield.closeSubpath()
ctx.addPath(shield)
ctx.setFillColor(color(0xC0, 0x1C, 0x2E))
ctx.fillPath()

let check = CGMutablePath()
check.move(to: P(0.40, 0.50))
check.addLine(to: P(0.47, 0.585))
check.addLine(to: P(0.61, 0.42))
ctx.setStrokeColor(color(0xFF, 0xFF, 0xFF))
ctx.setLineWidth(0.058 * n)
ctx.setLineCap(.round); ctx.setLineJoin(.round)
ctx.addPath(check); ctx.strokePath()

let img = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out) (\(N)px)")
