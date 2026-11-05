// Renders Flick's app icon to a 1024x1024 PNG: swift make_icon.swift out.png
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"

let cs = CGColorSpace(name: CGColorSpace.displayP3)!
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(colorSpace: cs, components: [r/255, g/255, b/255, a])! }

// macOS icon grid: 824pt tile centered in 1024 canvas.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

// Drop shadow under the tile.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: c(0, 0, 0, 0.35))
ctx.addPath(tilePath); ctx.setFillColor(c(20, 20, 40)); ctx.fillPath()
ctx.restoreGState()

// Background gradient: deep indigo to violet.
ctx.saveGState()
ctx.addPath(tilePath); ctx.clip()
let bg = CGGradient(colorsSpace: cs, colors: [c(28, 24, 74), c(74, 44, 168), c(140, 70, 220)] as CFArray, locations: [0, 0.6, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 200, y: 100), end: CGPoint(x: 824, y: 924), options: [])
// Soft glow top-right.
let glow = CGGradient(colorsSpace: cs, colors: [c(255, 120, 200, 0.45), c(255, 120, 200, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 800, y: 860), startRadius: 0, endCenter: CGPoint(x: 800, y: 860), endRadius: 520, options: [])
// Subtle top sheen.
let sheen = CGGradient(colorsSpace: cs, colors: [c(255, 255, 255, 0.14), c(255, 255, 255, 0)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(sheen, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 560), options: [])
ctx.restoreGState()

// Search bar pill, slightly tilted for motion. Everything stays inside the tile.
ctx.saveGState()
ctx.addPath(tilePath); ctx.clip()
ctx.translateBy(x: 488, y: 512)
ctx.rotate(by: 8 * .pi / 180)
let pill = CGRect(x: -185, y: -78, width: 460, height: 156)
let pillPath = CGPath(roundedRect: pill, cornerWidth: 78, cornerHeight: 78, transform: nil)

// Motion streaks trailing left of the pill.
ctx.setLineCap(.round)
for (i, s) in [(-40.0, 95.0, 0.5), (4.0, 140.0, 0.85), (48.0, 80.0, 0.4)].enumerated() {
    _ = i
    let y = CGFloat(s.0), len = CGFloat(s.1)
    let start = CGPoint(x: -225 - len, y: y), end = CGPoint(x: -225, y: y)
    ctx.saveGState()
    ctx.setLineWidth(24)
    ctx.addLines(between: [start, end])
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    let g = CGGradient(colorsSpace: cs, colors: [c(255, 255, 255, 0), c(255, 255, 255, CGFloat(s.2))] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: start, end: end, options: [])
    ctx.restoreGState()
}

ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 30, color: c(10, 0, 40, 0.45))
ctx.addPath(pillPath); ctx.setFillColor(c(255, 255, 255)); ctx.fillPath()
ctx.setShadow(offset: .zero, blur: 0, color: nil)
// Faint inner gradient on the pill.
ctx.saveGState()
ctx.addPath(pillPath); ctx.clip()
let pg = CGGradient(colorsSpace: cs, colors: [c(255, 255, 255), c(232, 228, 255)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(pg, start: CGPoint(x: 0, y: 78), end: CGPoint(x: 0, y: -78), options: [])
ctx.restoreGState()

// Magnifier glyph.
let mc = CGPoint(x: -100, y: 10)
ctx.setStrokeColor(c(74, 44, 168)); ctx.setLineWidth(22)
ctx.addEllipse(in: CGRect(x: mc.x - 36, y: mc.y - 36, width: 72, height: 72)); ctx.strokePath()
ctx.setLineCap(.round); ctx.setLineWidth(24)
ctx.addLines(between: [CGPoint(x: mc.x + 28, y: mc.y - 28), CGPoint(x: mc.x + 58, y: mc.y - 58)]); ctx.strokePath()

// Text caret in a warm gradient.
let caret = CGRect(x: 3, y: -46, width: 20, height: 92)
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: caret, cornerWidth: 10, cornerHeight: 10, transform: nil)); ctx.clip()
let cg = CGGradient(colorsSpace: cs, colors: [c(255, 95, 160), c(255, 150, 80)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(cg, start: CGPoint(x: 0, y: 46), end: CGPoint(x: 0, y: -46), options: [])
ctx.restoreGState()

// Placeholder "text" lines.
ctx.setFillColor(c(74, 44, 168, 0.18))
ctx.addPath(CGPath(roundedRect: CGRect(x: 51, y: -12, width: 160, height: 24), cornerWidth: 12, cornerHeight: 12, transform: nil)); ctx.fillPath()
ctx.restoreGState()

let img = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: img)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
