import AppKit
import CoreGraphics

// Renders a 1024x1024 macOS app icon: a voice waveform that ends in a text cursor ("speech -> text").
let S: CGFloat = 1024
let out = CommandLine.arguments[1]

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func c(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

// Apple macOS icon grid: 824pt body centred in 1024 canvas.
let inset: CGFloat = 100
let body = CGRect(x: inset, y: inset, width: S - 2 * inset, height: S - 2 * inset)
let radius = body.width * 0.2237
let squircle = CGPath(roundedRect: body, cornerWidth: radius, cornerHeight: radius, transform: nil)

// Drop shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: c(0x000000, 0.35))
ctx.addPath(squircle); ctx.setFillColor(c(0x1B1A3A)); ctx.fillPath()
ctx.restoreGState()

// Background gradient (deep indigo -> violet)
ctx.saveGState()
ctx.addPath(squircle); ctx.clip()
let bg = CGGradient(colorsSpace: cs, colors: [c(0x5B3FE0), c(0x2A1E78), c(0x120F33)] as CFArray,
                    locations: [0, 0.55, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: body.minX, y: body.maxY),
                       end: CGPoint(x: body.maxX, y: body.minY), options: [])
// soft top glow
let glow = CGGradient(colorsSpace: cs, colors: [c(0xFFFFFF, 0.18), c(0xFFFFFF, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: S * 0.35, y: S * 0.82), startRadius: 0,
                       endCenter: CGPoint(x: S * 0.35, y: S * 0.82), endRadius: S * 0.55, options: [])
ctx.restoreGState()

// Waveform bars
let heights: [CGFloat] = [0.16, 0.34, 0.58, 0.80, 0.52, 0.30]
let barW: CGFloat = 58
let gap: CGFloat = 30
let cursorGap: CGFloat = 52
let cursorW: CGFloat = 40
let totalW = CGFloat(heights.count) * barW + CGFloat(heights.count - 1) * gap + cursorGap + cursorW
var x = (S - totalW) / 2
let midY = S / 2
let maxH: CGFloat = 520

let barGrad = CGGradient(colorsSpace: cs, colors: [c(0xFFFFFF), c(0xB9F3E4)] as CFArray, locations: [0, 1])!
for h in heights {
    let bh = maxH * h
    let r = CGRect(x: x, y: midY - bh / 2, width: barW, height: bh)
    let p = CGPath(roundedRect: r, cornerWidth: barW / 2, cornerHeight: barW / 2, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: c(0x000000, 0.25))
    ctx.addPath(p); ctx.setFillColor(c(0xFFFFFF)); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(p); ctx.clip()
    ctx.drawLinearGradient(barGrad, start: CGPoint(x: 0, y: r.maxY), end: CGPoint(x: 0, y: r.minY), options: [])
    ctx.restoreGState()
    x += barW + gap
}

// Text cursor (I-beam) in amber
x += cursorGap - gap
let curH: CGFloat = maxH * 0.9
let stem = CGRect(x: x, y: midY - curH / 2, width: cursorW, height: curH)
let capW: CGFloat = 120, capH: CGFloat = 34
let topCap = CGRect(x: stem.midX - capW / 2, y: stem.maxY - capH, width: capW, height: capH)
let botCap = CGRect(x: stem.midX - capW / 2, y: stem.minY, width: capW, height: capH)
let beam = CGMutablePath()
beam.addPath(CGPath(roundedRect: stem, cornerWidth: cursorW / 2, cornerHeight: cursorW / 2, transform: nil))
beam.addPath(CGPath(roundedRect: topCap, cornerWidth: capH / 2, cornerHeight: capH / 2, transform: nil))
beam.addPath(CGPath(roundedRect: botCap, cornerWidth: capH / 2, cornerHeight: capH / 2, transform: nil))
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 40, color: c(0xFFC24B, 0.75))
ctx.addPath(beam); ctx.setFillColor(c(0xFFC24B)); ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addPath(beam); ctx.clip()
let amber = CGGradient(colorsSpace: cs, colors: [c(0xFFE08A), c(0xFFA928)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(amber, start: CGPoint(x: 0, y: stem.maxY), end: CGPoint(x: 0, y: stem.minY), options: [])
ctx.restoreGState()

// Thin inner stroke for definition
ctx.saveGState()
ctx.addPath(squircle); ctx.setStrokeColor(c(0xFFFFFF, 0.12)); ctx.setLineWidth(3); ctx.strokePath()
ctx.restoreGState()

let img = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: img)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
