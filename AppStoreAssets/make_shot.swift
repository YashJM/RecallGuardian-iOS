// Composites a simulator screenshot into a captioned App Store image (exactly
// 1320×2868, 6.9" iPhone). Usage: swift make_shot.swift <shot.png> "<caption>" <out.png>
import AppKit
import Foundation

let a = CommandLine.arguments
guard a.count >= 4, let shot = NSImage(contentsOfFile: a[1]) else {
    FileHandle.standardError.write("usage: make_shot <shot> <caption> <out>\n".data(using: .utf8)!); exit(1)
}
let caption = a[2], outPath = a[3]
let W = 1320, H = 2868
let Wf = CGFloat(W), Hf = CGFloat(H)
let cs = CGColorSpaceCreateDeviceRGB()
func cg(_ r: Int, _ g: Int, _ b: Int, _ al: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [CGFloat(r)/255, CGFloat(g)/255, CGFloat(b)/255, al])!
}

// Explicit 1320×2868 bitmap (no Retina scaling).
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
let gctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = gctx
let ctx = gctx.cgContext

// Background gradient.
let grad = CGGradient(colorsSpace: cs, colors: [cg(0xF5, 0xF8, 0xFA), cg(0xDF, 0xE7, 0xEE)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: Hf), end: CGPoint(x: 0, y: 0), options: [])

// Caption near the top.
let para = NSMutableParagraphStyle(); para.alignment = .center; para.lineHeightMultiple = 1.04
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 92, weight: .heavy),
    .foregroundColor: NSColor(red: 0x18/255, green: 0x28/255, blue: 0x38/255, alpha: 1),
    .paragraphStyle: para,
]
(caption as NSString).draw(in: NSRect(x: 80, y: Hf - 520, width: Wf - 160, height: 420), withAttributes: attrs)

// Screenshot framed below the caption.
let topBand: CGFloat = 560
let availH = Hf - topBand - 110
let availW = Wf - 220
let scale = min(availW / 1320, availH / 2868)
let dw = 1320 * scale, dh = 2868 * scale
let frame = NSRect(x: (Wf - dw) / 2, y: 80, width: dw, height: dh)
let path = NSBezierPath(roundedRect: frame, xRadius: 56 * scale, yRadius: 56 * scale)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -22), blur: 46, color: cg(0x14, 0x27, 0x3B, 0.22))
NSColor.white.setFill(); path.fill()
ctx.restoreGState()

ctx.saveGState()
path.addClip()
shot.draw(in: frame)
ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath) \(rep.pixelsWide)x\(rep.pixelsHigh)")
